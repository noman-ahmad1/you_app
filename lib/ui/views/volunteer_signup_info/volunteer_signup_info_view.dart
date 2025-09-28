import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/widgets.dart';
import 'package:you_app/ui/views/volunteer_signup_info/tabs/academic_info.dart';
import 'package:you_app/ui/views/volunteer_signup_info/tabs/agreement.dart';
import 'package:you_app/ui/views/volunteer_signup_info/tabs/personal_info.dart';

import 'volunteer_signup_info_viewmodel.dart';

class VolunteerSignupInfoView
    extends StackedView<VolunteerSignupInfoViewModel> {
  const VolunteerSignupInfoView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    VolunteerSignupInfoViewModel viewModel,
    Widget? child,
  ) {
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
          bottom: false,
          child: Stack(
            children: [
              // Content Area (Scrollable, full height)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Space.verticalSpaceSmall(context),
                        _buildProgressIndicator(viewModel, context),
                        Space.verticalSpaceTiny(context),
                        _buildCurrentPage(viewModel, context, screenSize),
                        Space.verticalSpaceLarge(context),
                        Space.verticalSpaceLarge(context),
                        Space.verticalSpaceLarge(context),
                        // Extra space so content doesn’t hide behind buttons
                      ],
                    ),
                  ),
                ),
              ),

              // Floating Navigation Buttons
              Positioned(
                bottom: 20,
                left: 25,
                right: 25,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!viewModel.isFirstPage)
                      _buildGlassButton(
                        onTap: viewModel.previousPage,
                        asset: AppConstants.back,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                      )
                    else
                      SizedBox(width: screenWidth * 0.15),
                    _buildGlassButton(
                      onTap: viewModel.isLastPage
                          ? () => viewModel.submitForm()
                          : viewModel.nextPage,
                      asset: AppConstants.next,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
      VolunteerSignupInfoViewModel viewModel, BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              width: 100,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index <= viewModel.currentPage
                    ? AppColors.primaryDark
                    : AppColors.background.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
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

  Widget _buildCurrentPage(VolunteerSignupInfoViewModel viewModel,
      BuildContext context, Size screenSize) {
    switch (viewModel.currentPage) {
      case 0:
        return PersonalInfoView(
          key: ValueKey('Personal'),
        );
      case 1:
        return AcademicInfoView(
          key: ValueKey('Academic'),
        );
      case 2:
        return AgreementInfoView(
          key: ValueKey('Agreement'),
        );
      default:
        return PersonalInfoView(
          key: ValueKey('Personal'),
        );
    }
  }

  Widget _buildGlassButton({
    required VoidCallback onTap,
    required String asset,
    required double screenWidth,
    required double screenHeight,
  }) {
    return GestureDetector(
      onTapDown: (_) => HapticFeedback.lightImpact(),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: screenWidth * 0.15,
        height: screenHeight * 0.067,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: LinearGradient(
            colors: [
              AppColors.background.withOpacity(0.4),
              AppColors.primaryDark.withOpacity(0.4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: AppColors.background.withOpacity(0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 5,
              spreadRadius: -3,
              offset: const Offset(-3, -3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Center(
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    colors: [
                      AppColors.background.withOpacity(0.9),
                      Colors.white.withOpacity(0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds);
                },
                blendMode: BlendMode.srcATop,
                child: Image.asset(
                  asset,
                  width: 26,
                  height: 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(
    VolunteerSignupInfoViewModel viewModel,
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    Widget buildGlassButton({
      required VoidCallback onTap,
      required String asset,
    }) {
      return GestureDetector(
        onTapDown: (_) => HapticFeedback.lightImpact(),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: screenWidth * 0.15,
          height: screenHeight * 0.067,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            gradient: LinearGradient(
              colors: [
                AppColors.background.withOpacity(0.4),
                AppColors.primaryDark.withOpacity(0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppColors.background.withOpacity(0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 5,
                spreadRadius: -3,
                offset: const Offset(-3, -3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Center(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      colors: [
                        AppColors.background.withOpacity(0.9),
                        Colors.white.withOpacity(0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcATop,
                  child: Image.asset(
                    asset,
                    width: 26,
                    height: 26,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button (visible except on first page)
        if (!viewModel.isFirstPage)
          buildGlassButton(
            onTap: viewModel.previousPage,
            asset: AppConstants.back,
          )
        else
          SizedBox(
            width: screenWidth * 0.15,
            height: screenHeight * 0.067,
          ),

        // Next/Submit Button
        buildGlassButton(
          onTap: viewModel.isLastPage
              ? () => viewModel.submitForm()
              : viewModel.nextPage,
          asset: viewModel.isLastPage ? AppConstants.next : AppConstants.next,
        ),
      ],
    );
  }

  // void _submitForm(VolunteerSignupInfoViewModel viewModel) {
  //   viewModel.navigateToVolunteerHome;
  //   // Handle form submission
  //   print('Form submitted!');
  //   // Add your form submission logic here
  // }

  @override
  VolunteerSignupInfoViewModel viewModelBuilder(BuildContext context) =>
      VolunteerSignupInfoViewModel();
}
