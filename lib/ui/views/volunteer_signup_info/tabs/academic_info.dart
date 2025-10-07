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
class AcademicInfoView extends StatelessWidget {
  const AcademicInfoView({
    Key? key,
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
        Text(
          'Academic Information',
          style: GoogleFonts.crimsonPro(
            fontSize: 22,
            color: AppColors.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Space.verticalSpaceSmall(context),

        // --- Current Level of Study Dropdown ---
        DropdownButtonFormField<String>(
          value: viewModel.selectedLevel, // Use value instead of initialValue
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
          items: viewModel.levels.map((String level) {
            return DropdownMenuItem<String>(
              value: level,
              child: Text(
                level,
                style: GoogleFonts.crimsonPro(
                  color: AppColors.secondaryLight,
                  fontSize: 16,
                ),
              ),
            );
          }).toList(),
          onChanged: viewModel.setLevel,
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
            'Current Level of Study',
            style: GoogleFonts.crimsonPro(
              color: AppColors.secondaryLight,
              fontSize: 16,
            ),
          ),
        ),
        Space.verticalSpaceVTiny(context),

        // --- Institution Name ---
        CustomTextField(
          controller: viewModel.institutionController,
          labelText: 'Institution Name',
          keyboardType: TextInputType.text,
        ),
        Space.verticalSpaceVTiny(context),

        // --- Graduation Year ---
        CustomTextField(
          controller: viewModel.graduationYearController,
          labelText: 'Graduation Year',
          keyboardType: TextInputType.number,
        ),
        Space.verticalSpaceVTiny(context),

        // --- Specialization Category Dropdown ---
        DropdownButtonFormField<String>(
          value:
              viewModel.selectedCategory, // Use value instead of initialValue
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
          items: viewModel.categories.map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(
                category,
                style: GoogleFonts.crimsonPro(
                  color: AppColors.secondaryLight,
                  fontSize: 16,
                ),
              ),
            );
          }).toList(),
          onChanged: viewModel.setCategory,
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
            'Specialization Category',
            style: GoogleFonts.crimsonPro(
              color: AppColors.secondaryLight,
              fontSize: 16,
            ),
          ),
        ),
        Space.verticalSpaceVTiny(context),

        // --- 2. Student Card Photo Upload (Inline Logic) ---
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
            child: viewModel.selectedStudentIdImage != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Student ID card uploaded successfully.',
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
                          onTap: () => viewModel
                              .showStudentIdImagePickerOptions(context),
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
                        'Tap Camera icon to upload Student ID.',
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
                          onTap: () => viewModel
                              .showStudentIdImagePickerOptions(context),
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
      ],
    );
  }
}
