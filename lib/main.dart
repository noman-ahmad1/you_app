import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

    // Live-listen to the remote moderation config so admin edits (banned
    // keywords / enabled toggle) apply without an app update. The first
    // snapshot applies immediately; failures are non-fatal (defaults stand).
    FirebaseFirestore.instance
        .collection('app_settings')
        .doc('moderation_config')
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      locator<ModerationService>().applyRemoteConfig(
        enabled: data?['enabled'] as bool?,
        bannedKeywords: (data?['bannedKeywords'] as List?)
            ?.map((e) => e.toString())
            .toList(),
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
