import 'package:flutter/widgets.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/services/auth_service.dart';

class VolunteerResetPasswordViewModel extends BaseViewModel {
  // Assuming AuthenticationService handles both user and volunteer auth logic
  final _authenticationService = locator<AuthenticationService>();
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();

  final emailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Reactive state to show the email confirmation screen
  final ReactiveValue<bool> _isEmailSent = ReactiveValue<bool>(false);
  bool get isEmailSent => _isEmailSent.value;

  // Store the email that the link was sent to, for the resend function
  String? _sentEmail;
  String? get sentEmail => _sentEmail;

  @override
  void dispose() {
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> sendPasswordResetLink(String email) async {
    // Input validation
    if (email.isEmpty || !email.contains('@')) {
      await _dialogService.showDialog(
        title: 'Validation Error',
        description: 'Please enter a valid email address.',
      );
      return;
    }

    setBusy(true);
    try {
      // NOTE: This assumes a service method exists for volunteers,
      // possibly the same one if the logic handles user types implicitly.
      await _authenticationService.sendPasswordResetEmail(email: email);

      // Update state to show the confirmation screen
      _sentEmail = email;
      _isEmailSent.value = true;
      notifyListeners();
    } catch (e) {
      await _dialogService.showDialog(
          title: 'Error',
          description: e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setBusy(false);
    }
  }

  Future<void> resendEmail() async {
    if (_sentEmail == null) {
      await _dialogService.showDialog(
          title: 'Error',
          description:
              'No email address registered. Please go back and enter an email.');
      return;
    }

    setBusy(true);
    try {
      await _authenticationService.sendPasswordResetEmail(email: _sentEmail!);

      await _dialogService.showDialog(
        title: 'Resent!',
        description:
            'The password reset link has been successfully resent to $_sentEmail.',
      );
    } catch (e) {
      await _dialogService.showDialog(
          title: 'Resend Failed',
          description: e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setBusy(false);
    }
  }

  Future<void> resetPassword({
    required String oobCode,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // Input validation (standard logic)
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      await _dialogService.showDialog(
          title: 'Validation Error',
          description: 'Please fill in both password fields.');
      return;
    }
    if (newPassword != confirmPassword) {
      await _dialogService.showDialog(
          title: 'Validation Error', description: 'Passwords do not match.');
      return;
    }

    setBusy(true);
    try {
      // Assuming this service method works for the volunteer context too
      await _authenticationService.confirmPasswordReset(
        oobCode: oobCode,
        newPassword: newPassword,
      );

      await _dialogService.showDialog(
        title: 'Success',
        description:
            'Your volunteer password has been reset successfully. You can now log in.',
      );

      navigateToVolunteerLogin();
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      await _dialogService.showDialog(
          title: 'Error', description: errorMessage);
    } finally {
      setBusy(false);
    }
  }

  Future navigateToVolunteerLogin() async {
    _navigationService
        .navigateToVolunteerLoginView(); // Assuming this is the correct route
  }
}
