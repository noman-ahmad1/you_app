import 'package:stacked/stacked.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/services/auth_service.dart';

class StartupViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _authenticationService = locator<AuthenticationService>();

  // Place anything here that needs to happen before we get into the application
  Future runStartupLogic() async {
    // You can keep a short delay for a splash screen effect
    await Future.delayed(const Duration(seconds: 2));

    // --- Role-Based Navigation Logic ---

    // Assuming AuthenticationService provides a simple way to check the current user's role
    final userRole = await _authenticationService.getCurrentUserRole();
    print('Startup Logic: Detected User Role: $userRole');

    if (userRole == 'volunteer') {
      _navigationService.replaceWith(Routes.volunteerHomeView);
    } else if (userRole == 'user' || userRole == 'admin') {
      // Added 'admin' check for safety
      _navigationService.replaceWith(Routes.homeView);
    } else {
      _navigationService.replaceWithWelcomeView();
    }
  }
}
