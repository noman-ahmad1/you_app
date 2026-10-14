import 'dart:async';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:flutter/foundation.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/models/app_user.dart';
import 'package:you_app/services/user_service.dart';

class VolunteerPendingVerificationViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _userService = locator<UserService>();
  final _authService = locator<AuthenticationService>();

  StreamSubscription<AppUser?>? _userStreamSubscription;

  VolunteerPendingVerificationViewModel() {
    _listenToUserStatus();
  }

  void _listenToUserStatus() {
    final uid = _authService.currentUid;
    if (uid == null) return;

    _userStreamSubscription = _userService.streamUser(uid).listen((appUser) {
      if (appUser != null) {
        if (appUser.status == 'active') {
          // Application is approved, navigate to home!
          _navigationService.replaceWithVolunteerHomeView();
        } else if (appUser.status == 'rejected') {
          // Optional: handle rejected application scenario
          // e.g. show dialog or navigate to support
        }
      }
    });
  }

  // Goes through AuthenticationService so sign-out also removes the FCM token
  // and clears session caches — calling FirebaseAuth directly skipped both,
  // leaving the device registered for this account's pushes.
  void logout() async {
    try {
      await _authService.signOut();
    } catch (e) {
      // Still signed in — stay put rather than show the welcome screen.
      debugPrint('Pending verification sign-out failed: $e');
      return;
    }
    _navigationService.clearStackAndShow(Routes.welcomeView);
  }

  @override
  void dispose() {
    _userStreamSubscription?.cancel();
    super.dispose();
  }
}
