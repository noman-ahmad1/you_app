import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/views/volunteer_home/volunteer_home_viewmodel.dart';
import "package:you_app/ui/shared/custom_lottie_loader.dart";

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
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
                    leadingIconAsset:
                        AppConstants.logoRound, // Your 'Y' logo asset
                    onLeadingPressed: () {
                      // Handle tap
                    },
                    title: 'Dashboard',
                    subtitle: DateFormat('EEEE, MMMM d').format(DateTime.now()),
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
                                  _buildHeader(viewModel),
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
                                  _buildStatsRow(viewModel),
                                  SizedBox(height: height * 0.03),
                                  _buildQuickActions(context, viewModel),
                                  const SizedBox(height: 120),
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
            if (viewModel.isBusy) const Center(child: CustomLottieLoader()),
          ],
        );
      },
    );
  }

  // --- Shared modern card styling ---
  BoxDecoration _cardDecoration() => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withAlpha(240),
            AppColors.secondaryVeryLight.withAlpha(70),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: AppColors.primaryVeryDark.withAlpha(20), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryVeryDark.withAlpha(18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );

  Widget _iconChip(String icon, {Color color = AppColors.secondary}) =>
      Container(
        padding: const EdgeInsets.all(9),
        decoration:
            BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
        child: Image.asset(icon, color: color, width: 22, height: 22),
      );

  /// HEADER SECTION
  Widget _buildHeader(VolunteerHomeViewModel viewModel) {
    return Row(
      children: [
        InkWell(
          onTap: () => viewModel.navigateToVolunteerEditProfile(),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.secondary, AppColors.secondaryLight],
              ),
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.secondaryVeryLight,
              backgroundImage: (viewModel.currentUserProfileUrl != null &&
                      viewModel.currentUserProfileUrl!.isNotEmpty)
                  ? NetworkImage(viewModel.currentUserProfileUrl!)
                  : AssetImage(viewModel.currentUser?.defaultAvatar ??
                      AppConstants.avatarBinary) as ImageProvider,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome back,",
                style: GoogleFonts.crimsonPro(
                  fontSize: 13,
                  color: AppColors.primaryVeryDark.withAlpha(150),
                ),
              ),
              Text(
                viewModel.currentUserName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.crimsonPro(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryVeryDark,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(28),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🎧 Volunteer Listener',
                  style: GoogleFonts.crimsonPro(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// STATS SECTION
  Widget _buildStatsRow(VolunteerHomeViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
              "Pending Requests",
              viewModel.pendingRequests.length.toString(),
              AppConstants.pending),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard("Active Chats",
              viewModel.activeChats.length.toString(), AppConstants.activeChat),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconChip(icon),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.crimsonPro(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryVeryDark,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.crimsonPro(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryVeryDark.withAlpha(160),
            ),
          ),
        ],
      ),
    );
  }

  /// QUICK ACTIONS
  Widget _buildQuickActions(
      BuildContext context, VolunteerHomeViewModel viewModel) {
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
        const SizedBox(height: 14),
        _buildCertificationCard(viewModel),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildActionButton("Edit Profile", AppConstants.setting,
                  viewModel.navigateToVolunteerEditProfile),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildActionButton("Completed Chats", AppConstants.done,
                  () => viewModel.showComingSoon('Completed Chats')),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildActionButton("Guidelines", AppConstants.write,
                  viewModel.navigateToGuidelines),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildActionButton("Log Out", AppConstants.logout,
                  viewModel.isBusy ? () {} : viewModel.logout),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildActionButton(
          "Delete Account",
          AppConstants.delete,
          viewModel.isBusy ? () {} : viewModel.deleteAccount,
          danger: true,
          fullWidth: true,
        ),
      ],
    );
  }

  /// Prominent gradient "Get Certified" card (feature in development).
  Widget _buildCertificationCard(VolunteerHomeViewModel viewModel) {
    return GestureDetector(
      onTap: viewModel.getCertification,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.secondary, AppColors.secondaryLight],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withAlpha(85),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(45),
                shape: BoxShape.circle,
              ),
              child: Image.asset(AppConstants.premiumBadgeFill,
                  width: 28, height: 28, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get Certified',
                    style: GoogleFonts.crimsonPro(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Earn your verified listener experience certificate',
                    style: GoogleFonts.crimsonPro(
                      fontSize: 12.5,
                      color: Colors.white.withAlpha(215),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, String icon, VoidCallback onTap,
      {bool danger = false, bool fullWidth = false}) {
    final accent = danger ? AppColors.error : AppColors.secondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withAlpha(240),
              accent.withAlpha(danger ? 28 : 60),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.primaryVeryDark.withAlpha(20), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryVeryDark.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment:
              fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            _iconChip(icon, color: accent),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.crimsonPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: danger ? AppColors.error : AppColors.primaryVeryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
