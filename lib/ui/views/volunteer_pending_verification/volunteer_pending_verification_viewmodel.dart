import 'dart:async';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/models/app_user.dart';
import 'package:you_app/services/user_service.dart';

class VolunteerPendingVerificationViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _userService = locator<UserService>();
  final _auth = FirebaseAuth.instance;

  StreamSubscription<AppUser?>? _userStreamSubscription;

  VolunteerPendingVerificationViewModel() {
    _listenToUserStatus();
  }

  void _listenToUserStatus() {
    final uid = _auth.currentUser?.uid;
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

  void logout() async {
    await _auth.signOut();
    _navigationService.clearStackAndShow(Routes.welcomeView);
  }

  @override
  void dispose() {
    _userStreamSubscription?.cancel();
    super.dispose();
  }
}
