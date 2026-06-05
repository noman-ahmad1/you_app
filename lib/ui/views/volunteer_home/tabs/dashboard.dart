import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/app/app.dart';
import 'package:you_app/ui/common/animation_decoder.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/views/volunteer_home/volunteer_home_viewmodel.dart';
import "package:you_app/ui/shared/custom_lottie_loader.dart";

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    return ViewModelBuilder<VolunteerHomeViewModel>.reactive(
      viewModelBuilder: () => VolunteerHomeViewModel(),
      onViewModelReady: (viewModel) =>
          viewModel.initialize(), // Ensure initialization if needed
      builder: (context, viewModel, child) {
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AppConstants.background),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  TopBar(
                    leadingIconAsset: AppConstants.logo, // Your 'Y' logo asset
                    onLeadingPressed: () {
                      // Handle tap
                    },
                    title: 'Dashboard',
                    subtitle: _getFormattedDate(),
                    trailingActions: [
                      // Icon 1 (e.g., Notifications)
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          InkWell(
                            onTap: () {
                              viewModel.markAllNotificationsAsRead();
                              Scaffold.of(context).openDrawer();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primaryVeryDark
                                        .withAlpha(50)),
                              ),
                              child: Image.asset(AppConstants.notification,
                                  width: 24, height: 24),
                            ),
                          ),
                          Positioned(
                            right: -4,
                            top: -4,
                            child: IgnorePointer(
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: viewModel.unreadNotificationsCount > 0
                                    ? 1.0
                                    : 0.0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    '${viewModel.unreadNotificationsCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Icon 2 (e.g., Profile/Flower)
                      // InkWell(
                      //   onTap: () {},
                      //   child: Container(
                      //     padding: const EdgeInsets.all(4),
                      //     decoration: BoxDecoration(
                      //       shape: BoxShape.circle,
                      //       border: Border.all(
                      //           color: AppColors.primaryVeryDark.withAlpha(50)),
                      //     ),
                      //     child: ClipOval(
                      //       child: viewModel.currentUserProfileUrl != null &&
                      //               viewModel.currentUserProfileUrl!.isNotEmpty
                      //           ? Image.network(
                      //               viewModel.currentUserProfileUrl!,
                      //               width: 24,
                      //               height: 24,
                      //               fit: BoxFit.cover)
                      //           : Image.asset(AppConstants.avatar,
                      //               width: 24, height: 24, fit: BoxFit.cover),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeader(width, height, viewModel),
                                  SizedBox(height: height * 0.03),
                                  Text(
                                    "Overview",
                                    style: GoogleFonts.crimsonPro(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryVeryDark,
                                    ),
                                  ),
                                  SizedBox(height: height * 0.02),
                                  _buildStatsRow(width, height, viewModel),
                                  SizedBox(height: height * 0.03),
                                  _buildQuickActions(
                                      context, width, height, viewModel),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Show a loading indicator if the ViewModel is busy (e.g., during logout)
            if (viewModel.isBusy)
              const Center(
                child: CustomLottieLoader()
              ),
          ],
        );
      },
    );
  }

  /// HEADER SECTION
  Widget _buildHeader(
      double width, double height, VolunteerHomeViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => viewModel.navigateToVolunteerEditProfile(),
              child: Container(
                width: width * 0.18,
                height: width * 0.18,
                decoration: BoxDecoration(
                  color: AppColors.secondaryVeryLight.withAlpha(102),
                  border: Border.all(color: AppColors.secondary, width: 2),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: viewModel.currentUserProfileUrl != null &&
                          viewModel.currentUserProfileUrl!.isNotEmpty
                      ? Image.network(viewModel.currentUserProfileUrl!,
                          fit: BoxFit.cover)
                      : Image.asset(AppConstants.avatar, fit: BoxFit.cover),
                ),
              ),
            ),
            SizedBox(width: width * 0.04),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, ${viewModel.currentUserName}",
                  style: GoogleFonts.crimsonPro(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryVeryDark,
                  ),
                ),
                Text(
                  "Volunteer Listener",
                  style: GoogleFonts.crimsonPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        // Removed the "Edit Profile" button from here, moving it to Quick Actions
      ],
    );
  }

  /// STATS SECTION
  Widget _buildStatsRow(
      double width, double height, VolunteerHomeViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard(
            "Pending Requests",
            viewModel.pendingRequests.length.toString(),
            AppConstants.pending,
            width,
            height),
        _buildStatCard("Active Chats", viewModel.activeChats.length.toString(),
            AppConstants.activeChat, width, height),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, String icon, double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
        child: Container(
          width: width * 0.42,
          height: height * 0.14,
          padding: EdgeInsets.all(width * 0.04),
          decoration: BoxDecoration(
            color: AppColors.secondaryVeryLight.withAlpha(90),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppColors.secondary, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(icon,
                  color: AppColors.secondary, width: width * 0.08),
              Spacer(),
              Text(
                value,
                style: GoogleFonts.crimsonPro(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryVeryDark,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.crimsonPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// QUICK ACTIONS
  Widget _buildQuickActions(BuildContext context, double width, double height,
      VolunteerHomeViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: GoogleFonts.crimsonPro(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryVeryDark,
          ),
        ),
        SizedBox(height: height * 0.02),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionButton("Edit Profile", AppConstants.setting, () {
              viewModel.navigateToVolunteerEditProfile();
            }, width, height),
            _buildActionButton("Completed Chats", AppConstants.done, () {
              print("Completed Chats");
            }, width, height),
          ],
        ),
        SizedBox(height: height * 0.02),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // LOGOUT BUTTON: Calls the ViewModel's logout method
            _buildActionButton(
              "Log Out",
              AppConstants.logout,
              viewModel.isBusy ? () {} : viewModel.logout, // Disable when busy
              width,
              height,
            ),
            _buildActionButton("Guidelines", AppConstants.write, () {
              print("Guidelines");
            }, width, height),
          ],
        ),
      ],
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  Widget _buildActionButton(String title, String icon, VoidCallback onTap,
      double width, double height) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
          child: Container(
            width: width * 0.42,
            height: height * 0.12,
            padding: EdgeInsets.all(width * 0.04),
            decoration: BoxDecoration(
              color: AppColors.secondaryVeryLight.withAlpha(90),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppColors.secondary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(icon,
                    color: AppColors.secondary, width: width * 0.08),
                SizedBox(height: height * 0.01),
                Text(
                  title,
                  style: GoogleFonts.crimsonPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryVeryDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
