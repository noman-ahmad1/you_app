import 'package:flutter/widgets.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/services/auth_service.dart';

class ResetPasswordViewModel extends BaseViewModel {
  final _authenticationService = locator<AuthenticationService>();
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();

  final emailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Reactive state to show the email confirmation screen (Phase 1a)
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

  // NOTE: This state is currently unused in the updated View logic,
  // as the View will rely on the presence of the oobCode to determine Phase 2.
  final int _isVerified = 1;
  int get isVerified => _isVerified;

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
      await _authenticationService.sendPasswordResetEmail(email: email);

      // --- NEW LOGIC: Update state instead of showing dialog and navigating ---
      _sentEmail = email;
      _isEmailSent.value = true;
      notifyListeners();
      // ------------------------------------------------------------------------
    } catch (e) {
      // 3. Handle service errors
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
    required String oobCode, // Added required oobCode
    required String newPassword,
    required String confirmPassword,
  }) async {
    // Input validation
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
    if (newPassword.length < 6) {
      await _dialogService.showDialog(
          title: 'Validation Error',
          description: 'Password must be at least 6 characters long.');
      return;
    }

    setBusy(true);
    try {
      // 1. Call the service function
      await _authenticationService.confirmPasswordReset(
        oobCode: oobCode,
        newPassword: newPassword,
      );

      // 2. Notify success and navigate
      await _dialogService.showDialog(
        title: 'Success',
        description:
            'Your password has been reset successfully. You can now log in.',
      );

      // Navigate back to the login view after successful password reset
      navigateToLoginView();
    } catch (e) {
      // 3. Handle service errors
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      await _dialogService.showDialog(
          title: 'Error', description: errorMessage);
    } finally {
      setBusy(false);
    }
  }

  Future navigateToLoginView() async {
    _navigationService.navigateToLoginView();
  }
}
