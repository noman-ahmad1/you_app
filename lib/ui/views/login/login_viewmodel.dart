import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';

class LoginViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  Future navigateToResetPassword() async {
    _navigationService.navigateToResetPasswordView();
  }

  Future navigateToSignUp() async {
    _navigationService.navigateToSignupView();
  }

  Future navigateToHome() async {
    _navigationService.navigateToHomeView();
  }
}
