import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/shared/widgets.dart';

import 'volunteer_edit_profile_viewmodel.dart';
import "package:you_app/ui/shared/custom_lottie_loader.dart";

class VolunteerEditProfileView
    extends StackedView<VolunteerEditProfileViewModel> {
  const VolunteerEditProfileView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    VolunteerEditProfileViewModel viewModel,
    Widget? child,
  ) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      // appBar: const TopBar(title: 'Edit Volunteer Profile'),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.background),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            TopBar(
              leadingIconAsset: AppConstants.back,
              title: 'Edit Profile',
              onLeadingPressed: () {
                Navigator.of(context).pop();
              },
            ),
            Expanded(
              child: viewModel.isBusy
                  ? const CustomLottieLoader(fullScreen: true)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Profile Picture Section
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primaryVeryDark,
                                      width: 3,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: viewModel.selectedProfileImage !=
                                            null
                                        ? Image.file(
                                            viewModel.selectedProfileImage!,
                                            fit: BoxFit.cover,
                                          )
                                        : (viewModel.currentProfileImageUrl !=
                                                    null &&
                                                viewModel
                                                    .currentProfileImageUrl!
                                                    .isNotEmpty
                                            ? Image.network(
                                                viewModel
                                                    .currentProfileImageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Image.asset(
                                                        viewModel.currentUser?.defaultAvatar ?? AppConstants.avatarBinary),
                                              )
                                            : Image.asset(viewModel.currentUser?.defaultAvatar ?? AppConstants.avatarBinary)),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => viewModel
                                        .showImagePickerOptions(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: AppColors.peach,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: AppColors.background,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Space.verticalSpaceTiny(context),

                          // Personal Info Section
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Personal Info',
                              style: GoogleFonts.crimsonPro(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                          Space.verticalSpaceVTiny(context),
                          CustomTextField(
                            controller: viewModel.firstNameController,
                            labelText: 'First Name',
                          ),
                          Space.verticalSpaceVTiny(context),
                          CustomTextField(
                            controller: viewModel.lastNameController,
                            labelText: 'Last Name',
                          ),
                          Space.verticalSpaceVTiny(context),
                          PhoneNumberField(
                            controller: viewModel.phoneController,
                            initialDialCode: '+92',
                            labelText: 'Phone Number',
                            hintText: 'Enter phone number',
                            onChanged: viewModel.setPhoneNumber,
                          ),
                          Space.verticalSpaceVTiny(context),
                          GestureDetector(
                            onTap: () => viewModel.selectDate(context),
                            child: AbsorbPointer(
                              child: CustomTextField(
                                controller: viewModel.dobController,
                                labelText: 'Date of Birth (DD/MM/YYYY)',
                                hintText: 'DD/MM/YYYY',
                                suffixIcon: const Icon(Icons.calendar_today,
                                    color: AppColors.primaryDark),
                              ),
                            ),
                          ),
                          Space.verticalSpaceVTiny(context),
                          _buildGenderDropdown(context, viewModel),

                          Space.verticalSpaceTiny(context),

                          // Academic Info Section
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Academic Info',
                              style: GoogleFonts.crimsonPro(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                          Space.verticalSpaceVTiny(context),
                          _buildLevelDropdown(context, viewModel),
                          Space.verticalSpaceVTiny(context),
                          CustomTextField(
                            controller: viewModel.institutionController,
                            labelText: 'Institution Name',
                          ),
                          Space.verticalSpaceVTiny(context),
                          CustomTextField(
                            controller: viewModel.graduationYearController,
                            labelText: 'Graduation Year',
                            keyboardType: TextInputType.number,
                          ),

                          Space.verticalSpaceTiny(context),

                          // Tags Section
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Specialties / Tags',
                              style: GoogleFonts.crimsonPro(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                          Space.verticalSpaceVTiny(context),
                          _buildTagSelector(viewModel),

                          Space.verticalSpaceTiny(context),
                          Space.verticalSpaceTiny(context),

                          CustomButton(
                            text: 'Save Changes',
                            onPressed: viewModel.saveProfile,
                          ),
                          Space.verticalSpaceSmall(context),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown(
      BuildContext context, VolunteerEditProfileViewModel viewModel) {
    return DropdownButtonFormField<String>(
      value: viewModel.selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender',
        labelStyle: const TextStyle(color: AppColors.secondaryLight),
        filled: true,
        fillColor: AppColors.background, // Kept solid as per original
        contentPadding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.0177,
          horizontal: MediaQuery.of(context).size.width * 0.07,
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
            color: AppColors.primaryVeryDark,
            width: 2.0,
          ),
        ),
      ),
      dropdownColor: AppColors.background,
      items: viewModel.genders.map((String gender) {
        return DropdownMenuItem<String>(
          value: gender,
          child: Text(
            gender,
            style: const TextStyle(color: AppColors.primaryVeryDark),
          ),
        );
      }).toList(),
      onChanged: viewModel.setGender,
    );
  }

  Widget _buildLevelDropdown(
      BuildContext context, VolunteerEditProfileViewModel viewModel) {
    return DropdownButtonFormField<String>(
      value: viewModel.selectedLevel,
      decoration: InputDecoration(
        labelText: 'Current Level of Study',
        labelStyle: const TextStyle(color: AppColors.secondaryLight),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.0177,
          horizontal: MediaQuery.of(context).size.width * 0.07,
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
            color: AppColors.primaryVeryDark,
            width: 2.0,
          ),
        ),
      ),
      dropdownColor: AppColors.background,
      items: viewModel.levels.map((String level) {
        return DropdownMenuItem<String>(
          value: level,
          child: Text(
            level,
            style: const TextStyle(color: AppColors.primaryVeryDark),
          ),
        );
      }).toList(),
      onChanged: viewModel.setLevel,
    );
  }

  Widget _buildTagSelector(VolunteerEditProfileViewModel viewModel) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: viewModel.categories.map((tag) {
        final isSelected = viewModel.selectedTags.contains(tag);
        return ChoiceChip(
          label: Text(tag),
          selected: isSelected,
          onSelected: (_) => viewModel.toggleTag(tag),
          selectedColor: AppColors.peach,
          backgroundColor: AppColors.primaryDark.withOpacity(0.5),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.background : AppColors.secondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  @override
  VolunteerEditProfileViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      VolunteerEditProfileViewModel();

  @override
  void onViewModelReady(VolunteerEditProfileViewModel viewModel) {
    viewModel.initialize();
    super.onViewModelReady(viewModel);
  }
}
