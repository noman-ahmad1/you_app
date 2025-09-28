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
                      Space.verticalSpaceTiny(context),
                      Space.verticalSpaceVTiny(context),
                      Image.asset(
                        AppConstants.logo,
                        height: screenSize.height * 0.25,
                        width: screenSize.width * 0.5,
                        fit: BoxFit.cover,
                      ),
                      Space.verticalSpaceSmall(context),
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all(AppColors.primary),
                          padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(
                                  vertical: 25, horizontal: 65)),
                          shape: WidgetStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: const BorderSide(
                              color: AppColors.secondary,
                              width: 2,
                            ),
                          )),
                        ),
                        onPressed: () {
                          viewModel.navigateToLoginView();
                        },
                        child: const Text(
                          'SIGN IN',
                          style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w900,
                              fontSize: 18),
                        ),
                      ),
                      Space.verticalSpaceTiny(context),
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all(AppColors.primary),
                          padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(
                                  vertical: 25, horizontal: 62)),
                          shape: WidgetStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: const BorderSide(
                              color: AppColors.secondary,
                              width: 2,
                            ),
                          )),
                        ),
                        onPressed: () {
                          viewModel.navigateToSignupView();
                        },
                        child: const Text(
                          'SIGN UP',
                          style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w900,
                              fontSize: 18),
                        ),
                      ),
                      Space.verticalSpaceTiny(context),
                      InkWell(
                        onTap: () {
                          viewModel.navigateToVolunteerSignup();
                        },
                        child: Text(
                          'Sign Up | Login as Volunteer',
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
