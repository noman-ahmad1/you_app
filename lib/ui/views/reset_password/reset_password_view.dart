import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/widgets.dart';

import 'reset_password_viewmodel.dart';

class ResetPasswordView extends StackedView<ResetPasswordViewModel> {
  const ResetPasswordView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    ResetPasswordViewModel viewModel,
    Widget? child,
  ) {
    final passwordController = TextEditingController();
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
                child: viewModel.isVerified == 1
                    ? Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Space.verticalSpaceSmall(context),
                          Space.verticalSpaceTiny(context),
                          Text(
                            'Forgot Password',
                            style: GoogleFonts.crimsonPro(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: AppColors.secondary),
                          ),
                          Space.verticalSpaceVTiny(context),
                          Text(
                            'We will share a password reset link on your email address',
                            style: GoogleFonts.crimsonPro(
                                color: AppColors.primaryVeryDark, fontSize: 15),
                          ),
                          Column(
                            children: [
                              Space.verticalSpaceVTiny(context),
                              CustomTextField(
                                controller: passwordController,
                                labelText: 'Email Address',
                                keyboardType: TextInputType.emailAddress,
                              ),
                              Space.verticalSpaceVTiny(context),
                              SizedBox(height: screenSize.height * 0.045),
                              CustomButton(
                                  text: '    Send    ', onPressed: () {}),
                              Space.verticalSpaceLarge(context),
                              Space.verticalSpaceSmall(context),
                              InkWell(
                                splashColor: AppColors.peachDark,
                                onTap: () {
                                  viewModel.navigateToLoginView();
                                },
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.crimsonPro(
                                        color: AppColors.background,
                                        fontSize: 15),
                                    children: <TextSpan>[
                                      TextSpan(text: 'Try logging in?'),
                                      TextSpan(
                                        text: ' Login Now',
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
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Space.verticalSpaceSmall(context),
                          Space.verticalSpaceTiny(context),
                          Text(
                            'Set a new password',
                            style: GoogleFonts.crimsonPro(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: AppColors.secondary),
                          ),
                          Space.verticalSpaceVTiny(context),
                          // Text(
                          //     'We will share a password reset link on your email address',
                          //     style: GoogleFonts.crimsonPro(
                          //         color: AppColors.primaryVeryDark,
                          //         fontSize: 15),
                          //   ),
                          Column(
                            children: [
                              // Space.verticalSpaceVTiny(context),
                              Space.verticalSpaceVTiny(context),
                              CustomTextField(
                                controller: passwordController,
                                labelText: 'Type a password',
                                keyboardType: TextInputType.emailAddress,
                              ),
                              Space.verticalSpaceVTiny(context),
                              CustomTextField(
                                controller: passwordController,
                                labelText: 'Confirm password',
                                obscureText: true,
                              ),
                              SizedBox(height: screenSize.height * 0.045),
                              CustomButton(
                                  text: '    Reset    ', onPressed: () {}),
                              Space.verticalSpaceLarge(context),
                              Space.verticalSpaceSmall(context),
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.crimsonPro(
                                      color: AppColors.background,
                                      fontSize: 15),
                                  children: <TextSpan>[
                                    TextSpan(text: 'Try logging in?'),
                                    TextSpan(
                                      text: ' Login Now',
                                      style: GoogleFonts.crimsonPro(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.background),
                                    ),
                                  ],
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
  ResetPasswordViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      ResetPasswordViewModel();
}
