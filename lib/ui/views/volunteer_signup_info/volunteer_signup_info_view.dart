import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
// Note: Assuming the class AcademicInfoView is exported from this path
import 'package:you_app/ui/views/volunteer_signup_info/tabs/academic_info.dart';
// Note: Assuming the class AgreementInfoView is exported from this path
import 'package:you_app/ui/views/volunteer_signup_info/tabs/agreement.dart';
// Note: Assuming the class PersonalInfoView is exported from this path
import 'package:you_app/ui/views/volunteer_signup_info/tabs/personal_info.dart';

import 'volunteer_signup_info_viewmodel.dart';

class VolunteerSignupInfoView
    extends StackedView<VolunteerSignupInfoViewModel> {
  const VolunteerSignupInfoView({
    super.key,
    required this.uid,
  });

  final String uid;

  @override
  Widget builder(
    BuildContext context,
    VolunteerSignupInfoViewModel viewModel,
    Widget? child,
  ) {
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
            child: Column(
              children: [
                Space.verticalSpaceSmall(context),
                _buildProgressIndicator(viewModel, context),
                Space.verticalSpaceTiny(context),
                // The step content + its nav buttons scroll together.
                Expanded(
                  child: _buildCurrentPage(viewModel, context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
      VolunteerSignupInfoViewModel viewModel, BuildContext context) {
    return Column(
      children: [
        // Flexible, not fixed-width: three 100dp bars plus margins needed
        // 374dp of screen, which overflowed every 360dp Android device.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index <= viewModel.currentPage
                        ? AppColors.primaryDark
                        : AppColors.background.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ),
        Space.verticalSpaceTiny(context),
        Text(
          'Step ${viewModel.currentPage + 1} of 3',
          style: GoogleFonts.crimsonPro(
            color: AppColors.secondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentPage(
      VolunteerSignupInfoViewModel viewModel, BuildContext context) {
    // State (controllers, selections) lives in the shared ViewModel, so we can
    // swap the step widget directly without losing any entered data.
    final Widget step;
    switch (viewModel.currentPage) {
      case 0:
        step = const PersonalInfoView();
        break;
      case 1:
        step = const AcademicInfoView();
        break;
      default:
        step = const AgreementInfoView();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          step,
          const SizedBox(height: 24),
          // In-flow navigation buttons (scroll with the content).
          _buildNavRow(viewModel),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNavRow(VolunteerSignupInfoViewModel viewModel) {
    final isLast = viewModel.isLastPage;
    return Row(
      children: [
        if (!viewModel.isFirstPage) ...[
          Expanded(
            child: _navButton(
              label: 'Back',
              icon: Icons.arrow_back_rounded,
              filled: false,
              onTap: viewModel.previousPage,
            ),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: _navButton(
            label: isLast ? 'Submit' : 'Next',
            icon: isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
            iconTrailing: true,
            filled: true,
            onTap: viewModel.isBusy
                ? null
                : (isLast ? viewModel.submitForm : viewModel.nextPage),
          ),
        ),
      ],
    );
  }

  Widget _navButton({
    required String label,
    required IconData icon,
    required bool filled,
    VoidCallback? onTap,
    bool iconTrailing = false,
  }) {
    final Color fg = filled ? Colors.white : AppColors.secondary;
    final iconWidget = Icon(icon, size: 18, color: fg);
    final textWidget = Flexible(
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.crimsonPro(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );

    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          color: filled ? null : AppColors.surface,
          gradient: filled
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.secondary, AppColors.secondaryLight],
                )
              : null,
          borderRadius: BorderRadius.circular(30),
          border: filled
              ? null
              : Border.all(
                  color: AppColors.secondary.withAlpha(80), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: filled
                  ? AppColors.secondary.withAlpha(90)
                  : AppColors.primaryVeryDark.withAlpha(35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!iconTrailing) ...[iconWidget, const SizedBox(width: 8)],
            textWidget,
            if (iconTrailing) ...[const SizedBox(width: 8), iconWidget],
          ],
        ),
      ),
    );
  }

  @override
  VolunteerSignupInfoViewModel viewModelBuilder(BuildContext context) =>
      VolunteerSignupInfoViewModel(uid: uid);
}
