import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/views/home/community_card.dart';
import 'package:you_app/ui/views/home/home_viewmodel.dart';
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
              title: 'Communities',
              imageAssetPath: AppConstants.back,
              color: AppColors.secondary,
              onMenuPressed: () {}, // Handle back navigation here if needed
            ),
            Expanded(
              child: SingleChildScrollView(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Hello Noman', // TODO: Make this dynamic from ViewModel
                          style: GoogleFonts.crimsonPro(
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary),
                        ),
                        Text(
                          textAlign: TextAlign.center,
                          'You\'re not alone here. Connect, share, and grow with others on similar journeys — safely and supportively.',
                          style: GoogleFonts.crimsonPro(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryVeryDark),
                        ),
                        Space.verticalSpaceTiny(context),

                        // --- THE DYNAMIC GRID ---
                        StreamBuilder<List<Map<String, dynamic>>>(
                            stream: viewModel
                                .getCommunitiesStream(), // Call the service via ViewModel
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Center(
                                    child: Text("No communities found."));
                              }

                              final communities = snapshot.data!;

                              return GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: communities.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.9,
                                ),
                                itemBuilder: (context, index) {
                                  final community = communities[index];
                                  return CommunityCard(
                                    title: community['name'] ?? 'Unknown',
                                    assetPath: community['imageAsset'] ??
                                        AppConstants.anxiety,
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
                        Space.verticalSpaceSmall(context),
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
