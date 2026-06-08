import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:you_app/services/push_notification_service.dart';
import 'package:you_app/app/app.bottomsheets.dart';
import 'package:you_app/app/app.dialogs.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/firebase_options.dart';
import 'package:you_app/ui/common/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive and clear chatbot history on application startup
  await Hive.initFlutter();
  final chatbotBox = await Hive.openBox('chatbot_history');
  await chatbotBox.clear();

  await setupLocator();

  // Initialize Push Notifications
  try {
    await locator<PushNotificationService>().initialise();
  } catch (e) {
    debugPrint('Error initializing PushNotificationService: $e');
  }

  setupDialogUi();
  setupBottomSheetUi();
  runApp(const MainApp());
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
      ],
    );
  }
}
