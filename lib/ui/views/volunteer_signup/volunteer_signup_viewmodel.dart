import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/ui/common/validators.dart';

enum DialogType { infoAlert }

class VolunteerSignupViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _authenticationService = locator<AuthenticationService>();
  final _dialogService = locator<DialogService>();

  final phoneNumberController = TextEditingController();
  final smsCodeController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? _validationError;
  String? get validationError => _validationError;

  String _dialCode = '+92';
  bool _isPhoneVerified = false;

  bool get isPhoneVerified => _isPhoneVerified;
  bool get isCodeSent => _authenticationService.isPhoneCodeSent;
  String? get pendingPhoneNumber => _authenticationService.pendingPhoneNumber;

  void setDialCode(String dialCode) {
    _dialCode = dialCode;
  }

  Future<void> sendVerificationCode() async {
    _validationError = null;
    notifyListeners();

    final nationalNumber =
        phoneNumberController.text.trim().replaceAll(RegExp(r'\s+'), '');

    // Enhanced validation
    if (nationalNumber.isEmpty) {
      _setError('Mobile number required', 'Please enter your mobile number.');
      return;
    }

    if (!RegExp(r'^[0-9]{10,15}$').hasMatch(nationalNumber)) {
      _setError('Invalid number',
          'Please enter a valid mobile number (10–15 digits, no spaces).');
      return;
    }

    final fullPhoneNumber = '$_dialCode$nationalNumber';

    // Validate international phone number format
    if (!RegExp(r'^\+\d{1,4}\d{10,15}$').hasMatch(fullPhoneNumber)) {
      _setError(
          'Invalid number', 'Please enter a valid international phone number.');
      return;
    }

    _authenticationService.clearError();
    setBusy(true);

    try {
      await _authenticationService.sendPhoneVerification(fullPhoneNumber);

      // On successful code sent, navigate to the OTP view
      _navigationService.navigateTo(Routes.volunteerOtpView);
    } catch (e) {
      String errorMessage = _authenticationService.error ??
          'Failed to send verification code. Please try again.';
      await _showErrorDialog('Verification Failed', errorMessage);
    } finally {
      if (!_authenticationService.isPhoneCodeSent) {
        setBusy(false);
      }
    }
  }

  Future<void> verifySmsCode({
    VoidCallback? onVerificationSuccess,
  }) async {
    setBusy(true);
    _validationError = null;
    notifyListeners();

    final smsCode = smsCodeController.text.trim();

    // Enhanced OTP validation
    if (smsCode.isEmpty) {
      setBusy(false);
      _setError('Code required', 'Please enter the verification code.');
      return;
    }

    if (!RegExp(r'^[0-9]{6}$').hasMatch(smsCode)) {
      setBusy(false);
      _setError('Invalid code',
          'Please enter the 6-digit verification code we sent.');
      return;
    }

    try {
      // Remove the success variable assignment since verifyPhoneCode returns void
      await _authenticationService.verifyPhoneCode(smsCode);

      // Check if the service marks it as verified instead
      if (_authenticationService.isPhoneVerified) {
        _isPhoneVerified = true;

        // Show success dialog first
        await _showSuccessDialog('Verification Successful',
            'Your mobile number has been verified successfully!');

        // Execute callback if provided
        if (onVerificationSuccess != null) {
          onVerificationSuccess();
        } else {
          // Fallback: navigate back after a short delay
          await Future.delayed(const Duration(milliseconds: 1500));
          _navigationService.back();
        }
      } else {
        // If service doesn't mark it as verified, show error
        throw Exception('Verification failed - phone not marked as verified');
      }
    } catch (e) {
      String errorMessage = _authenticationService.error ??
          'Invalid verification code. Please check the code and try again.';
      await _showErrorDialog('Verification Failed', errorMessage);

      _authenticationService.cancelPhoneVerification();
    } finally {
      setBusy(false);
    }
  }

  Future<void> resendCode() async {
    _authenticationService.clearError();
    setBusy(true);

    try {
      await _authenticationService.resendPhoneVerification();
      await _showInfoDialog('Code Sent',
          'A new verification code has been sent to your mobile number.');
    } catch (e) {
      String errorMessage = _authenticationService.error ??
          'Failed to resend verification code. Please try again.';
      await _showErrorDialog('Resend Failed', errorMessage);
    } finally {
      setBusy(false);
    }
  }

  void signUpVolunteer() async {
    _validationError = null;
    notifyListeners();

    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmPasswordController.text;

    // Comprehensive validation (each failure shows a specific dialog)
    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _setError(
          'Missing information', 'Please fill out all fields to continue.');
      return;
    }
    final emailError = Validators.email(email);
    if (emailError != null) {
      _setError('Invalid email', emailError);
      return;
    }
    final passwordError = Validators.password(password);
    if (passwordError != null) {
      _setError('Weak password', passwordError);
      return;
    }
    if (password != confirm) {
      _setError("Passwords don't match",
          'Your password and confirmation must be identical.');
      return;
    }
    if (!isPhoneVerified) {
      _setError('Verify your number',
          'Please verify your mobile number before signing up.');
      return;
    }

    _authenticationService.clearError();
    setBusy(true);

    try {
      final user = await _authenticationService.signUpVolunteer(
        email: email,
        password: passwordController.text,
      );

      if (user != null) {
        await _showSuccessDialog('Sign Up Successful',
            'Your volunteer account has been created successfully!');

        _navigationService.replaceWith(
          Routes.volunteerSignupInfoView,
          arguments: VolunteerSignupInfoViewArguments(uid: user.uid),
        );
      } else {
        throw Exception('User creation failed');
      }
    } catch (e) {
      String errorMessage = _authenticationService.error ??
          'Failed to create account. Please try again.';
      await _showErrorDialog('Sign Up Failed', errorMessage);
    } finally {
      setBusy(false);
    }
  }

  void navigateToLogin() {
    // Unified login routes by role; there is no separate volunteer sign-in.
    _navigationService.replaceWithLoginView();
  }

  Future<void> back() async {
    _navigationService.back();
  }

  /// Sets the inline error and shows an explanatory dialog.
  void _setError(String title, String message) {
    _validationError = message;
    notifyListeners();
    _showErrorDialog(title, message);
  }

  // Enhanced dialog methods with proper await
  Future<void> _showErrorDialog(String title, String description) async {
    await _dialogService.showDialog(
      title: title,
      description: description,
    );
  }

  Future<void> _showInfoDialog(String title, String description) async {
    await _dialogService.showDialog(
      title: title,
      description: description,
    );
  }

  Future<void> _showSuccessDialog(String title, String description) async {
    await _dialogService.showDialog(
      title: title,
      description: description,
    );
  }

  // Method to update phone verification status (call this when returning to signup screen)
  void updatePhoneVerificationStatus() {
    _isPhoneVerified = _authenticationService.isPhoneVerified;
    notifyListeners();
  }

  @override
  void dispose() {
    smsCodeController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
