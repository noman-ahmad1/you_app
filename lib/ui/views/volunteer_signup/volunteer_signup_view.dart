import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/widgets.dart';
import 'package:you_app/app/app.locator.dart'; // Import locator

import 'volunteer_signup_viewmodel.dart';

class VolunteerSignupView extends StackedView<VolunteerSignupViewModel> {
  const VolunteerSignupView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    VolunteerSignupViewModel viewModel,
    Widget? child,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = MediaQuery.of(context).size.width;

    // UI state derived from ViewModel
    final isPhoneVerified = viewModel.isPhoneVerified;
    final phoneButtonText = isPhoneVerified ? 'Verified' : 'Verify';
    final phoneButtonColor = isPhoneVerified
        ? AppColors.pink
        : AppColors.secondary; // Changed to success for better visual cue

    // Determine if the verify button should be active
    final bool isVerifyButtonActive = !isPhoneVerified && !viewModel.isBusy;

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
                constraints: BoxConstraints(
                    minHeight:
                        screenSize.height - MediaQuery.of(context).padding.top),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Space.verticalSpaceSmall(context),
                    Space.verticalSpaceTiny(context),
                    Text(
                      'Become a Volunteer Listener',
                      textAlign: TextAlign.start,
                      style: GoogleFonts.crimsonPro(
                          fontSize: 29,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary),
                    ),
                    Text(
                      'Join our community of psychology students helping people with emotional support.',
                      textAlign: TextAlign.start,
                      style: GoogleFonts.crimsonPro(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryVeryDark),
                    ),
                    Space.verticalSpaceSmall(context),
                    Column(
                      children: [
                        // Phone Number Field with Verify Button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: PhoneNumberField(
                                controller: viewModel.phoneNumberController,
                                labelText: 'Mobile Number',
                                hintText: '300 123 4567',
                                initialDialCode: '+92',
                                onCountryCodeChanged: (dialCode) {
                                  // Removed redundant notifyListeners() to prevent jank
                                  viewModel.setDialCode(dialCode);
                                },
                                onChanged: (fullNumber) {
                                  // Removed redundant notifyListeners() to prevent jank
                                },
                                validator: (value) {
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(
                              width: screenWidth * 0.015, // Adjusted spacing
                            ),
                            SizedBox(
                              height: 54, // Match CustomTextField height
                              child: ElevatedButton(
                                // FIX: Correctly call the method or return null
                                onPressed: isVerifyButtonActive
                                    ? viewModel.sendVerificationCode
                                    : null,
                                style: ButtonStyle(
                                  backgroundColor:
                                      WidgetStateProperty.all(phoneButtonColor),
                                  shape: WidgetStateProperty.all<
                                      RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(27.0),
                                    ),
                                  ),
                                  padding: WidgetStateProperty.all(
                                      const EdgeInsets.symmetric(
                                          horizontal: 16)),
                                ),
                                child: viewModel.isBusy &&
                                        !isPhoneVerified // Only show busy state for the verification button itself
                                    ? const SizedBox(
                                        width: 15,
                                        height: 15,
                                        child: CircularProgressIndicator(
                                          color: AppColors.secondary,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        phoneButtonText,
                                        style: GoogleFonts.crimsonPro(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.background),
                                      ),
                              ),
                            )
                          ],
                        ),
                        Space.verticalSpaceVTiny(context),

                        // Email, Password Fields
                        CustomTextField(
                          controller: viewModel.emailController,
                          labelText: 'Email Address',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        Space.verticalSpaceVTiny(context),
                        CustomTextField(
                          controller: viewModel.passwordController,
                          labelText: 'Type a password',
                          obscureText: true,
                          keyboardType: TextInputType.visiblePassword,
                        ),
                        Space.verticalSpaceVTiny(context),
                        CustomTextField(
                          controller: viewModel.confirmPasswordController,
                          labelText: 'Confirm password',
                          obscureText: true,
                          keyboardType: TextInputType.visiblePassword,
                        ),
                        SizedBox(height: screenSize.height * 0.025),

                        // Error Display
                        if (viewModel.validationError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Text(
                              viewModel.validationError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),

                        SizedBox(height: screenSize.height * 0.02),

                        // Sign Up Button
                        CustomButton(
                          text: viewModel.isBusy ? 'Processing...' : 'Sign Up',
                          onPressed: viewModel.isBusy
                              ? null
                              : viewModel
                                  .signUpVolunteer, // Call the final signup method
                        ),

                        Space.verticalSpaceTiny(context),

                        // Login Link
                        InkWell(
                          splashColor: AppColors.peachDark,
                          onTap: viewModel.navigateToVolunteerLogin,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.crimsonPro(
                                    color: AppColors.background, fontSize: 15),
                                children: <TextSpan>[
                                  const TextSpan(
                                      text: 'Already have an account?'),
                                  TextSpan(
                                    text: ' Login',
                                    style: GoogleFonts.crimsonPro(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.background),
                                  ),
                                ],
                              ),
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
      locator<VolunteerSignupViewModel>();
}
