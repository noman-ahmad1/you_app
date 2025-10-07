import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/services/auth_service.dart';

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

  static void _noop() {}

  Future<void> sendVerificationCode() async {
    _validationError = null;
    notifyListeners();

    final nationalNumber =
        phoneNumberController.text.trim().replaceAll(RegExp(r'\s+'), '');

    // Enhanced validation
    if (nationalNumber.isEmpty) {
      _validationError = 'Please enter your mobile number.';
      notifyListeners();
      return;
    }

    if (!RegExp(r'^[0-9]{10,15}$').hasMatch(nationalNumber)) {
      _validationError = 'Please enter a valid mobile number (10-15 digits).';
      notifyListeners();
      return;
    }

    final fullPhoneNumber = '$_dialCode$nationalNumber';

    // Validate international phone number format
    if (!RegExp(r'^\+\d{1,4}\d{10,15}$').hasMatch(fullPhoneNumber)) {
      _validationError = 'Please enter a valid international phone number.';
      notifyListeners();
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
      _validationError = 'Please enter the verification code.';
      setBusy(false);
      notifyListeners();
      return;
    }

    if (!RegExp(r'^[0-9]{6}$').hasMatch(smsCode)) {
      _validationError = 'Please enter a valid 6-digit verification code.';
      setBusy(false);
      notifyListeners();
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

      // Only cancel if the service provides this method
      if (_authenticationService.cancelPhoneVerification != null) {
        _authenticationService.cancelPhoneVerification();
      }
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

    // Comprehensive validation
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      _validationError = 'All fields are required.';
      notifyListeners();
      return;
    }

    final email = emailController.text.trim();
    if (!RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email)) {
      _validationError = 'Please enter a valid email address.';
      notifyListeners();
      return;
    }

    if (passwordController.text.length < 6) {
      _validationError = 'Password must be at least 6 characters long.';
      notifyListeners();
      return;
    }

    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d).{6,}$')
        .hasMatch(passwordController.text)) {
      _validationError = 'Password must contain both letters and numbers.';
      notifyListeners();
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _validationError = 'Passwords do not match.';
      notifyListeners();
      return;
    }

    if (!isPhoneVerified) {
      _validationError = 'Please verify your mobile number before signing up.';
      notifyListeners();
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

  void navigateToVolunteerLogin() {
    _navigationService.replaceWithVolunteerLoginView();
  }

  Future<void> back() async {
    await _navigationService.back();
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
