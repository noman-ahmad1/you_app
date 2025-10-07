import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/widgets.dart';

import 'volunteer_reset_password_viewmodel.dart';

class VolunteerResetPasswordView
    extends StackedView<VolunteerResetPasswordViewModel> {
  // Added optional oobCode parameter for the new password phase
  final String? oobCode;
  const VolunteerResetPasswordView({Key? key, this.oobCode}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    VolunteerResetPasswordViewModel viewModel,
    Widget? child,
  ) {
    // Placeholder for oobCode used in case of testing the set password flow
    const String PLACEHOLDER_OOB_CODE = 'VOLUNTEER_OOB_CODE_HERE';
    final bool isInResetMode = oobCode != null;

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
                child: isInResetMode
                    ? _SetNewPasswordForm(
                        viewModel: viewModel,
                        screenSize: screenSize,
                        oobCode:
                            oobCode!, // oobCode is guaranteed to be non-null here
                        placeholderOobCode: PLACEHOLDER_OOB_CODE,
                      )
                    : viewModel.isEmailSent
                        ? _EmailConfirmationState(
                            viewModel: viewModel,
                            screenSize: screenSize,
                          )
                        : _ForgotPasswordForm(
                            viewModel: viewModel,
                            screenSize: screenSize,
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  VolunteerResetPasswordViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      VolunteerResetPasswordViewModel();
}

// --- WIDGETS FOR DIFFERENT STATES ---

// PHASE 1: Initial Forgot Password Form (Email Input)
class _ForgotPasswordForm extends StatelessWidget {
  final VolunteerResetPasswordViewModel viewModel;
  final Size screenSize;
  const _ForgotPasswordForm({
    required this.viewModel,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Space.verticalSpaceSmall(context),
        Space.verticalSpaceTiny(context),
        Text(
          'Volunteer Forgot Password',
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
            // Bind to Email Controller from ViewModel
            CustomTextField(
              controller: viewModel.emailController,
              labelText: 'Email Address',
              keyboardType: TextInputType.emailAddress,
            ),
            Space.verticalSpaceVTiny(context),
            SizedBox(height: screenSize.height * 0.045),
            CustomButton(
              text: 'Send Email Link',
              onPressed: viewModel.isBusy
                  ? null
                  : () => viewModel
                      .sendPasswordResetLink(viewModel.emailController.text),
            ),
            Space.verticalSpaceLarge(context),
            _buildLoginPrompt(viewModel),
          ],
        ),
      ],
    );
  }
}

// PHASE 1a: Email Sent Confirmation State (Confirmation Text + Resend Button)
class _EmailConfirmationState extends StatelessWidget {
  final VolunteerResetPasswordViewModel viewModel;
  final Size screenSize;
  const _EmailConfirmationState({
    required this.viewModel,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Space.verticalSpaceSmall(context),
        Space.verticalSpaceTiny(context),
        Text(
          'Email Sent!',
          style: GoogleFonts.crimsonPro(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppColors.secondary),
        ),
        Space.verticalSpaceVTiny(context),
        Text(
          textAlign: TextAlign.center,
          'A password reset link has been successfully sent to:\n${viewModel.sentEmail ?? 'your email address'}\n\nFollow the link in the email to reset your password.',
          style: GoogleFonts.crimsonPro(
              color: AppColors.primaryVeryDark,
              fontSize: 15,
              fontWeight: FontWeight.w600),
        ),
        Space.verticalSpaceMedium(context),
        CustomButton(
          text: viewModel.isBusy ? 'Resending...' : 'Resend Email',
          onPressed: viewModel.isBusy ? null : viewModel.resendEmail,
        ),
        Space.verticalSpaceLarge(context),
        _buildLoginPrompt(viewModel),
      ],
    );
  }
}

// PHASE 2: Set New Password Form (App opened via oobCode deep link)
class _SetNewPasswordForm extends StatelessWidget {
  final VolunteerResetPasswordViewModel viewModel;
  final Size screenSize;
  final String oobCode;
  final String placeholderOobCode;

  const _SetNewPasswordForm({
    required this.viewModel,
    required this.screenSize,
    required this.oobCode,
    required this.placeholderOobCode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Text(
          oobCode == placeholderOobCode
              ? 'DEBUG MODE: Placeholder code in use.'
              : 'Please enter and confirm your new volunteer password.',
          style: GoogleFonts.crimsonPro(
              color: AppColors.primaryVeryDark, fontSize: 15),
        ),
        Column(
          children: [
            Space.verticalSpaceVTiny(context),
            // Bind to New Password Controller
            CustomTextField(
              controller: viewModel.newPasswordController,
              labelText: 'Type a new password',
              obscureText: true,
            ),
            Space.verticalSpaceVTiny(context),
            // Bind to Confirm Password Controller
            CustomTextField(
              controller: viewModel.confirmPasswordController,
              labelText: 'Confirm new password',
              obscureText: true,
            ),
            SizedBox(height: screenSize.height * 0.045),
            CustomButton(
              text: 'Reset Password',
              // Hook up the logic for resetting the password
              onPressed: viewModel.isBusy
                  ? null
                  : () => viewModel.resetPassword(
                        oobCode: oobCode,
                        newPassword: viewModel.newPasswordController.text,
                        confirmPassword:
                            viewModel.confirmPasswordController.text,
                      ),
            ),
            Space.verticalSpaceLarge(context),
            _buildLoginPrompt(viewModel),
          ],
        ),
      ],
    );
  }
}

// Shared Login Prompt
Widget _buildLoginPrompt(VolunteerResetPasswordViewModel viewModel) {
  return InkWell(
    splashColor: AppColors.peachDark,
    onTap: viewModel.navigateToVolunteerLogin,
    child: RichText(
      text: TextSpan(
        style:
            GoogleFonts.crimsonPro(color: AppColors.background, fontSize: 15),
        children: <TextSpan>[
          const TextSpan(text: 'Remember your password?'),
          TextSpan(
            text: ' Login Now',
            style: GoogleFonts.crimsonPro(
                fontWeight: FontWeight.bold, color: AppColors.background),
          ),
        ],
      ),
    ),
  );
}
