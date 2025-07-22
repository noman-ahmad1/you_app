import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/ui_helpers.dart';

import 'login_viewmodel.dart';

class LoginView extends StackedView<LoginViewModel> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    LoginViewModel viewModel,
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
                        'We\'re glad to see you',
                        style: TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondary),
                      ),
                      TextField(
                        decoration: InputDecoration(
                          fillColor: AppColors.primaryLight,
                          filled: true,
                          labelText: 'Email Address',
                          labelStyle:
                              const TextStyle(color: AppColors.secondaryLight),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(27),
                            borderSide: const BorderSide(
                              color: AppColors.primaryDark,
                              width: 2.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(27),
                            borderSide: const BorderSide(
                              color: AppColors.primaryVeryDark,
                              width: 2.0,
                            ),
                          ),
                          border: OutlineInputBorder(
                            // Fallback border
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                      ),
                      TextField(
                        decoration: InputDecoration(
                          fillColor: AppColors.primaryLight,
                          filled: true,
                          labelText: 'Type your password',
                          labelStyle:
                              const TextStyle(color: AppColors.secondaryLight),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(27),
                            borderSide: const BorderSide(
                              color: AppColors.primaryDark,
                              width: 2.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(27),
                            borderSide: const BorderSide(
                              color: AppColors.primaryVeryDark,
                              width: 2.0,
                            ),
                          ),
                          border: OutlineInputBorder(
                            // Fallback border
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                      ),
                      verticalSpaceMedium,
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
                        onPressed: () {},
                        child: const Text(
                          'SIGN IN',
                          style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w900,
                              fontSize: 18),
                        ),
                      ),
                      verticalSpaceSmall,
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
  LoginViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      LoginViewModel();
}
