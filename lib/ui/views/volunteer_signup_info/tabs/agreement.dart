import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/views/volunteer_signup_info/volunteer_signup_info_viewmodel.dart';

class AgreementInfoView extends StackedView<VolunteerSignupInfoViewModel> {
  const AgreementInfoView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    VolunteerSignupInfoViewModel viewModel,
    Widget? child,
  ) {
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

  @override
  VolunteerSignupInfoViewModel viewModelBuilder(BuildContext context) =>
      VolunteerSignupInfoViewModel();
}
