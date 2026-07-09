import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/services/base/app_log.dart';
import 'package:you_app/services/user_service.dart';
import 'package:you_app/ui/shared/in_app_notification_banner.dart';
import 'package:you_app/ui/views/chat/chat_viewmodel.dart';

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
  RemoteMessage? pendingNotification;

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
        // Never log message.data / notification content — it can carry PII or
        // a message preview. Keep only a release-gated breadcrumb.
        AppLog.info('PushNotification', 'Foreground message received');

        if (message.notification != null) {
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
        pendingNotification = initialMessage;
      }

      // 6. Token management: Get initial token and watch for refreshes
      await _saveDeviceToken();
      _fcm.onTokenRefresh.listen((token) async {
        // Never log the token value (device secret); breadcrumb only.
        AppLog.info('PushNotification', 'FCM token refreshed');
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
        // Never log the token value (device secret); breadcrumb only.
        AppLog.info('PushNotification', 'FCM token obtained');
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
  void handleNotificationClick(RemoteMessage message) {
    _handleNotificationClick(message);
  }

  void _handleNotificationClick(RemoteMessage message) {
    // Don't log the full payload (may carry PII); breadcrumb only.
    AppLog.info('PushNotification', 'Notification tapped');
    final type = message.data['type'] as String?;
    final navigationService = locator<NavigationService>();
    if (type == 'request_accepted') {
      navigationService.clearStackAndShow(Routes.homeView, arguments: const HomeViewArguments(initialIndex: 2));
    } else if (type == 'new_message') {
      final chatId = message.data['chatId'] as String?;
      if (chatId != null) {
        // Prevent routing if already in the exact same chat
        if (type == 'new_message') {
           if (ChatViewModel.isActive && ChatViewModel.activeChatId == chatId) {
             return; // Already in this chat
           }
        }

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
      navigationService.clearStackAndShow(Routes.volunteerHomeView);
    } else if (type == 'broadcast') {
      // Broadcasts carry no routing data — land on home by default.
      navigationService.clearStackAndShow(Routes.homeView);
    }
  }
}
