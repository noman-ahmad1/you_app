import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/widgets.dart';

import 'user_info_viewmodel.dart';

class UserInfoView extends StackedView<UserInfoViewModel> {
  const UserInfoView({
    Key? key,
    required this.uid,
  }) : super(key: key);

  final String uid;

  @override
  Widget builder(
    BuildContext context,
    UserInfoViewModel viewModel,
    Widget? child,
  ) {
    final emailController = TextEditingController();
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
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenSize.height),
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
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenSize.width * 0.05,
                                  vertical: screenSize.height * 0.005),
                              child: Text(
                                'Choose your unique username',
                                style: GoogleFonts.crimsonPro(
                                    color: AppColors.primaryVeryDark,
                                    fontSize: 18),
                              ),
                            ),
                            CustomTextField(
                              controller: viewModel.userNameController,
                              labelText: '@ your_username',
                              keyboardType: TextInputType.name,
                            ),
                            Space.verticalSpaceVTiny(context),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenSize.width * 0.05,
                                  vertical: screenSize.height * 0.005),
                              child: Text(
                                'When\'s your birthday?',
                                style: GoogleFonts.crimsonPro(
                                    color: AppColors.primaryVeryDark,
                                    fontSize: 18),
                              ),
                            ),
                            InkWell(
                              onTap: () => viewModel.selectDate(context),
                              child: AbsorbPointer(
                                child: CustomTextField(
                                  controller: viewModel.dateOfBirthController,
                                  labelText: 'Date of Birth',
                                  keyboardType: TextInputType.datetime,
                                  suffixIcon: Icon(
                                    Icons.calendar_today,
                                    color: AppColors.primaryVeryDark,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            Space.verticalSpaceVTiny(context),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenSize.width * 0.05,
                                  vertical: screenSize.height * 0.005),
                              child: Text(
                                'Specify your Gender',
                                style: GoogleFonts.crimsonPro(
                                    color: AppColors.primaryVeryDark,
                                    fontSize: 18),
                              ),
                            ),
                            DropdownButtonFormField<String>(
                              initialValue: viewModel
                                  .selectedGender, // Use value instead of initialValue
                              decoration: InputDecoration(
                                fillColor: AppColors.background,
                                filled: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.0177,
                                  horizontal: screenWidth * 0.07,
                                ),
                                labelStyle: GoogleFonts.crimsonPro(
                                  color: AppColors.secondary,
                                ),
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
                                    color: AppColors.primaryDark,
                                    width: 2.0,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(27),
                                ),
                              ),
                              items: viewModel.genders.map((String gender) {
                                return DropdownMenuItem<String>(
                                  value: gender,
                                  child: Text(
                                    gender,
                                    style: GoogleFonts.crimsonPro(
                                      color: AppColors.secondaryLight,
                                      fontSize: 16,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: viewModel.setGender,
                              style: GoogleFonts.crimsonPro(
                                color: AppColors.secondaryLight,
                                fontSize: 16,
                              ),
                              dropdownColor: AppColors.background,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.primaryDark,
                                size: 24,
                              ),
                              iconSize: 24,
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              menuMaxHeight: 200,
                              isExpanded: true,
                              hint: Text(
                                'Select Gender',
                                style: GoogleFonts.crimsonPro(
                                  color: AppColors.secondaryLight,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Space.verticalSpaceTiny(context),
                        Text(
                          'This would help us understand your journey better',
                          style: GoogleFonts.crimsonPro(
                              color: AppColors.background,
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
                        Space.verticalSpaceTiny(context),
                        CustomButton(
                            text: viewModel.isBusy
                                ? 'Signing Up...'
                                : 'Complete Sign Up',
                            onPressed: () {
                              viewModel.isBusy
                                  ? null // Disable button when busy
                                  : viewModel.completeSignUp();
                            }),
                        Space.verticalSpaceTiny(context),
                      ],
                    ),
                    Container(
                        height: screenSize.height * 0.33,
                        child: Image.asset(AppConstants.register)),
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
  UserInfoViewModel viewModelBuilder(BuildContext context) =>
      UserInfoViewModel(uid: uid);
}
