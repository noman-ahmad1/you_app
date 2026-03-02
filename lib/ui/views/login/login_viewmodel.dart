import 'package:flutter/widgets.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/models/app_user.dart';
import 'package:you_app/services/auth_service.dart';

class LoginViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _authenticationService = locator<AuthenticationService>();
  final _dialogService = locator<DialogService>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? _validationError;
  String? get validationError => _validationError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signInWithEmail() async {
    _validationError = null;
    notifyListeners();

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _validationError = 'Email and password fields are required.';
      notifyListeners();
      return;
    }

    setBusy(true);

    try {
      // 1. Call the AuthService to sign the user in.
      await _authenticationService.signInWithEmail(email, password);

      // 2. Get the logged-in user's data from the service.
      final user = _authenticationService.currentUser;

      // 3. Safety check in case the user data is not available.
      if (user == null) {
        throw Exception('Failed to load user data after login.');
      }

      // 4. Navigate based on the user's role.
      if (user.role == UserRole.volunteer) {
        _navigationService.replaceWith(Routes.volunteerHomeView);
      } else {
        // Both 'user' and 'admin' roles go to the main home view.
        _navigationService.replaceWith(Routes.homeView);
      }
    } catch (e) {
      String errorMessage = _authenticationService.error ??
          'Login failed. Please check your email and password.';
      _showErrorDialog('Login Failed', errorMessage);
      _validationError = errorMessage;
      notifyListeners(); // Ensure error is displayed
    } finally {
      setBusy(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _validationError = null;
    notifyListeners();
    setBusy(true);

    try {
      // 2. Calls the AuthService for Google Sign-In
      await _authenticationService.signInWithGoogle();

      // On successful login, navigate to the home view
      _navigationService.replaceWith(Routes.homeView);
    } catch (e) {
      String errorMessage = _authenticationService.error ??
          'Google Sign-In failed. Please try again.';
      _showErrorDialog('Google Sign-In Failed', errorMessage);
      _validationError = errorMessage;
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  Future navigateToResetPassword() async {
    _navigationService.navigateToResetPasswordView();
  }

  Future navigateToSignUp() async {
    _navigationService.navigateToSignupView();
  }

  Future navigateToHome() async {
    _navigationService.navigateToHomeView();
  }

  void _showErrorDialog(String title, String description) {
    _dialogService.showDialog(title: title, description: description);
  }
}
