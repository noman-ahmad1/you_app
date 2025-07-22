import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_theme.dart';
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
              AppColors.peach,
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
                  verticalSpaceLarge,
                  verticalSpaceLarge,
                  Column(
                    children: [
                      const Text(
                        'Welcome to YOU',
                        style: TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondary),
                      ),
                      verticalSpaceLarge,
                      Image.asset(
                        'assets/images/You.png',
                        height: screenSize.height * 0.25,
                        width: screenSize.width * 0.5,
                        fit: BoxFit.cover,
                      ),
                      verticalSpaceLarge,
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
                      verticalSpaceSmall,
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
                        onPressed: () {},
                        child: const Text(
                          'SIGN UP',
                          style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w900,
                              fontSize: 18),
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
