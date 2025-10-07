import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Required for accessing parent's ViewModel
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/widgets.dart';
import 'package:you_app/ui/views/volunteer_signup_info/volunteer_signup_info_viewmodel.dart';

// FIX: Changed from StackedView back to StatelessWidget.
// This ensures this widget uses the parent's ViewModel instance,
// preserving the state of the controllers.
class PersonalInfoView extends StatelessWidget {
  const PersonalInfoView({
    Key? key,
    // Removed required this.uid as it's not needed by a StatelessWidget that uses Provider
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // FIX: Access the single ViewModel instance created by the parent view.
    // This allows access to the shared controllers and state.
    final viewModel = Provider.of<VolunteerSignupInfoViewModel>(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        // --- 1. Profile Photo Upload ---
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
                  child: viewModel.selectedProfileImage != null
                      ? Image.file(
                          viewModel.selectedProfileImage!,
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

        // --- Form Fields ---
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
          value: viewModel.selectedGender, // Use value instead of initialValue
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
        Space.verticalSpaceVTiny(context),

        // --- 2. ID Card Photo Upload (Inline Logic) ---
        Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 5, 0),
          width: double.infinity,
          height: screenHeight * 0.06,
          decoration: BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(27),
            border: Border.all(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: viewModel.selectedIdCardImage != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ID card uploaded successfully.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.crimsonPro(
                          fontSize: 16,
                          color: AppColors.secondaryLight,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Container(
                        width: screenHeight * 0.05,
                        height: screenHeight * 0.05,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          border: Border.all(
                            color: AppColors.primaryDark,
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          onTap: () =>
                              viewModel.showIdCardImagePickerOptions(context),
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Image.asset(
                              AppConstants.done,
                              color: AppColors.background,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tap Camera icon to upload your ID.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.crimsonPro(
                          fontSize: 16,
                          color: AppColors.secondaryLight,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Container(
                        width: screenHeight * 0.05,
                        height: screenHeight * 0.05,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          border: Border.all(
                            color: AppColors.primaryDark,
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          onTap: () =>
                              viewModel.showIdCardImagePickerOptions(context),
                          child: Padding(
                            padding: const EdgeInsets.all(7.0),
                            child: Image.asset(
                              AppConstants.camera,
                              color: AppColors.background,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        Space.verticalSpaceSmall(context),
      ],
    );
  }
}
