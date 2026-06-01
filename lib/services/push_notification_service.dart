import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/services/user_service.dart';
import 'package:you_app/ui/shared/in_app_notification_banner.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Background Message received: ${message.messageId}");
}

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final SnackbarService _snackbarService = locator<SnackbarService>();
  // Uncomment when implementing custom tap navigation
  // final NavigationService _navigationService = locator<NavigationService>();

  bool _initialized = false;

  /// Initializes FCM and configures foreground/background/clicked listeners
  Future<void> initialise() async {
    if (_initialized) return;

    // 1. Request permissions (specifically for iOS and Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // 2. Set the background messaging handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // 3. Handle messages when the app is in the foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint(
              'Message also contained a notification: ${message.notification}');

          // Display our custom elegant sliding notification banner
          InAppNotificationBanner.show(
            title: message.notification?.title ?? 'Notification',
            body: message.notification?.body ?? '',
            type: message.data['type'] ?? '',
            onTap: () {
              _handleNotificationClick(message);
            },
          );
        }
      });

      // 4. Handle notification clicks when the app is in the background (but not terminated)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('App opened from background notification!');
        _handleNotificationClick(message);
      });

      // 5. Check if the app was opened from a completely terminated state via a notification
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App opened from terminated notification!');
        _handleNotificationClick(initialMessage);
      }

      // 6. Token management: Get initial token and watch for refreshes
      await _saveDeviceToken();
      _fcm.onTokenRefresh.listen((token) async {
        debugPrint('FCM Token Refreshed: $token');
        await _updateTokenInFirestore(token);
      });

      _initialized = true;
    }
  }

  /// Retrieves the current FCM token and registers/updates it in Firestore
  Future<void> _saveDeviceToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint('FCM Token obtained: $token');
        await _updateTokenInFirestore(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// Updates the FCM token for the currently logged-in user in Firestore
  Future<void> _updateTokenInFirestore(String token) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userService = locator<UserService>();
        await userService.update(currentUser.uid, {
          'fcmToken': token,
        });
        debugPrint('Successfully saved FCM token to user ${currentUser.uid}');
      }
    } catch (e) {
      debugPrint('Failed to save FCM token to Firestore: $e');
    }
  }

  /// Utility function to trigger explicit FCM token update (e.g. called right after successful login)
  Future<void> syncTokenAfterLogin() async {
    await _saveDeviceToken();
  }

  /// Handles custom navigation/actions when a notification is tapped
  void _handleNotificationClick(RemoteMessage message) {
    debugPrint('Handling notification click: ${message.data}');
    final type = message.data['type'] as String?;
    final navigationService = locator<NavigationService>();
    if (type == 'request_accepted') {
      navigationService.replaceWithHomeView(initialIndex: 2);
    } else if (type == 'new_message') {
      final chatId = message.data['chatId'] as String?;
      if (chatId != null) {
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId != null) {
          final parts = chatId.split('_');
          final targetId =
              parts.firstWhere((id) => id != currentUserId, orElse: () => '');
          navigationService.navigateToChatView(
            volunteerId: targetId,
            volunteerName: "Chat",
            requestId: targetId,
          );
        }
      }
    } else if (type == 'request_received' || type == 'chat_request') {
      navigationService.replaceWithVolunteerHomeView();
    }
  }
}
