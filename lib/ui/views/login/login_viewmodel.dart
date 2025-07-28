import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';

class LoginViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  Future navigateToResetPasswordView() async {
    _navigationService.navigateToResetPasswordView();
  }

  Future navigateToSignUpView() async {
    _navigationService.navigateToSignupView();
  }
  Future navigateToHomeView() async {
    _navigationService.navigateToHomeView();
  }
}
