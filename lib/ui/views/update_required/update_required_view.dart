import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/services/app_version_service.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/widgets.dart';

import 'update_required_viewmodel.dart';

/// Shown instead of the app when this build is below the configured minimum.
/// There is deliberately no way past it except updating.
class UpdateRequiredView extends StackedView<UpdateRequiredViewModel> {
  final UpdateRequirement requirement;

  const UpdateRequiredView({super.key, required this.requirement});

  @override
  Widget builder(
    BuildContext context,
    UpdateRequiredViewModel viewModel,
    Widget? child,
  ) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      size: 72,
                      color: AppColors.secondary,
                    ),
                  ),
                  Space.verticalSpaceSmall(context),
                  Text(
                    'Time for an update',
                    style: GoogleFonts.crimsonPro(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Space.verticalSpaceTiny(context),
                  Text(
                    viewModel.message,
                    style: GoogleFonts.crimsonPro(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Space.verticalSpaceSmall(context),
                  if (viewModel.canOpenStore)
                    CustomButton(
                      text: 'Update now',
                      onPressed: viewModel.openStore,
                    )
                  else
                    Text(
                      'Please update You from the App Store.',
                      style: GoogleFonts.crimsonPro(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  UpdateRequiredViewModel viewModelBuilder(BuildContext context) =>
      UpdateRequiredViewModel(requirement);
}
