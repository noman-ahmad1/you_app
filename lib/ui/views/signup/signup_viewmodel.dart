import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/services/auth_service.dart';

class SignupViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _authenticationService = locator<AuthenticationService>();
  final _dialogService = locator<DialogService>();

  final firstNameController = TextEditingController();
  final secondNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? _validationError;
  String? get validationError => _validationError;

  void signUp() async {
    // 1. Reset local errors
    _validationError = null;
    notifyListeners();

    // 2. Client-Side Validation
    if (firstNameController.text.isEmpty ||
        secondNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      _validationError = 'All fields must be filled out.';
      notifyListeners();
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _validationError = 'Passwords do not match.';
      notifyListeners();
      return;
    }

    // Check for a minimum password length if not handled by Firebase error
    if (passwordController.text.length < 6) {
      _validationError = 'Password must be at least 6 characters.';
      notifyListeners();
      return;
    }

    // Clear the error from the service before calling
    _authenticationService.clearError();
    setBusy(true);

    try {
      // ✅ STAGE 1: Call the Authentication service method (User Role)
      final user = await _authenticationService.signUpUser(
        email: emailController.text.trim(),
        password: passwordController.text,
        firstName: firstNameController.text.trim(),
        lastName: secondNameController.text.trim(),
      );

      // 3. Success: Navigate to the next screen (User Info/Profile Completion)
      _navigationService.replaceWith(
        Routes
            .userInfoView, // Use your actual route name for profile completion
        arguments: UserInfoViewArguments(uid: user!.uid), // Pass the UID
      );
    } catch (e) {
      // 4. Server Error Handling (Firebase or Firestore exceptions)
      String errorMessage = 'An unexpected error occurred during sign up.';

      // Check for service-level errors
      if (_authenticationService.error != null) {
        errorMessage = _authenticationService.error!;
      } else {
        errorMessage = e.toString().contains('Exception:')
            ? e.toString().split('Exception: ')[1]
            : e.toString();
      }

      // Display the error using the DialogService
      _dialogService.showDialog(
        title: 'Sign Up Failed',
        description: errorMessage,
      );
    } finally {
      setBusy(false);
    }
  }

  void signInWithGoogle() async {
    // Clear local error messages
    _validationError = null;
    _authenticationService.clearError();
    setBusy(true);

    try {
      // 1. Call the service to initiate Google Sign-in
      final user = await _authenticationService.signInWithGoogle();

      if (user != null) {
        // 2. Success: Navigate to the next screen (User Info/Profile Completion)
        // This handles both new sign-ups and existing sign-ins via Google.
        _navigationService.replaceWith(
          Routes.userInfoView,
          arguments: UserInfoViewArguments(uid: user.uid),
        );
      } else {
        // Safety fallback, though the service usually throws an error if it fails
        throw Exception(
            "Google Sign-In was cancelled or failed to return a user.");
      }
    } catch (e) {
      // 3. Error Handling
      String errorMessage =
          'An unexpected error occurred during Google sign-in.';

      if (_authenticationService.error != null) {
        // Use the detailed error from the service
        errorMessage = _authenticationService.error!;
      } else {
        // Fallback for general exceptions
        errorMessage = e.toString().contains('Exception:')
            ? e.toString().split('Exception: ')[1]
            : e.toString();
      }

      // Display the error using the DialogService
      _dialogService.showDialog(
        title: 'Google Sign In Failed',
        description: errorMessage,
      );
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  Future navigateToResetPasswordView() async {
    _navigationService.navigateToResetPasswordView();
  }

  Future navigateToLoginView() async {
    _navigationService.navigateToLoginView();
  }

  // Future navigateToUserInfoView() async {
  //   _navigationService.navigateToUserInfoView(uid: uid);
  // }
}
