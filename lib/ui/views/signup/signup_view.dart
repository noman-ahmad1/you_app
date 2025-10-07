import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/widgets.dart';

import 'signup_viewmodel.dart';

class SignupView extends StackedView<SignupViewModel> {
  const SignupView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    SignupViewModel viewModel,
    Widget? child,
  ) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.backgroundGradient,
              AppColors.peachDark,
              AppColors.secondary
            ],
            stops: [0, 0.33, 0.66, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenSize.height),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Space.verticalSpaceSmall(context),
                    Space.verticalSpaceTiny(context),
                    Text(
                      'Create your account',
                      style: GoogleFonts.crimsonPro(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary),
                    ),
                    Column(
                      children: [
                        Space.verticalSpaceTiny(context),
                        // SizedBox(height: screenSize.height * 0.04),
                        CustomTextField(
                          controller: viewModel.firstNameController,
                          labelText: 'First Name',
                          keyboardType: TextInputType.name,
                        ),
                        Space.verticalSpaceVTiny(context),
                        CustomTextField(
                          controller: viewModel.secondNameController,
                          labelText: 'Second Name',
                          keyboardType: TextInputType.name,
                        ),
                        Space.verticalSpaceVTiny(context),
                        CustomTextField(
                          controller: viewModel.emailController,
                          labelText: 'Email Address',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        Space.verticalSpaceVTiny(context),
                        CustomTextField(
                          controller: viewModel.passwordController,
                          labelText: 'Type a password',
                          keyboardType: TextInputType.visiblePassword,
                        ),
                        Space.verticalSpaceVTiny(context),
                        CustomTextField(
                          controller: viewModel.confirmPasswordController,
                          labelText: 'Confirm password',
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: true,
                        ),
                        SizedBox(height: screenSize.height * 0.045),
                        if (viewModel.validationError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Text(
                              viewModel.validationError!,
                              style: GoogleFonts.crimsonPro(
                                color: AppColors.error,
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                        CustomButton(
                            text:
                                viewModel.isBusy ? 'Signing Up...' : 'Sign Up',
                            onPressed: () {
                              viewModel.isBusy
                                  ? null // Disable button when busy
                                  : viewModel.signUp();
                            }),
                        Space.verticalSpaceTiny(context),
                        InkWell(
                          splashColor: AppColors.peachDark,
                          onTap: () {
                            viewModel.navigateToResetPasswordView();
                          },
                          child: const Text(
                            'Forgot the password?',
                            style: TextStyle(
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.background,
                                color: AppColors.background,
                                fontSize: 13),
                          ),
                        ),
                        SizedBox(
                          height: screenSize.height * 0.05,
                        ),
                        const CenteredDividerWithText(
                          text: 'Or Sign up with',
                          // color: AppColors.background,
                          spacing: 10,
                        ),
                        Space.verticalSpaceTiny(context),
                        Space.horizontalSpaceVTiny(context),
                        InkWell(
                          onTap: () {
                            viewModel.isBusy
                                ? null
                                : viewModel.signInWithGoogle();
                          },
                          child: PaddedImageContainer(
                            image: AssetImage(AppConstants.google),
                            containerWidth: screenSize.width * 0.28,
                            containerHeight: screenSize.height * 0.07,
                          ),
                        ),
                        Space.verticalSpaceTiny(context),
                        spacedDivider(context),
                        Space.verticalSpaceTiny(context),
                        InkWell(
                          splashColor: AppColors.peachDark,
                          onTap: () {
                            viewModel.navigateToLoginView();
                          },
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.crimsonPro(
                                  color: AppColors.background, fontSize: 15),
                              children: <TextSpan>[
                                TextSpan(text: 'Already have an account?'),
                                TextSpan(
                                  text: ' Login',
                                  style: GoogleFonts.crimsonPro(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.background),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  SignupViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      SignupViewModel();
}
