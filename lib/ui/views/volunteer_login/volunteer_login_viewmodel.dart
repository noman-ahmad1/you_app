import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/services/auth_service.dart';

class VolunteerLoginViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _authenticationService = locator<AuthenticationService>();
  final _dialogService = locator<DialogService>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signInVolunteer() async {
    _validationError = null;
    notifyListeners();

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _validationError = 'Email and password are required.';
      notifyListeners();
      return;
    }

    setBusy(true);

    try {
      // 1. Calls the AuthService for standard email/password login
      // NOTE: Using positional arguments (email, password) to match the service signature.
      await _authenticationService.signInWithEmail(
        email,
        password,
      );

      // On successful login, navigate to the volunteer home view
      _navigationService.replaceWith(Routes.volunteerHomeView);
    } catch (e) {
      String errorMessage = _authenticationService.error ??
          'Login failed. Please check your credentials.';
      _showErrorDialog('Login Failed', errorMessage);
      _validationError = errorMessage;
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  String? _validationError;
  String? get validationError => _validationError;

  Future navigateToVolunteerResetPassword() async {
    _navigationService.navigateToVolunteerResetPasswordView();
  }

  Future navigateToVolunteerSignUp() async {
    _navigationService.navigateToVolunteerSignupView();
  }

  Future navigateToVolunteerHome() async {
    _navigationService.navigateToVolunteerHomeView();
  }

  void _showErrorDialog(String title, String description) {
    _dialogService.showDialog(title: title, description: description);
  }
}
