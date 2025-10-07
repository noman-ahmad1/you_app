import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/widgets.dart';
import 'package:you_app/ui/views/volunteer_signup/volunteer_signup_viewmodel.dart';

class VolunteerOtpView extends StackedView<VolunteerSignupViewModel> {
  const VolunteerOtpView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    VolunteerSignupViewModel viewModel,
    Widget? child,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;

    // Callback to navigate back on success
    void onVerificationSuccess() {
      // After successfully verifying the phone number, pop the OTP screen
      // to return to the VolunteerSignupView where the 'Verified' status will show.
      locator<NavigationService>().back();
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          // Matching the gradient from the sign-up screen
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
                        screenHeight - MediaQuery.of(context).padding.top),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Verify Phone Number',
                      textAlign: TextAlign.center, // Ensure title is centered
                      style: GoogleFonts.crimsonPro(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary),
                    ),
                    Space.verticalSpaceSmall(context),

                    Text(
                      'Enter 6-Digit Code',
                      textAlign: TextAlign.center, // Ensure title is centered
                      style: GoogleFonts.crimsonPro(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary),
                    ),
                    Space.verticalSpaceTiny(context),
                    Text(
                      'We have sent a code to ${viewModel.pendingPhoneNumber ?? 'your number'}.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.crimsonPro(
                          fontSize: 16, color: AppColors.primaryVeryDark),
                    ),
                    Space.verticalSpaceSmall(context),

                    // OTP Input Field
                    CustomOtpField(
                      controller: viewModel.smsCodeController,
                      onCompleted: (String value) {
                        viewModel.smsCodeController.text = value;
                        // Optionally call verification immediately on completion
                        // viewModel.verifySmsCode(onVerificationSuccess: onVerificationSuccess);
                      },
                      autoFocus: true,
                    ),
                    Space.verticalSpaceSmall(context),

                    // Error message display
                    if (viewModel.validationError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Text(
                          viewModel.validationError!,
                          textAlign: TextAlign.center, // Center the error text
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 14),
                        ),
                      ),

                    // Verify Button
                    CustomButton(
                        text: viewModel.isBusy ? 'Verifying...' : 'Verify Code',
                        onPressed: viewModel.isBusy
                            ? null
                            : () => viewModel.verifySmsCode(
                                onVerificationSuccess: onVerificationSuccess)),

                    Space.verticalSpaceTiny(context),

                    // Resend Link
                    TextButton(
                      // Disable if busy or already verified
                      onPressed: viewModel.isBusy || viewModel.isPhoneVerified
                          ? null
                          : viewModel.resendCode,
                      child: Text(
                        viewModel.isBusy ? 'Sending...' : 'Resend Code',
                        style: GoogleFonts.crimsonPro(
                          color: AppColors.background,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
      // Crucial: Use the existing locator to ensure the same instance is used
      locator<VolunteerSignupViewModel>();

  // Use a non-reactive listener to keep the same ViewModel instance alive
  @override
  bool get disposeViewModel => false;
}
