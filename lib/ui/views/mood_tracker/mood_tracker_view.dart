import 'dart:ui';
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
        appBar: TopBar(
          title: 'Mood Tracker',
          imageAssetPath: AppConstants.back,
          color: AppColors.secondary,
          onBackPressed: () {
            viewModel.back();
          },
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppConstants.background),
              fit: BoxFit.cover,
            ),
          ),
          child: SingleChildScrollView(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Space.verticalSpaceTiny(context),
                  Text(
                    'Track your mood journey',
                    style: GoogleFonts.crimsonPro(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary),
                  ),
                  // Space.verticalSpaceVTiny(context),
                  Text(
                    textAlign: TextAlign.center,
                    'Taking a moment to acknowledge your feelings\nis a step toward self-care.',
                    style: GoogleFonts.crimsonPro(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryVeryDark),
                  ),
                  Space.verticalSpaceTiny(context),
                  SwipeButton(
                    text: "Energized",
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
                    text: "Holding steady?",
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
                  BarChartSample7()
                ],
              ),
            ),
          ),
        ));
  }

  @override
  MoodTrackerViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      MoodTrackerViewModel();
}
