import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/widgets.dart';
import 'login_viewmodel.dart';

class LoginView extends StackedView<LoginViewModel> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    LoginViewModel viewModel,
    Widget? child,
  ) {
    final emailController = TextEditingController();
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
                        // TextField(
                        //   decoration: InputDecoration(
                        //     fillColor: AppColors.primaryLight,
                        //     filled: true,
                        //     labelText: 'Email Address',
                        //     labelStyle:
                        //         const TextStyle(color: AppColors.secondaryLight),
                        //     enabledBorder: OutlineInputBorder(
                        //       borderRadius: BorderRadius.circular(27),
                        //       borderSide: const BorderSide(
                        //         color: AppColors.primaryDark,
                        //         width: 2.0,
                        //       ),
                        //     ),
                        //     focusedBorder: OutlineInputBorder(
                        //       borderRadius: BorderRadius.circular(27),
                        //       borderSide: const BorderSide(
                        //         color: AppColors.primaryVeryDark,
                        //         width: 2.0,
                        //       ),
                        //     ),
                        //     border: OutlineInputBorder(
                        //       // Fallback border
                        //       borderRadius: BorderRadius.circular(27),
                        //     ),
                        //   ),
                        // ),
                        CustomTextField(
                          controller: emailController,
                          labelText: 'Email Address',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        Space.verticalSpaceVTiny(context),
                        CustomTextField(
                          controller: passwordController,
                          labelText: 'Type your password',
                          obscureText: true,
                        ),
                        SizedBox(height: screenSize.height * 0.045),
                        CustomButton(
                            text: '  Login  ',
                            onPressed: () {
                              viewModel.navigateToHome();
                            }),
                        // ElevatedButton(
                        //   style: ButtonStyle(
                        //     backgroundColor:
                        //         WidgetStateProperty.all(AppColors.primaryVeryDark),
                        //     padding: WidgetStateProperty.all(
                        //         const EdgeInsets.symmetric(
                        //             vertical: 17, horizontal: 155)),
                        //     shape: WidgetStateProperty.all(RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(27),
                        //     )),
                        //   ),
                        //   onPressed: () {},
                        //   child: const Text(
                        //     'Login',
                        //     style: TextStyle(
                        //         color: AppColors.background,
                        //         fontWeight: FontWeight.w900,
                        //         fontSize: 18),
                        //   ),
                        // ),
                        Space.verticalSpaceTiny(context),
                        InkWell(
                          splashColor: AppColors.peach,
                          onTap: () {
                            viewModel.navigateToResetPassword();
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
                        SizedBox(
                          height: screenSize.height * 0.09,
                        ),
                        const CenteredDividerWithText(
                          text: 'Or Login with',
                          // color: AppColors.background,
                          spacing: 10,
                        ),
                        Space.verticalSpaceTiny(context),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PaddedImageContainer(
                              image: AssetImage(AppConstants.apple),
                              containerWidth: screenSize.width * 0.28,
                              containerHeight: screenSize.height * 0.07,
                            ),
                            Space.horizontalSpaceVTiny(context),
                            PaddedImageContainer(
                              image: AssetImage(AppConstants.google),
                              containerWidth: screenSize.width * 0.28,
                              containerHeight: screenSize.height * 0.07,
                            ),
                          ],
                        ),
                        Space.verticalSpaceTiny(context),
                        spacedDivider(context),
                        Space.verticalSpaceSmall(context),
                        InkWell(
                          splashColor: AppColors.peach,
                          onTap: () {
                            viewModel.navigateToSignUp();
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
  LoginViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      LoginViewModel();
}
