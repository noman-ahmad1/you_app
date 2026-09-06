import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/topbar.dart';

import 'mood_recommendation_viewmodel.dart';

class MoodRecommendationView extends StackedView<MoodRecommendationViewModel> {
  final String emoji;

  const MoodRecommendationView({super.key, required this.emoji});

  @override
  Widget builder(
    BuildContext context,
    MoodRecommendationViewModel viewModel,
    Widget? child,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;

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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TopBar(
              leadingIconAsset: AppConstants.logoRound, // Your 'Y' logo asset
              onLeadingPressed: () {
                // Handle tap
              },
              title: 'Suggestions',
              trailingActions: [],
            ),
            Space.verticalSpaceMedium(context),
            Text(
              'Based on your mood,',
              style: GoogleFonts.crimsonPro(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryVeryDark),
            ),
            Text(
              'Here are some suggestions:',
              style: GoogleFonts.crimsonPro(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary),
            ),
            Space.verticalSpaceMedium(context),
            ...viewModel.recommendations.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  child: InkWell(
                    onTap: item.onTap,
                    child: Container(
                      width: width * 0.9,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.background.withAlpha(200),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            item.iconAsset,
                            width: 40,
                            height: 40,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.star,
                                  color: AppColors.primary);
                            },
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: GoogleFonts.crimsonPro(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryVeryDark),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.subtitle,
                                  style: GoogleFonts.crimsonPro(
                                      fontSize: 16,
                                      color: AppColors.primaryDark),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              color: AppColors.primary, size: 18),
                        ],
                      ),
                    ),
                  ),
                )),
            const Spacer(),
            TextButton(
              onPressed: viewModel.skip,
              child: Text(
                'Skip for now',
                style: GoogleFonts.crimsonPro(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary.withValues(alpha: 0.8)),
              ),
            ),
            Space.verticalSpaceMedium(context),
          ],
        ),
      ),
    );
  }

  @override
  MoodRecommendationViewModel viewModelBuilder(BuildContext context) =>
      MoodRecommendationViewModel(emojiAssetPath: emoji);

  @override
  void onViewModelReady(MoodRecommendationViewModel viewModel) {
    viewModel.initialize();
    super.onViewModelReady(viewModel);
  }
}
