import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';

class ChatbotViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  Future back() async {
    _navigationService.back();
  }
}
