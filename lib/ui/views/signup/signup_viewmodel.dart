import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';

class SignupViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  final firstNameController = TextEditingController();
  final secondNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  Future navigateToResetPasswordView() async {
    _navigationService.navigateToResetPasswordView();
  }

  Future navigateToLoginView() async {
    _navigationService.navigateToLoginView();
  }

  Future navigateToUserInfoView() async {
    _navigationService.navigateToUserInfoView();
  }
}
