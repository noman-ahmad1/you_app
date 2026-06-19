import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:you_app/services/analytics_service.dart';
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
    await locator<AnalyticsService>().init();

    // Initialize Push Notifications
    try {
      await locator<PushNotificationService>().initialise();
    } catch (e) {
      debugPrint('Error initializing PushNotificationService: $e');
    }

    setupDialogUi();
    setupBottomSheetUi();
    runApp(const MainApp());
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
