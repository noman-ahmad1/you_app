import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/views/mood_tracker/chart.dart';
import 'package:you_app/ui/views/mood_tracker/swipe_card.dart';

import 'mood_tracker_viewmodel.dart';

class MoodTrackerView extends StackedView<MoodTrackerViewModel> {
  const MoodTrackerView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    MoodTrackerViewModel viewModel,
    Widget? child,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
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
              leadingIconAsset: AppConstants.back, // Your 'Y' logo asset
              iconColor: AppColors.primaryVeryDark,
              onLeadingPressed: () {
                Navigator.pop(context);
              },
              title: 'Mood Tracker',
              subtitle: DateFormat('EEEE, MMMM d').format(DateTime.now()),
              trailingActions: [],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: SafeArea(
                  top:
                      false, // TopBar handles the top safe area usually, but just in case
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Space.verticalSpaceTiny(context),
                      if (viewModel.moodStreak > 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.4)),
                          ),
                          child: Text(
                            '🔥 ${viewModel.moodStreak} Day Streak!',
                            style: GoogleFonts.crimsonPro(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary),
                          ),
                        ),
                      Text(
                        'Track your mood journey',
                        style: GoogleFonts.crimsonPro(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary),
                      ),
                      Space.verticalSpaceVTiny(context),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          textAlign: TextAlign.center,
                          viewModel.dailyQuote,
                          style: GoogleFonts.crimsonPro(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryVeryDark),
                        ),
                      ),
                      Space.verticalSpaceTiny(context),
                      SwipeButton(
                        text: "Energized",
                        lottieAsset: AppConstants.swipeRight,
                        iconAsset: AppConstants.emoji_1,
                        direction: SwipeDirection.left,
                        height: height * 0.065,
                        width: width * 0.9,
                        onSwipe: () {
                          viewModel.onEmojiSelected(AppConstants.emoji_1);
                        },
                      ),
                      Space.verticalSpaceVTiny(context),
                      SwipeButton(
                        text: "Main character vibe",
                        lottieAsset: AppConstants.swipeRight,
                        iconAsset: AppConstants.emoji_2,
                        direction: SwipeDirection.left,
                        height: height * 0.065,
                        width: width * 0.9,
                        onSwipe: () {
                          viewModel.onEmojiSelected(AppConstants.emoji_2);
                        },
                      ),
                      Space.verticalSpaceVTiny(context),
                      SwipeButton(
                        text: "Over the moon",
                        lottieAsset: AppConstants.swipeRight,
                        iconAsset: AppConstants.emoji_3,
                        direction: SwipeDirection.left,
                        height: height * 0.065,
                        width: width * 0.9,
                        onSwipe: () {
                          viewModel.onEmojiSelected(AppConstants.emoji_3);
                        },
                      ),
                      Space.verticalSpaceVTiny(context),
                      SwipeButton(
                        text: "chill mode",
                        lottieAsset: AppConstants.swipeRight,
                        iconAsset: AppConstants.emoji_4,
                        direction: SwipeDirection.left,
                        height: height * 0.065,
                        width: width * 0.9,
                        onSwipe: () {
                          viewModel.onEmojiSelected(AppConstants.emoji_4);
                        },
                      ),
                      Space.verticalSpaceVTiny(context),
                      SwipeButton(
                        text: "Holding                          steady?",
                        lottieAsset: AppConstants.swipeRight,
                        iconAsset: AppConstants.emoji_5,
                        direction: SwipeDirection.both,
                        height: height * 0.065,
                        width: width * 0.9,
                        onSwipeLeft: () {
                          viewModel.onEmojiSelected(AppConstants.emoji_5);
                        },
                        onSwipeRight: () {
                          viewModel.onEmojiSelected(AppConstants.emoji_5);
                        },
                      ),
                      Space.verticalSpaceVTiny(context),
                      SwipeButton(
                        text: "Restless?",
                        lottieAsset: AppConstants.swipeLeft,
                        iconAsset: AppConstants.emoji_6,
                        direction: SwipeDirection.right,
                        height: height * 0.065,
                        width: width * 0.9,
                        onSwipe: () {
                          viewModel.onEmojiSelected(AppConstants.emoji_6);
                        },
                      ),
                      Space.verticalSpaceVTiny(context),
                      SwipeButton(
                        text: "Running on 1%?",
                        lottieAsset: AppConstants.swipeLeft,
                        iconAsset: AppConstants.emoji_7,
                        direction: SwipeDirection.right,
                        height: height * 0.065,
                        width: width * 0.9,
                        onSwipe: () {
                          viewModel.onEmojiSelected(AppConstants.emoji_7);
                        },
                      ),
                      Space.verticalSpaceVTiny(context),
                      SwipeButton(
                        text: "Overstimulated?",
                        lottieAsset: AppConstants.swipeLeft,
                        iconAsset: AppConstants.emoji_8,
                        direction: SwipeDirection.right,
                        height: height * 0.065,
                        width: width * 0.9,
                        onSwipe: () {
                          viewModel.onEmojiSelected(AppConstants.emoji_8);
                        },
                      ),
                      Space.verticalSpaceVTiny(context),
                      SwipeButton(
                        text: "About to crash out??",
                        lottieAsset: AppConstants.swipeLeft,
                        iconAsset: AppConstants.emoji_9,
                        direction: SwipeDirection.right,
                        height: height * 0.065,
                        width: width * 0.9,
                        onSwipe: () {
                          viewModel.onEmojiSelected(AppConstants.emoji_9);
                        },
                      ),
                      Space.verticalSpaceVTiny(context),
                      // Text(
                      //   'Emotional Insights',
                      //   style: GoogleFonts.crimsonPro(
                      //       fontSize: 25,
                      //       fontWeight: FontWeight.w700,
                      //       color: AppColors.secondary),
                      // ),
                      WeeklyMoodChart(key: viewModel.chartKey),
                      if (viewModel.insightsLocked)
                        _AdvancedInsightsTeaser(viewModel: viewModel),
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

  @override
  MoodTrackerViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      MoodTrackerViewModel();
}

/// Premium teaser inviting free users into advanced mood insights (deep
/// patterns, triggers, weekly/monthly reports).
class _AdvancedInsightsTeaser extends StatelessWidget {
  final MoodTrackerViewModel viewModel;
  const _AdvancedInsightsTeaser({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: viewModel.onUnlockInsights,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.secondary.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.insights_outlined,
                color: AppColors.secondary, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Advanced mood insights',
                    style: GoogleFonts.crimsonPro(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                  Text(
                    'Deep patterns, triggers & personal reports with Premium.',
                    style: GoogleFonts.crimsonPro(
                      fontSize: 12,
                      color: AppColors.secondary.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.lock_outline,
                color: AppColors.secondary, size: 20),
          ],
        ),
      ),
    );
  }
}
