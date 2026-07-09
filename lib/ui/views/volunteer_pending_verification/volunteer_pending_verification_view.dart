import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/animation_decoder.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'volunteer_pending_verification_viewmodel.dart';
import "package:you_app/ui/shared/custom_lottie_loader.dart";
import 'package:you_app/ui/shared/verify_email_block.dart';

class VolunteerPendingVerificationView
    extends StackedView<VolunteerPendingVerificationViewModel> {
  const VolunteerPendingVerificationView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    VolunteerPendingVerificationViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.background),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Use a built-in icon or custom image, here using an icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Lottie.asset(
                    decoder: customDecoder,
                    AppConstants.pending2,
                    width: 200,
                    height: 200,
                  ),
                  // const Icon(
                  //   Icons.pending_actions_rounded,
                  //   size: 80,
                  //   color: AppColors.primary,
                  // ),
                ),
                Space.verticalSpaceSmall(context),
                Text(
                  'Application Under Review',
                  style: GoogleFonts.crimsonPro(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                Space.verticalSpaceTiny(context),
                Text(
                  'Thank you for signing up to volunteer! Our team is currently reviewing your profile and documents. You will automatically be redirected here once your application is approved.',
                  style: GoogleFonts.crimsonPro(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                Space.verticalSpaceSmall(context),
                // const CustomLottieLoader(
                //   width: 80,
                //   height: 80,
                //   loaderWidth: 80,
                //   loaderHeight: 80,
                // ),
                Space.verticalSpaceSmall(context),
                InkWell(
                  onTap: viewModel.logout,
                  child: Container(
                    height: 50,
                    width: 150,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background.withAlpha(150),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          AppConstants.logout,
                          color: AppColors.secondary,
                          // width: 20,
                        ),
                        Space.horizontalSpaceTiny(context),
                        Text(
                          'Logout',
                          style: GoogleFonts.crimsonPro(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
          ),
          // Non-dismissible verify block also persists on the pending-approval
          // screen until the volunteer verifies their email.
          const VerifyEmailBlock(source: 'volunteer_block'),
        ],
      ),
    );
  }

  @override
  VolunteerPendingVerificationViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      VolunteerPendingVerificationViewModel();
}
