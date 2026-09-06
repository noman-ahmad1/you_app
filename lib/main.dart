import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/billing_service.dart';
import 'package:you_app/services/moderation_service.dart';
import 'package:you_app/services/push_notification_service.dart';
import 'package:you_app/app/app.bottomsheets.dart';
import 'package:you_app/app/app.dialogs.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/firebase_options.dart';
import 'package:you_app/ui/common/app_theme.dart';

Future<void> main() async {
  // runZonedGuarded captures uncaught async errors for Crashlytics.
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Use Android's system Photo Picker for gallery picks. It requires NO
    // media permission, which is exactly what Google Play's Photo and Video
    // Permissions policy mandates for apps (like ours) that only need one-time
    // media access. The picker is backported to Android 7–12 via Play services
    // and falls back to the document picker when unavailable — still no
    // permission. `is ImagePickerAndroid` is the platform guard (no-op on iOS).
    final ImagePickerPlatform picker = ImagePickerPlatform.instance;
    if (picker is ImagePickerAndroid) {
      picker.useAndroidPhotoPicker = true;
    }

    // Load environment secrets before any service that needs them is created.
    // Fail-soft: a missing .env should not crash the app on startup.
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('Could not load .env file: $e');
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // FCM background handler. Firebase requires this to be registered as early
    // as possible after initializeApp and before the first frame; it used to be
    // registered inside PushNotificationService.initialise(), which runs after
    // runApp() and only when the user had granted permission.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Route all uncaught Flutter framework + platform errors to Crashlytics.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Initialize Hive and clear chatbot history on application startup
    await Hive.initFlutter();
    final chatbotBox = await Hive.openBox('chatbot_history');
    await chatbotBox.clear();

    await setupLocator();

    // Apply persisted analytics/crash consent (on by default) before logging.
    // Cheap + local, so it stays on the critical path.
    await locator<AnalyticsService>().init();

    // Live-listen to the remote moderation config so admin edits apply without an
    // app update. The first snapshot applies immediately; failures are non-fatal
    // (bundled defaults stand).
    //
    // Two shapes are supported, deliberately:
    //  • NEW (admin panel): per-category lists + `version`
    //    { hate: [], violence: [], sexual: [], romance: [], offTopic: [],
    //      contactIntent: [], version: n }
    //  • LEGACY: { enabled: bool, bannedKeywords: [] } — still honoured, because
    //    `enabled` is the only kill-switch and `bannedKeywords` is the admin's
    //    ad-hoc hard-block list. Both may be present at once.
    FirebaseFirestore.instance
        .collection('app_settings')
        .doc('moderation_config')
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      if (data == null) return; // no doc yet → bundled defaults stand

      List<String>? list(String key) =>
          (data[key] as List?)?.map((e) => e.toString()).toList();

      final moderation = locator<ModerationService>();

      // New per-category shape.
      moderation.updateLists(
        hate: list('hate'),
        violence: list('violence'),
        sexual: list('sexual'),
        romance: list('romance'),
        offTopic: list('offTopic'),
        contactIntent: list('contactIntent'),
        version: (data['version'] as num?)?.toInt(),
      );

      // Legacy kill-switch + explicit banned list (null args are ignored).
      moderation.applyRemoteConfig(
        enabled: data['enabled'] as bool?,
        bannedKeywords: list('bannedKeywords'),
      );
    }, onError: (e) {
      debugPrint('Moderation config listener error: $e');
    });

    setupDialogUi();
    setupBottomSheetUi();
    runApp(const MainApp());

    // Kick off the network/Play-Services-heavy, non-critical initialisations
    // AFTER the first frame so they never delay startup. Both are fail-soft:
    // billing just leaves the purchase UI unavailable until it's ready; push
    // sets up its listeners a moment later. (These were previously awaited
    // before runApp, which blocked the splash — badly so on devices/emulators
    // with slow or unavailable Google Play Services / billing.)
    unawaited(() async {
      try {
        await locator<BillingService>().configure();
      } catch (e) {
        debugPrint('Error configuring BillingService: $e');
      }
    }());
    unawaited(() async {
      try {
        await locator<PushNotificationService>().initialise();
      } catch (e) {
        debugPrint('Error initializing PushNotificationService: $e');
      }
    }());
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.theme,
      initialRoute: Routes.startupView,
      onGenerateRoute: StackedRouter().onGenerateRoute,
      navigatorKey: StackedService.navigatorKey,
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        StackedService.routeObserver,
        locator<AnalyticsService>().observer,
      ],
    );
  }
}
