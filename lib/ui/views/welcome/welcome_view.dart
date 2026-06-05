import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'welcome_viewmodel.dart';

class WelcomeView extends StackedView<WelcomeViewModel> {
  const WelcomeView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    WelcomeViewModel viewModel,
    Widget? child,
  ) {
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
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Space.verticalSpaceSmall(context),
                  Column(
                    children: [
                      Text(
                        'Welcome to YOU',
                        style: GoogleFonts.crimsonPro(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary),
                      ),
                      Space.verticalSpaceVTiny(context),
                      Text(
                        'Your safe space to land',
                        style: GoogleFonts.crimsonPro(
                            fontSize: 25,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondary),
                      ),
                      Space.verticalSpaceSmall(context),
                      Space.verticalSpaceVTiny(context),
                      Image.asset(
                        AppConstants.logo,
                        height: 200,
                        width: 200,
                        // height: screenSize.height * 0.23,
                        // width: screenSize.width * 0.5,
                        fit: BoxFit.cover,
                      ),
                      Space.verticalSpaceSmall(context),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.background.withAlpha(100), // Purple
                              AppColors.secondary, // Blue
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.all(2), // Border thickness
                        child: ElevatedButton(
                          style: ButtonStyle(
                            elevation: WidgetStateProperty.all(0),
                            backgroundColor: WidgetStateProperty.all(
                              AppColors.background.withAlpha(100),
                            ),
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 80,
                              ),
                            ),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          onPressed: () {
                            viewModel.navigateToLoginView();
                          },
                          child: const Text(
                            'SIGN IN',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                      Space.verticalSpaceTiny(context),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.background.withAlpha(100), // Purple
                              AppColors.secondary, // Blue
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.all(2), // Border thickness
                        child: ElevatedButton(
                          style: ButtonStyle(
                            elevation: WidgetStateProperty.all(0),
                            backgroundColor: WidgetStateProperty.all(
                              AppColors.background.withAlpha(100),
                            ),
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 80,
                              ),
                            ),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          onPressed: () {
                            viewModel.navigateToSignupView();
                          },
                          child: const Text(
                            'SIGN UP',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                      Space.verticalSpaceTiny(context),
                      InkWell(
                        onTap: () {
                          viewModel.navigateToVolunteerSignup();
                          // viewModel.navigateToVolunteerSignupInfo();
                        },
                        child: Text(
                          'Sign Up as Volunteer',
                          style: GoogleFonts.crimsonPro(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondaryVeryLight),
                        ),
                      ),
                    ],
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
  WelcomeViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      WelcomeViewModel();
}
