import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/widgets.dart';
import 'package:you_app/ui/views/volunteer_signup_info/volunteer_signup_info_viewmodel.dart';

class AcademicInfoView extends StackedView<VolunteerSignupInfoViewModel> {
  const AcademicInfoView({Key? key}) : super(key: key);

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
        Text(
          'Academic Information',
          style: GoogleFonts.crimsonPro(
            fontSize: 22,
            color: AppColors.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Space.verticalSpaceSmall(context),
        DropdownButtonFormField<String>(
          initialValue: viewModel.selectedLevel,
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
            'Current Level of Study',
            style: GoogleFonts.crimsonPro(
              color: AppColors.secondaryLight,
              fontSize: 16,
            ),
          ),
        ),
        Space.verticalSpaceVTiny(context),
        CustomTextField(
          controller: viewModel.institutionController,
          labelText: 'Institution Name',
          keyboardType: TextInputType.text,
        ),
        Space.verticalSpaceVTiny(context),
        CustomTextField(
          controller: viewModel.graduationYearController,
          labelText: 'Graduation Year',
          keyboardType: TextInputType.number,
        ),
        Space.verticalSpaceVTiny(context),
        DropdownButtonFormField<String>(
          initialValue: viewModel.selectedCategory,
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
            'Specialization Category',
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
