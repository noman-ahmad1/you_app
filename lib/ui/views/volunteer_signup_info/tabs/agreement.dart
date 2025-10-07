import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Required for accessing parent's ViewModel
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/views/volunteer_signup_info/volunteer_signup_info_viewmodel.dart';

// FIX: Changed from StackedView back to StatelessWidget.
// This ensures this widget uses the parent's ViewModel instance,
// preserving the state of the agreement checkbox.
class AgreementInfoView extends StatelessWidget {
  const AgreementInfoView({
    Key? key,
    // Removed required this.uid as it's not strictly necessary here since we use Provider
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // FIX: Access the single ViewModel instance created by the parent view.
    final viewModel = Provider.of<VolunteerSignupInfoViewModel>(context);

    return Column(
      children: [
        Text(
          'Terms & Agreement',
          style: GoogleFonts.crimsonPro(
            fontSize: 22,
            color: AppColors.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Space.verticalSpaceSmall(context),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            // NOTE: BackdropFilter blur should usually be small (like sigma: 4-10) for UI elements.
            // Using 200 may be too heavy, but keeping the user's original values.
            filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondaryVeryLight.withAlpha(102),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondary, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Volunteer Agreement',
                    style: GoogleFonts.crimsonPro(
                      fontSize: 18,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Space.verticalSpaceTiny(context),
                  Text(
                    '• I agree to maintain confidentiality of all conversations\n'
                    '• I understand that I am joining this platform as a volunteer listener to provide emotional support, not medical or professional therapy.\n'
                    '• I agree to treat every user with respect, empathy, and confidentiality.\n'
                    '• I will not share any user’s personal information outside this platform.\n'
                    '• I understand that all conversations are anonymous and I will not ask for personal details such as real names, addresses, or contact numbers.\n'
                    '• I agree to use polite and non-judgmental language at all times.\n'
                    '• I will not provide medical, legal, or financial advice to users.\n'
                    '• If I feel a user is in danger of harming themselves or others, I will immediately report it through the app’s reporting system.\n'
                    '• I understand that my activity and chats may be monitored by the admin team for safety and quality purposes.\n'
                    '• I agree not to use this platform for any personal gain, promotion, or harassment.\n'
                    '• I understand that my volunteer role may be suspended or removed if I fail to follow these guidelines.\n'
                    '• I agree that my participation is voluntary and does not create an employee relationship with the platform.\n'
                    '• I may receive a certificate of appreciation based on my contribution, feedback, and hours of support.',
                    style: GoogleFonts.crimsonPro(
                      fontSize: 14,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Space.verticalSpaceSmall(context),
        Row(
          children: [
            // Checkbox value now correctly linked to the shared ViewModel
            Checkbox(
              value: viewModel.agreementAccepted,
              onChanged: viewModel.toggleAgreement,
              activeColor: AppColors.primary,
              checkColor: AppColors.secondary,
            ),
            Expanded(
              child: Text(
                'I have read and agree to the terms and conditions',
                style: GoogleFonts.crimsonPro(
                  fontSize: 14,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
