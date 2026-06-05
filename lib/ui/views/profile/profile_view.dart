import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/shared/widgets.dart';
import 'profile_viewmodel.dart';

class ProfileView extends StackedView<ProfileViewModel> {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    ProfileViewModel viewModel,
    Widget? child,
  ) {
    final user = viewModel.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              onLeadingPressed: () {
                Navigator.pop(context);
              },
              title: 'Profile',
              iconColor: AppColors.primaryVeryDark,
              trailingActions: [
                IconButton(
                  icon:
                      const Icon(Icons.edit, color: AppColors.primaryVeryDark),
                  onPressed: viewModel.navigateToEditProfile,
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: SafeArea(
                  top: false,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (viewModel.completionPercentage < 1.0) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.background.withAlpha(70),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Profile Completeness',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryVeryDark,
                                  ),
                                ),
                                Text(
                                  '${(viewModel.completionPercentage * 100).toInt()}%',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: viewModel.completionPercentage,
                                backgroundColor:
                                    AppColors.primaryLight.withAlpha(50),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.secondary),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Space.verticalSpaceTiny(context),
                    ],
                    // Profile Picture
                    Hero(
                      tag: 'profile_pic',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.primaryLight, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(50),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.secondaryVeryLight,
                          backgroundImage: user.profilePictureUrl != null &&
                                  user.profilePictureUrl!.isNotEmpty
                              ? NetworkImage(user.profilePictureUrl!)
                              : AssetImage(user.defaultAvatar)
                                  as ImageProvider,
                        ),
                      ),
                    ),
                    Space.verticalSpaceTiny(context),

                    // Name
                    Text(
                      user.fullName,
                      style: GoogleFonts.crimsonPro(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    Space.verticalSpaceVTiny(context),

                    // Username / Role
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.username != null
                            ? '@${user.username} • ${viewModel.displayRole}'
                            : viewModel.displayRole,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    Space.verticalSpaceTiny(context),

                    // Profile Details Container
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background.withAlpha(100),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildProfileItem(
                            iconAsset: AppConstants.email,
                            title: 'Email',
                            value: user.email,
                            iconColor: AppColors.secondary,
                          ),
                          const Divider(height: 32),
                          _buildProfileItem(
                            iconAsset: AppConstants.phone,
                            title: 'Phone',
                            value: user.phoneNumber ?? 'Not specified',
                            iconColor: AppColors.secondary,
                          ),
                          const Divider(height: 32),
                          _buildProfileItem(
                            iconAsset: AppConstants.gift,
                            title: 'Date of Birth',
                            value: viewModel.formattedDateOfBirth,
                            iconColor: AppColors.secondary,
                          ),
                          const Divider(height: 32),
                          _buildProfileItem(
                            iconAsset: AppConstants.person,
                            title: 'Gender',
                            value: user.gender ?? 'Not specified',
                            iconColor: AppColors.secondary,
                          ),
                          if (user.isVolunteer) ...[
                            const Divider(height: 32),
                            _buildProfileItem(
                              iconAsset: AppConstants.done,
                              title: 'Volunteer Status',
                              value: user.status
                                  .replaceAll('_', ' ')
                                  .toUpperCase(),
                              valueColor: user.status == 'active'
                                  ? Colors.green
                                  : AppColors.primaryDark,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Space.verticalSpaceTiny(context),
                    CustomButton(
                        text: "Edit",
                        onPressed: () {
                          viewModel.navigateToEditProfile();
                        }),
                  ],
                ),
              ),
            ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    // required IconData icon,
    required String iconAsset,
    required String title,
    required String value,
    Color? iconColor,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.secondaryVeryLight.withAlpha(150),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              Image.asset(iconAsset, width: 24, height: 24, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: valueColor ?? AppColors.primaryVeryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  ProfileViewModel viewModelBuilder(BuildContext context) => ProfileViewModel();
}
