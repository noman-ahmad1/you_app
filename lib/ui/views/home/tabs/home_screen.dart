import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/animation_decoder.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/app_theme.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/views/home/home_viewmodel.dart';
// import 'package:you_app/ui/views/home/volunteer_card.dart';
import 'package:you_app/ui/views/home/widgets/feature_nav_card.dart';
import 'package:you_app/ui/shared/topbar.dart';

class HomeScreen extends ViewModelWidget<HomeViewModel> {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, HomeViewModel viewModel) {
    final user = viewModel.currentUser;
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
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
                isCenterTitle: false,
                leadingIconAsset: AppConstants.logo, // Your 'Y' logo asset
                onLeadingPressed: () {
                  // Handle tap
                },
                title: 'Hi, ${viewModel.currentUser?.firstName ?? "Friend"}',
                subtitle: 'Saturday, May 16',
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
                                color: AppColors.secondary.withAlpha(50)),
                          ),
                          child: Image.asset(AppConstants.notification,
                              color: AppColors.primaryVeryDark,
                              width: 24,
                              height: 24),
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
                  InkWell(
                    onTap: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.secondary.withAlpha(50)),
                      ),
                      child: ClipOval(
                        child: user?.profilePictureUrl != null &&
                                user!.profilePictureUrl!.isNotEmpty
                            ? Image.network(user.profilePictureUrl!,
                                width: 34, height: 34, fit: BoxFit.cover)
                            : Image.asset(AppConstants.avatar,
                                width: 34, height: 34, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(23),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 200, sigmaY: 200),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  width: width * 0.9,
                                  // height: height * 0.125,
                                  decoration: BoxDecoration(
                                    color: AppColors.background.withAlpha(200),
                                    // AppColors.secondaryVeryLight
                                    //     .withAlpha(102),
                                    border: Border.all(
                                        color: AppColors.background, width: 2),
                                    // AppColors.secondary,
                                    // width: 2),
                                    borderRadius: BorderRadius.circular(23),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(25),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Today\'s Whisper',
                                        style: GoogleFonts.crimsonPro(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.secondary),
                                      ),
                                      Text(
                                        'Some days, surviving is a form of bravery too',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.crimsonPro(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryVeryDark),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Space.verticalSpaceTiny(context),
                            // Mood Card
                            ClipRRect(
                              borderRadius: BorderRadius.circular(23),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 200, sigmaY: 200),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  width: width * 0.9,
                                  height: height * 0.19,
                                  decoration: BoxDecoration(
                                    color: AppColors.background.withAlpha(200),
                                    // AppColors.secondaryVeryLight
                                    //     .withAlpha(102),
                                    border: Border.all(
                                        color: AppColors.background, width: 2),
                                    // AppColors.secondary,
                                    // width: 2),
                                    borderRadius: BorderRadius.circular(23),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(25),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Feeling happy, meh, or down?\n Lock it in!',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.crimsonPro(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.secondary),
                                      ),
                                      Space.verticalSpaceTiny(context),
                                      // Space.verticalSpaceVTiny(context),
                                      InkWell(
                                        onTap: () {
                                          viewModel.navigateToMoodTracker();
                                        },
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(23),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: 200, sigmaY: 200),
                                            child: Container(
                                              width: width * 0.7,
                                              height: height * 0.075,
                                              decoration: BoxDecoration(
                                                color:
                                                    // AppColors.background
                                                    //     .withAlpha(200),
                                                    AppColors.secondaryVeryLight
                                                        .withAlpha(200),
                                                border: Border.all(
                                                    color:
                                                        // AppColors
                                                        //     .background,
                                                        // width: 2),
                                                        AppColors
                                                            .secondaryVeryLight,
                                                    width: 2),
                                                borderRadius:
                                                    BorderRadius.circular(23),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withAlpha(25),
                                                    blurRadius: 20,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                                // image: DecorationImage(
                                                //   image: AssetImage(
                                                //       AppConstants.emo),
                                                //   fit: BoxFit.contain,
                                                // ),
                                              ),
                                              child: Center(
                                                child: Image.asset(
                                                    height: height * 0.055,
                                                    width: width * 0.75,
                                                    AppConstants.emo),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Space.verticalSpaceTiny(context),
                            // Journal Card
                            ClipRRect(
                              borderRadius: BorderRadius.circular(23),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 200, sigmaY: 200),
                                child: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 10, 0, 0),
                                  width: width * 0.9,
                                  height: height * 0.19,
                                  decoration: BoxDecoration(
                                    color: AppColors.background.withAlpha(200),
                                    // AppColors.secondaryVeryLight
                                    //     .withAlpha(102),
                                    border: Border.all(
                                        color: AppColors.background, width: 2),
                                    // AppColors.secondary,
                                    // width: 2),
                                    borderRadius: BorderRadius.circular(23),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(25),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Today\'s Journal',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.crimsonPro(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.secondary),
                                      ),
                                      Space.verticalSpaceVTiny(context),
                                      Row(
                                        children: [
                                          Column(
                                            children: [
                                              Text(
                                                'Your safe space to\n write',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.crimsonPro(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors
                                                        .primaryVeryDark),
                                              ),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(35),
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(
                                                      sigmaX: 200, sigmaY: 200),
                                                  child: Container(
                                                    padding: EdgeInsets.all(
                                                        width * 0.007),
                                                    width: width * 0.55,
                                                    height: height * 0.065,
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .secondaryVeryLight
                                                          .withAlpha(200),
                                                      border: Border.all(
                                                          color:
                                                              AppColors.peach,
                                                          width: 2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              100),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withAlpha(25),
                                                          blurRadius: 20,
                                                          offset: const Offset(
                                                              0, 4),
                                                        ),
                                                      ],
                                                    ),
                                                    child: SwipeButton.expand(
                                                      thumb: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(35),
                                                        child: BackdropFilter(
                                                          filter:
                                                              ImageFilter.blur(
                                                                  sigmaX: 200,
                                                                  sigmaY: 200),
                                                          child: Container(
                                                            width:
                                                                width * 0.115,
                                                            height:
                                                                height * 0.05,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: AppColors
                                                                  .secondaryVeryLight
                                                                  .withAlpha(
                                                                      200),
                                                              border: Border.all(
                                                                  color:
                                                                      AppColors
                                                                          .peach,
                                                                  width: 2),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          35),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Colors
                                                                      .black
                                                                      .withAlpha(
                                                                          25),
                                                                  blurRadius:
                                                                      20,
                                                                  offset:
                                                                      const Offset(
                                                                          0, 4),
                                                                ),
                                                              ],
                                                            ),
                                                            child: Center(
                                                              child:
                                                                  Image.asset(
                                                                AppConstants
                                                                    .write,
                                                                color: AppColors
                                                                    .secondary,
                                                                width: width *
                                                                    0.05,
                                                                height: height *
                                                                    0.025,
                                                                fit: BoxFit
                                                                    .contain,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      activeThumbColor:
                                                          const Color.fromRGBO(
                                                              0, 0, 0, 0),
                                                      activeTrackColor:
                                                          Colors.transparent,
                                                      onSwipeStart: () async {
                                                        HapticFeedback
                                                            .lightImpact();
                                                        // Play a gentle "swipe start" sound
                                                        // await viewModel
                                                        //     .playSwipeSound(
                                                        //         isComplete:
                                                        //             false);
                                                      },
                                                      onSwipe: () async {
                                                        // While swiping, you could loop a soft whoosh sound
                                                        // await viewModel
                                                        //     .playSwipeSound(
                                                        //         isComplete:
                                                        //             false);
                                                      },
                                                      onSwipeEnd: () async {
                                                        HapticFeedback
                                                            .mediumImpact();
                                                        // Stop swipe loop and play "completion chime"
                                                        // viewModel
                                                        //     .playSwipeSound(
                                                        //         isComplete:
                                                        //             true);
                                                        viewModel
                                                            .navigateToJournal();
                                                      },
                                                      child: Row(
                                                        children: [
                                                          SizedBox(
                                                              width:
                                                                  width * 0.14),
                                                          Text(
                                                            "Swipe to express",
                                                            style: GoogleFonts
                                                                .crimsonPro(
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: AppColors
                                                                  .secondary,
                                                            ),
                                                          ),
                                                          Lottie.asset(
                                                            decoder:
                                                                customDecoder,
                                                            AppConstants
                                                                .swipeRight,
                                                            width: width * 0.1,
                                                            height:
                                                                height * 0.05,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Space.horizontalSpaceTiny(context),
                                          Image.asset(
                                            AppConstants.journalImg,
                                            width: width * 0.21,
                                            height: height * 0.13,
                                            // width: width * 0.394,
                                            // height: height * 0.125,
                                            fit: BoxFit.cover,
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Space.verticalSpaceTiny(context),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () {
                                    viewModel.setTab(0);
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(23),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 200, sigmaY: 200),
                                      child: Container(
                                        padding: const EdgeInsets.all(15),
                                        width: width * 0.42,
                                        height: height * 0.14,
                                        decoration: BoxDecoration(
                                          color: AppColors.background
                                              .withAlpha(200),
                                          border: Border.all(
                                              color: AppColors.background,
                                              width: 2),
                                          borderRadius:
                                              BorderRadius.circular(23),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withAlpha(25),
                                              blurRadius: 20,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              AppConstants.community,
                                              color: AppColors.secondary,
                                              width: width * 0.1,
                                              height: height * 0.04,
                                              fit: BoxFit.cover,
                                            ),
                                            Text(
                                              'Communities',
                                              style: GoogleFonts.crimsonPro(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.secondary),
                                            ),
                                            Text(
                                              'Find your people',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.crimsonPro(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w300,
                                                  color: AppColors
                                                      .primaryVeryDark),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    viewModel.setTab(2);
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(23),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 200, sigmaY: 200),
                                      child: Container(
                                        padding: const EdgeInsets.all(15),
                                        width: width * 0.42,
                                        height: height * 0.14,
                                        decoration: BoxDecoration(
                                          color: AppColors.background
                                              .withAlpha(200),
                                          border: Border.all(
                                              color: AppColors.background,
                                              width: 2),
                                          borderRadius:
                                              BorderRadius.circular(23),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withAlpha(25),
                                              blurRadius: 20,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              AppConstants.chat,
                                              color: AppColors.secondary,
                                              width: width * 0.1,
                                              height: height * 0.04,
                                              fit: BoxFit.cover,
                                            ),
                                            Text(
                                              'Volunteers',
                                              style: GoogleFonts.crimsonPro(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.secondary),
                                            ),
                                            Text(
                                              'Caring Listeners',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.crimsonPro(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w300,
                                                  color: AppColors
                                                      .primaryVeryDark),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Space.verticalSpaceTiny(context),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                FeatureNavCard(
                                  title: 'Soothing Sounds',
                                  subtitle: 'Relax & Listen',
                                  imageAsset: AppConstants.soothing,
                                  onTap: viewModel.navigateToSoothingSounds,
                                ),
                                FeatureNavCard(
                                  title: 'Breathe',
                                  subtitle: 'Calm Your Mind',
                                  imageAsset: AppConstants.breathe,
                                  onTap: viewModel.navigateToBreathe,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 20, 200),
            child: InkWell(
              onTap: () async {
                viewModel.navigateToChatbot();
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    width: 100,
                    height: 100,
                    // width: width * 0.25,
                    // height: height * 0.115,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage(AppConstants.dodoCut),
                        fit: BoxFit.scaleDown,
                      ),
                      color: AppColors.pink.withAlpha(50),
                      border: Border.all(color: AppColors.pink, width: 2),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
//             Align(
//   alignment: Alignment.bottomRight,
//   child: Padding(
//     padding: const EdgeInsets.fromLTRB(0, 0, 20, 170),
//     child: GestureDetector(
//       onTap: () => viewModel.showBottomSheet(),
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           // Liquid Glass Bubble
//           SizedBox(
//             height: 150,  // keep width = height for circle
//             width: 150,
//             child: LiquidGlass(
//               shape: LiquidOval(), // perfect circle
//               // borderWidth: 2,
//               // borderColor: Colors.white.withOpacity(0.3),
//               child: Container(), // transparent center
//             ),
//           ),

//           // Icon/Image inside
//           Image.asset(
//             'assets/images/santa.png',
//             height: 100,
//             width: 100,
//           ),
//         ],
//       ),
//     ),
//   ),
// ),
      ],
    );
  }
}
