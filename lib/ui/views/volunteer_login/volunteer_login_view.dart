import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/widgets.dart';

import 'volunteer_login_viewmodel.dart';

class VolunteerLoginView extends StackedView<VolunteerLoginViewModel> {
  const VolunteerLoginView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    VolunteerLoginViewModel viewModel,
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
                    Space.verticalSpaceMedium(context),
                    Text(
                      'We\'re glad to see you',
                      style: GoogleFonts.crimsonPro(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary),
                    ),
                    Column(
                      children: [
                        SizedBox(height: screenSize.height * 0.04),
                        CustomTextField(
                          controller: viewModel.emailController,
                          labelText: 'Email Address',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        Space.verticalSpaceVTiny(context),
                        CustomTextField(
                          controller: viewModel.passwordController,
                          labelText: 'Type your password',
                          obscureText: true,
                        ),
                        SizedBox(height: screenSize.height * 0.045),
                        CustomButton(
                          text: viewModel.isBusy ? 'Logging Inn...' : 'Login',
                          onPressed: viewModel.isBusy
                              ? null
                              : viewModel.signInVolunteer,
                        ),
                        Space.verticalSpaceTiny(context),
                        InkWell(
                          splashColor: AppColors.peach,
                          onTap: () {
                            viewModel.navigateToVolunteerResetPassword();
                          },
                          child: Text(
                            'Forgot the password?',
                            style: GoogleFonts.crimsonPro(
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.background,
                                color: AppColors.background,
                                fontSize: 13),
                          ),
                        ),
                        Space.verticalSpaceSmall(context),
                        InkWell(
                          splashColor: AppColors.peach,
                          onTap: () {
                            viewModel.navigateToVolunteerSignUp();
                          },
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.crimsonPro(
                                  color: AppColors.background, fontSize: 15),
                              children: <TextSpan>[
                                TextSpan(text: 'Don\'t have an account?'),
                                TextSpan(
                                  text: ' Sign up',
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
  VolunteerLoginViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      VolunteerLoginViewModel();
}
