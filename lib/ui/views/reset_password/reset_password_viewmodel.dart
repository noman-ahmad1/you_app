import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';

class ResetPasswordViewModel extends BaseViewModel {
  int isVerified = 1;
  final _navigationService = locator<NavigationService>();

  Future navigateToLoginView() async {
    _navigationService.navigateToLoginView();
  }
}
