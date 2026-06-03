import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/views/home/home_viewmodel.dart';

class HomeDrawer extends StatelessWidget {
  final HomeViewModel viewModel;

  const HomeDrawer({Key? key, required this.viewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = viewModel.currentUser;
    return Drawer(
      backgroundColor:
          AppColors.background, // Soft off-white to match screenshot
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(35),
          bottomLeft: Radius.circular(35),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Avatar, Name/Email, Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: user?.profilePictureUrl != null &&
                            user!.profilePictureUrl!.isNotEmpty
                        ? NetworkImage(user!.profilePictureUrl!)
                        : const AssetImage(AppConstants.avatar)
                            as ImageProvider,
                    backgroundColor: AppColors.secondaryVeryLight,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          viewModel.currentUserName,
                          style: GoogleFonts.crimsonPro(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                        Text(
                          viewModel.currentUserEmail,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.withAlpha(50)),
                      ),
                      child: const Icon(Icons.close,
                          size: 20, color: AppColors.secondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Streak Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.secondaryVeryLight
                      .withAlpha(200), // Light purple background
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '7-DAY STREAK 🔥',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppColors.secondary, // Purple text
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You've shown up for yourself this week.",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        height: 1.4,
                        color: AppColors.primaryVeryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Menu Items
              _buildMenuItem(
                iconPath: AppConstants.person,
                title: 'My profile',
                onTap: () {
                  Navigator.pop(context);
                  viewModel.navigateToProfile();
                },
              ),
              const SizedBox(height: 24),
              _buildMenuItem(
                iconPath: AppConstants.heart,
                title: 'Mood history',
                onTap: () {
                  Navigator.pop(context);
                  viewModel.navigateToMoodTracker();
                },
              ),
              const SizedBox(height: 24),
              _buildMenuItem(
                iconPath: AppConstants.group,
                title: 'My communities',
                onTap: () {
                  Navigator.pop(context);
                  viewModel.setTab(0);
                },
              ),
              const SizedBox(height: 24),
              _buildMenuItem(
                iconPath: AppConstants.starFill,
                title: 'Listeners',
                onTap: () {
                  Navigator.pop(context);
                  viewModel.setTab(2);
                },
              ),
              const SizedBox(height: 24),
              _buildMenuItem(
                iconPath: AppConstants.star,
                title: 'Breathe',
                onTap: () {},
              ),

              const Spacer(),

              // Logout button at the bottom
              _buildMenuItem(
                iconPath: AppConstants.logout,
                title: 'Log out',
                onTap: () {
                  Navigator.pop(context);
                  viewModel.logout();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    String? iconPath,
    IconData? icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondaryVeryLight
                  .withAlpha(200), // Light purple box background
              borderRadius: BorderRadius.circular(14),
            ),
            child: iconPath != null
                ? Image.asset(
                    iconPath,
                    width: 22,
                    height: 22,
                    color: AppColors.secondary, // Dark purple icon
                  )
                : Icon(
                    icon,
                    size: 22,
                    color: AppColors.secondary,
                  ),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryVeryDark,
            ),
          ),
        ],
      ),
    );
  }
}
