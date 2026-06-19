import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/base/app_log.dart';
import 'package:you_app/services/push_notification_service.dart';
import 'package:you_app/services/monetization_service.dart';

class StartupViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _authenticationService = locator<AuthenticationService>();

  // Place anything here that needs to happen before we get into the application
  Future runStartupLogic() async {
    // Initialize MonetizationService silently in the background
    locator<MonetizationService>();

    // You can keep a short delay for a splash screen effect
    await Future.delayed(const Duration(seconds: 2));

    // --- Role-Based Navigation Logic ---

    // Assuming AuthenticationService provides a simple way to check the current user's role
    final userRole = await _authenticationService.getCurrentUserRole();
    AppLog.info('StartupViewModel', 'Detected user role: $userRole');

    if (userRole == 'volunteer') {
      final currentUser = _authenticationService.currentUser;
      if (currentUser != null && currentUser.status == 'profile_incomplete') {
        await _navigationService.clearStackAndShow(
          Routes.volunteerSignupInfoView,
          arguments: VolunteerSignupInfoViewArguments(uid: currentUser.uid),
        );
      } else if (currentUser != null && currentUser.status == 'pending_verification') {
        await _navigationService.clearStackAndShow(Routes.volunteerPendingVerificationView);
      } else {
        await _navigationService.clearStackAndShow(Routes.volunteerHomeView);
      }
    } else if (userRole == 'user' || userRole == 'admin') {
      // Added 'admin' check for safety
      await _navigationService.clearStackAndShow(Routes.homeView);
    } else {
      await _navigationService.clearStackAndShow(Routes.welcomeView);
    }

    // Process any push notification that woke up the app from a terminated state
    final pushService = locator<PushNotificationService>();
    final pendingMsg = pushService.pendingNotification;
    if (pendingMsg != null) {
      pushService.pendingNotification = null;
      // Allow a brief moment for the root route to settle
      await Future.delayed(const Duration(milliseconds: 300));
      pushService.handleNotificationClick(pendingMsg);
    }
  }
}
