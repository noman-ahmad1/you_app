import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/shared/widgets.dart';
import 'edit_profile_viewmodel.dart';

class EditProfileView extends StackedView<EditProfileViewModel> {
  const EditProfileView({super.key});

  @override
  void onViewModelReady(EditProfileViewModel viewModel) {
    viewModel.initialize();
    super.onViewModelReady(viewModel);
  }

  @override
  Widget builder(
    BuildContext context,
    EditProfileViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
              onLeadingPressed: viewModel.goBack,
              title: 'Edit Profile',
              iconColor: AppColors.primaryVeryDark,
              trailingActions: [
                if (viewModel.isBusy)
                  const Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CustomLottieLoader(
                        width: 20,
                        height: 20,
                        loaderWidth:
                            40, // Lottie loader might need to be slightly larger to look good within 20x20, or just 20x20.
                        loaderHeight: 40,
                      ),
                    ),
                  )
                else
                  TextButton(
                    onPressed: viewModel.saveProfile,
                    child: Text(
                      'Save',
                      style: GoogleFonts.crimsonPro(
                        color: AppColors.primaryVeryDark,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 15.0, vertical: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    // color: AppColors.background.withAlpha(100),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                child: viewModel.selectedProfileImage != null
                                    ? Image.file(
                                        viewModel.selectedProfileImage!,
                                        fit: BoxFit.cover,
                                        width: 120,
                                        height: 120,
                                      )
                                    : (viewModel.currentUser
                                                    ?.profilePictureUrl !=
                                                null &&
                                            viewModel.currentUser!
                                                .profilePictureUrl!.isNotEmpty
                                        ? Image.network(
                                            viewModel.currentUser!
                                                .profilePictureUrl!,
                                            fit: BoxFit.cover,
                                            width: 120,
                                            height: 120,
                                            errorBuilder: (context, error,
                                                    stackTrace) =>
                                                Image.asset(viewModel
                                                        .currentUser
                                                        ?.defaultAvatar ??
                                                    AppConstants.avatarBinary),
                                          )
                                        : Image.asset(viewModel
                                                .currentUser?.defaultAvatar ??
                                            AppConstants.avatarBinary)),
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
                      const SizedBox(height: 16),
                      CustomTextField(
                        labelText: 'First Name',
                        controller: viewModel.firstNameController,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        labelText: 'Last Name',
                        controller: viewModel.lastNameController,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        labelText: 'Username',
                        controller: viewModel.usernameController,
                      ),
                      const SizedBox(height: 16),
                      PhoneNumberField(
                        controller: viewModel.phoneController,
                        initialDialCode: '+92',
                        onChanged: viewModel.setPhoneNumber,
                      ),
                      const SizedBox(height: 16),
                      _buildDatePicker(context, viewModel),
                      const SizedBox(height: 16),
                      _buildGenderDropdown(context, viewModel),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(
      BuildContext context, EditProfileViewModel viewModel) {
    String dateText = '';
    if (viewModel.selectedDate != null) {
      final dob = viewModel.selectedDate!;
      dateText =
          '${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}';
    }

    // We create a dummy controller just to use CustomTextField visually
    final dateController = TextEditingController(text: dateText);

    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: viewModel.selectedDate ??
              DateTime.now().subtract(const Duration(days: 365 * 18)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.secondary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) viewModel.updateSelectedDate(picked);
      },
      child: AbsorbPointer(
        child: CustomTextField(
          controller: dateController,
          labelText: 'Date of Birth',
          keyboardType: TextInputType.datetime,
          suffixIcon: const Icon(
            Icons.calendar_today,
            color: AppColors.primaryDark,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown(
      BuildContext context, EditProfileViewModel viewModel) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return DropdownButtonFormField<String>(
      initialValue: viewModel.selectedGender,
      decoration: InputDecoration(
        fillColor: AppColors.background,
        filled: true,
        labelText: 'Gender',
        contentPadding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.0177,
          horizontal: screenWidth * 0.07,
        ),
        labelStyle: GoogleFonts.crimsonPro(
          color: AppColors.secondaryLight,
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(27),
        ),
      ),
      items: viewModel.genders.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
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
      isExpanded: true,
      hint: Text(
        'Select Gender',
        style: GoogleFonts.crimsonPro(
          color: AppColors.secondaryLight,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  EditProfileViewModel viewModelBuilder(BuildContext context) =>
      EditProfileViewModel();
}
