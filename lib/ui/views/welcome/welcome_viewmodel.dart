import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import '../volunteer_signup/volunteer_signup_view.dart';

class WelcomeViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  Future navigateToLoginView() async {
    _navigationService.navigateToLoginView();
  }

  Future navigateToVolunteerSignup() async {
    _navigationService.navigateToVolunteerSignupView();
  }

  Future navigateToSignupView() async {
    _navigationService.navigateToSignupView();
  }

  Future navigateToVolunteerSignupInfo() async {
    _navigationService.navigateToVolunteerSignupInfoView(uid: '');
  }

  Future userInfo() async {
    _navigationService.navigateToUserInfoView(uid: '');
  }
}
