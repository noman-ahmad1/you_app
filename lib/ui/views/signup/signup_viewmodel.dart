import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/ui/common/validators.dart';

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

  /// Sets the inline error and shows an explanatory dialog.
  void _fail(String title, String message) {
    _validationError = message;
    notifyListeners();
    _dialogService.showDialog(title: title, description: message);
  }

  void signUp() async {
    // 1. Reset local errors
    _validationError = null;
    notifyListeners();

    final firstName = firstNameController.text.trim();
    final lastName = secondNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmPasswordController.text;

    // 2. Client-Side Validation (each failure shows a specific dialog)
    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      _fail('Missing information', 'Please fill out all fields to continue.');
      return;
    }
    final firstNameError = Validators.personName(firstName, 'First name');
    if (firstNameError != null) {
      _fail('Invalid name', firstNameError);
      return;
    }
    final lastNameError = Validators.personName(lastName, 'Last name');
    if (lastNameError != null) {
      _fail('Invalid name', lastNameError);
      return;
    }
    final emailError = Validators.email(email);
    if (emailError != null) {
      _fail('Invalid email', emailError);
      return;
    }
    final passwordError = Validators.password(password);
    if (passwordError != null) {
      _fail('Weak password', passwordError);
      return;
    }
    if (password != confirm) {
      _fail("Passwords don't match",
          'Your password and confirmation must be identical.');
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
        _navigationService.clearStackAndShow(Routes.userInfoView,
            arguments: UserInfoViewArguments(uid: user.uid));
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
