import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/widgets.dart';
import 'package:you_app/ui/views/volunteer_signup_info/volunteer_signup_info_viewmodel.dart';

class PersonalInfoView extends StackedView<VolunteerSignupInfoViewModel> {
  const PersonalInfoView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    VolunteerSignupInfoViewModel viewModel,
    Widget? child,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 3,
                  ),
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.peachDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ClipOval(
                  child: viewModel.selectedImage != null
                      ? Image.file(
                          viewModel.selectedImage!,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                        )
                      : Image.asset(AppConstants.person),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    border: Border.all(
                      color: AppColors.background,
                      width: 2,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      viewModel.showImagePickerOptions(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Image.asset(
                        AppConstants.camera,
                        color: AppColors.background,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Space.verticalSpaceTiny(context),
        Text(
          'Add Profile Photo',
          textAlign: TextAlign.center,
          style: GoogleFonts.crimsonPro(
            fontSize: 16,
            color: AppColors.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Space.verticalSpaceTiny(context),
        CustomTextField(
          controller: viewModel.firstNameController,
          labelText: 'First Name',
          keyboardType: TextInputType.name,
        ),
        Space.verticalSpaceVTiny(context),
        CustomTextField(
          controller: viewModel.secondNameController,
          labelText: 'Second Name',
          keyboardType: TextInputType.name,
        ),
        Space.verticalSpaceVTiny(context),
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

        // Gender Dropdown styled to match CustomTextField
        DropdownButtonFormField<String>(
          initialValue: viewModel.selectedGender,
          decoration: InputDecoration(
            fillColor: AppColors.background,
            filled: true,
            // labelText: 'Gender',
            contentPadding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.0177,
              horizontal: screenWidth * 0.07,
            ),
            labelStyle: GoogleFonts.crimsonPro(
              color: AppColors.secondary,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(27),
              borderSide: BorderSide(
                color: AppColors.primaryDark,
                width: 2.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(27),
              borderSide: BorderSide(
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
          icon: Icon(
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
    );
  }

  @override
  VolunteerSignupInfoViewModel viewModelBuilder(BuildContext context) =>
      VolunteerSignupInfoViewModel();
}
