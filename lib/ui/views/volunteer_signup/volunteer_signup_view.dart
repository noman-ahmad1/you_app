import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/widgets.dart';

import 'volunteer_signup_viewmodel.dart';

class VolunteerSignupView extends StackedView<VolunteerSignupViewModel> {
  const VolunteerSignupView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    VolunteerSignupViewModel viewModel,
    Widget? child,
  ) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
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
                      'Become a Volunteer Listener',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.crimsonPro(
                          fontSize: 29,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary),
                    ),
                    Text(
                      'Join our community of psychology students helping people with emotional support.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.crimsonPro(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryVeryDark),
                    ),
                    Column(
                      children: [
                        // Space.verticalSpaceTiny(context),
                        // // SizedBox(height: screenSize.height * 0.04),
                        // CustomTextField(
                        //   controller: emailController,
                        //   labelText: 'Full Name',
                        //   keyboardType: TextInputType.name,
                        // ),
                        Space.verticalSpaceTiny(context),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: emailController,
                                labelText: 'Email Address',
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                            SizedBox(
                              width: screenWidth * 0.005,
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(
                                    AppColors.secondary),
                              ),
                              child: Text(
                                'Verify',
                                style: GoogleFonts.crimsonPro(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.background),
                              ),
                            )
                          ],
                        ),
                        Space.verticalSpaceVTiny(context),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: emailController,
                                labelText: 'Mobile Number',
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            SizedBox(
                              width: screenWidth * 0.005,
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(
                                    AppColors.secondary),
                              ),
                              child: Text(
                                'Verify',
                                style: GoogleFonts.crimsonPro(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.background),
                              ),
                            )
                          ],
                        ),
                        Space.verticalSpaceVTiny(context),
                        CustomTextField(
                          controller: passwordController,
                          labelText: 'Type a password',
                          obscureText: true,
                          keyboardType: TextInputType.visiblePassword,
                        ),
                        Space.verticalSpaceVTiny(context),
                        CustomTextField(
                          controller: passwordController,
                          labelText: 'Confirm password',
                          obscureText: true,
                          keyboardType: TextInputType.visiblePassword,
                        ),
                        SizedBox(height: screenSize.height * 0.045),
                        CustomButton(
                            text: 'Sign Up',
                            onPressed: () {
                              viewModel.navigateToVolunteerSignupInfo();
                            }),
                        Space.verticalSpaceTiny(context),
                        InkWell(
                          splashColor: AppColors.peachDark,
                          onTap: () {},
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
  VolunteerSignupViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      VolunteerSignupViewModel();
}
