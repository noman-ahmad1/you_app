import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/widgets.dart';

import 'user_info_viewmodel.dart';

class UserInfoView extends StackedView<UserInfoViewModel> {
  const UserInfoView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    UserInfoViewModel viewModel,
    Widget? child,
  ) {
    final emailController = TextEditingController();
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
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                  minHeight: screenSize.height
                ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Space.verticalSpaceSmall(context),
                        Space.verticalSpaceTiny(context),
                        Text(
                            'Tell us a bit more about you',
                            style: GoogleFonts.crimsonPro(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryVeryDark),
                          ),
                          Text(
                            'Let\'s personalize your journey',
                            style: GoogleFonts.crimsonPro(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary),
                          ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Space.verticalSpaceTiny(context),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: screenSize.width* 0.05, vertical: screenSize.height * 0.005),
                              child: Text(
                                  'Choose your unique username',
                                  style: GoogleFonts.crimsonPro(
                                      color: AppColors.primaryVeryDark, fontSize: 18),
                                ),
                            ),
                            CustomTextField(
                              controller: emailController,
                              labelText: '@ your_username',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            Space.verticalSpaceVTiny(context),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: screenSize.width* 0.05, vertical: screenSize.height * 0.005),
                              child: Text(
                                  'When\'s your birthday?',
                                  style: GoogleFonts.crimsonPro(
                                      color: AppColors.primaryVeryDark, fontSize: 18),
                                ),
                            ),
                            CustomTextField(
                              controller: emailController,
                              labelText: 'DD MM YYYY',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            Space.verticalSpaceVTiny(context),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: screenSize.width* 0.05, vertical: screenSize.height * 0.005),
                              child: Text(
                                  'How do you identify your gender?',
                                  style: GoogleFonts.crimsonPro(
                                      color: AppColors.primaryVeryDark, fontSize: 18),
                                ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(AppColors.primaryVeryDark),
                                padding: WidgetStateProperty.all(EdgeInsets.symmetric(
                                  vertical:
                                      screenSize.height * 0.022,
                                  horizontal:
                                      screenSize.width* 0.08,
                                )),
                                shape: WidgetStateProperty.all(RoundedRectangleBorder(
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(33),
                                )),
                                elevation: WidgetStateProperty.all(0),
                                ),
                              onPressed: (){},
                              child: const Text('  Male  ',
                              style: TextStyle(
                                fontSize: 16
                              ),
                              )),
                              Space.horizontalSpaceVTiny(context),
                              ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(AppColors.primaryVeryDark),
                                padding: WidgetStateProperty.all(EdgeInsets.symmetric(
                                  vertical:
                                      screenSize.height * 0.022,
                                  horizontal:
                                      screenSize.width* 0.08,
                                )),
                                shape: WidgetStateProperty.all(RoundedRectangleBorder(
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(33),
                                )),
                                elevation: WidgetStateProperty.all(0),
                                ),
                              onPressed: (){},
                              child: const Text('Female',
                              style: TextStyle(
                                fontSize: 16
                              ),
                              )),
                              Space.horizontalSpaceVTiny(context),
                              ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(AppColors.primaryVeryDark),
                                padding: WidgetStateProperty.all(EdgeInsets.symmetric(
                                  vertical:
                                      screenSize.height * 0.022,
                                  horizontal:
                                      screenSize.width* 0.08,
                                )) ,
                                shape: WidgetStateProperty.all(RoundedRectangleBorder(
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(33),
                                )),
                                elevation: WidgetStateProperty.all(0),
                                ),
                              onPressed: (){},
                              child: const Text(' Other ',
                              style: TextStyle(
                                fontSize: 16
                              ),
                              )),
                              ],
                            ),
                          ],
                        ),
                        Space.verticalSpaceTiny(context),
                        Space.verticalSpaceTiny(context),
                              Text(
                                'This would help us understand your journey better',
                                style: GoogleFonts.crimsonPro(
                                    color: AppColors.background,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700
                                    ),
                              ),
                      ],
                    ),
                    Container(
                      height: screenSize.height * 0.33,
                      child: Image.asset('assets/images/1.png')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  UserInfoViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      UserInfoViewModel();
}
