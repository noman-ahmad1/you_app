import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/app/app.dart';
import 'package:you_app/ui/common/animation_decoder.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/views/home/widgets/community_card.dart';
import 'package:you_app/ui/views/home/home_viewmodel.dart';
import "package:you_app/ui/shared/custom_lottie_loader.dart";
// ... your other imports

class CommunitiesScreen extends ViewModelWidget<HomeViewModel> {
  const CommunitiesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, HomeViewModel viewModel) {
    return Scaffold(
      // Use Scaffold as the root if it's a full screen
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
              leadingIconAsset: AppConstants.logoRound, // Your 'Y' logo asset
              onLeadingPressed: () {
                // Handle tap
              },
              title: 'Communities',
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
                              color: AppColors.primaryVeryDark.withAlpha(50)),
                        ),
                        child: Image.asset(
                            AppConstants
                                .notification, // Your notification icon asset
                            width: 24,
                            height: 24,
                            color: AppColors.primaryVeryDark),
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
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FIND YOUR PEOPLE',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: AppColors.secondary,
                                ),
                              ),
                              Space.verticalSpaceVTiny(context),
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.crimsonPro(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryVeryDark,
                                  ),
                                  children: const [
                                    TextSpan(text: 'You\'re '),
                                    TextSpan(
                                      text: 'never ',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                    TextSpan(text: 'alone in this.'),
                                  ],
                                ),
                              ),
                              Space.verticalSpaceTiny(context),
                              Text(
                                'Each community is a quiet circle for one shared experience.',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Space.verticalSpaceTiny(context),

                        // --- THE DYNAMIC LIST ---
                        StreamBuilder<List<Map<String, dynamic>>>(
                            stream: viewModel
                                .getCommunitiesStream(), // Call the service via ViewModel
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CustomLottieLoader());
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Center(
                                    child: Text("No communities found."));
                              }

                              final communities = snapshot.data!;

                              return ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: communities.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final community = communities[index];
                                  final communityId = community['id'];
                                  final isJoined =
                                      viewModel.isCommunityJoined(communityId);

                                  return CommunityCard(
                                    title: community['name'] ?? 'Unknown',
                                    description: community['description'] ??
                                        'A quiet circle for those carrying heavy hearts.',
                                    membersCount:
                                        community['membersCount']?.toString() ??
                                            '4,830',
                                    postsToday:
                                        community['postsToday']?.toString() ??
                                            '128',
                                    assetPath: community['imageAsset'] ??
                                        AppConstants.lonliness,
                                    coverPhotoUrl: community['cover_photo'],
                                    isJoined: isJoined,
                                    onJoin: () {
                                      viewModel.joinCommunity(communityId);
                                    },
                                    onTap: () {
                                      // Navigate to the specific community chat
                                      viewModel.navigateToCommunityChat(
                                        communityId: community['id'],
                                        communityName: community['name'],
                                      );
                                    },
                                  );
                                },
                              );
                            }),
                        // Space.verticalSpaceSmall(context),
                        // Space.verticalSpaceTiny(context),
                        const SizedBox(height: 120),
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
}
