import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/app_theme.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/views/home/home_viewmodel.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/views/volunteer_home/volunteer_home_viewmodel.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    return ViewModelBuilder<VolunteerHomeViewModel>.reactive(
      viewModelBuilder: () => VolunteerHomeViewModel(),
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
                    title: 'Dashboard',
                    imageAssetPath: AppConstants.logo,
                    onMenuPressed: () {},
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
                                  _buildHeader(width, height),
                                  SizedBox(height: height * 0.03),
                                  _buildStatsRow(width, height),
                                  SizedBox(height: height * 0.03),
                                  _buildQuickActions(width, height),
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
          ],
        );
      },
    );
  }

  /// HEADER SECTION
  Widget _buildHeader(double width, double height) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: Container(
                width: width * 0.18,
                height: width * 0.18,
                decoration: BoxDecoration(
                  color: AppColors.secondaryVeryLight.withAlpha(102),
                  border: Border.all(color: AppColors.secondary, width: 2),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(AppConstants.avatar, fit: BoxFit.cover),
              ),
            ),
            SizedBox(width: width * 0.04),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, Ali",
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
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.04,
              vertical: height * 0.01,
            ),
          ),
          onPressed: () {
            print("Edit Profile");
          },
          child: Text(
            "Edit Profile",
            style: GoogleFonts.crimsonPro(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// STATS SECTION
  Widget _buildStatsRow(double width, double height) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard("Total Chats", "45", AppConstants.msg, width, height),
        _buildStatCard(
            "Active Chats", "3", AppConstants.activeChat, width, height),
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
  Widget _buildQuickActions(double width, double height) {
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
            _buildActionButton("Pending Requests", AppConstants.pending, () {
              print("Pending Requests");
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
            _buildActionButton("My Journal", AppConstants.journalIcon, () {
              print("Open Journal");
            }, width, height),
            _buildActionButton("Settings", AppConstants.setting, () {
              print("Settings");
            }, width, height),
          ],
        ),
      ],
    );
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
