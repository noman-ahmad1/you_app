import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';

class SignupViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  Future navigateToResetPasswordView() async {
    _navigationService.navigateToResetPasswordView();
  }

  Future navigateToLoginView() async {
    _navigationService.navigateToLoginView();
  }

  Future navigateToUserInfoView() async {
    _navigationService.navigateToUserInfoView();
  }
}
