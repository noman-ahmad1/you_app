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

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: () => HomeViewModel(),
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
                    title: 'Home',
                    imageAssetPath: AppConstants.logo,
                    onMenuPressed: () {},
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 100),
                        child: SafeArea(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 25.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Hello Noman',
                                  style: GoogleFonts.crimsonPro(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondary),
                                ),
                                // Space.verticalSpaceVTiny(context),
                                Text(
                                  'Welcome to YOU, a safe space to land',
                                  style: GoogleFonts.crimsonPro(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondary),
                                ),
                                Space.verticalSpaceVTiny(context),
                                Space.verticalSpaceTiny(context),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(23),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 200, sigmaY: 200),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      width: width * 0.9,
                                      // height: height * 0.125,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryVeryLight
                                            .withAlpha(102),
                                        border: Border.all(
                                            color: AppColors.secondary,
                                            width: 2),
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
                                                color:
                                                    AppColors.primaryVeryDark),
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
                                    filter: ImageFilter.blur(
                                        sigmaX: 200, sigmaY: 200),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      width: width * 0.9,
                                      height: height * 0.19,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryVeryLight
                                            .withAlpha(102),
                                        border: Border.all(
                                            color: AppColors.secondary,
                                            width: 2),
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
                                                    color: AppColors
                                                        .secondaryVeryLight
                                                        .withAlpha(102),
                                                    border: Border.all(
                                                        color:
                                                            AppColors.secondary,
                                                        width: 2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            23),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withAlpha(25),
                                                        blurRadius: 20,
                                                        offset:
                                                            const Offset(0, 4),
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
                                    filter: ImageFilter.blur(
                                        sigmaX: 200, sigmaY: 200),
                                    child: Container(
                                      padding: const EdgeInsets.fromLTRB(
                                          10, 10, 0, 0),
                                      width: width * 0.9,
                                      height: height * 0.19,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryVeryLight
                                            .withAlpha(102),
                                        border: Border.all(
                                            color: AppColors.secondary,
                                            width: 2),
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
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors
                                                            .primaryVeryDark),
                                                  ),
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            35),
                                                    child: BackdropFilter(
                                                      filter: ImageFilter.blur(
                                                          sigmaX: 200,
                                                          sigmaY: 200),
                                                      child: Container(
                                                        padding: EdgeInsets.all(
                                                            width * 0.007),
                                                        width: width * 0.45,
                                                        height: height * 0.065,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppColors
                                                              .secondaryVeryLight
                                                              .withAlpha(102),
                                                          border: Border.all(
                                                              color: AppColors
                                                                  .secondary,
                                                              width: 2),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      100),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .black
                                                                  .withAlpha(
                                                                      25),
                                                              blurRadius: 20,
                                                              offset:
                                                                  const Offset(
                                                                      0, 4),
                                                            ),
                                                          ],
                                                        ),
                                                        child:
                                                            SwipeButton.expand(
                                                          thumb: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        35),
                                                            child:
                                                                BackdropFilter(
                                                              filter: ImageFilter
                                                                  .blur(
                                                                      sigmaX:
                                                                          200,
                                                                      sigmaY:
                                                                          200),
                                                              child: Container(
                                                                width: width *
                                                                    0.115,
                                                                height: height *
                                                                    0.05,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: AppColors
                                                                      .secondaryVeryLight
                                                                      .withAlpha(
                                                                          102),
                                                                  border: Border.all(
                                                                      color: AppColors
                                                                          .secondary,
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
                                                                              0,
                                                                              4),
                                                                    ),
                                                                  ],
                                                                ),
                                                                child: Center(
                                                                  child: Image
                                                                      .asset(
                                                                    AppConstants
                                                                        .write,
                                                                    color: AppColors
                                                                        .secondary,
                                                                    width:
                                                                        width *
                                                                            0.05,
                                                                    height:
                                                                        height *
                                                                            0.025,
                                                                    fit: BoxFit
                                                                        .contain,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          activeThumbColor:
                                                              const Color
                                                                  .fromRGBO(
                                                                  0, 0, 0, 0),
                                                          activeTrackColor:
                                                              Colors
                                                                  .transparent,
                                                          onSwipeStart:
                                                              () async {
                                                            HapticFeedback
                                                                .lightImpact();
                                                            // Play a gentle "swipe start" sound
                                                            await viewModel
                                                                .playSwipeSound(
                                                                    isComplete:
                                                                        false);
                                                          },
                                                          onSwipe: () async {
                                                            // While swiping, you could loop a soft whoosh sound
                                                            await viewModel
                                                                .playSwipeSound(
                                                                    isComplete:
                                                                        false);
                                                          },
                                                          onSwipeEnd: () async {
                                                            HapticFeedback
                                                                .mediumImpact();
                                                            // Stop swipe loop and play "completion chime"
                                                            viewModel
                                                                .playSwipeSound(
                                                                    isComplete:
                                                                        true);
                                                            viewModel
                                                                .navigateToJournal();
                                                          },
                                                          child: Row(
                                                            children: [
                                                              SizedBox(
                                                                  width: width *
                                                                      0.14),
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
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              // Space.horizontalSpaceTiny(context),
                                              Image.asset(
                                                AppConstants.journal,
                                                width: width * 0.394,
                                                height: height * 0.125,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Image.asset(
                                      AppConstants.back,
                                      color: AppColors.secondary,
                                      width: width * 0.08,
                                      height: height * 0.04,
                                      fit: BoxFit.cover,
                                    ),
                                    Text(
                                      'Soothing Sounds',
                                      style: GoogleFonts.crimsonPro(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.secondary),
                                    ),
                                    Image.asset(
                                      AppConstants.next,
                                      color: AppColors.secondary,
                                      width: width * 0.08,
                                      height: height * 0.04,
                                      fit: BoxFit.cover,
                                    ),
                                  ],
                                ),
                                Space.verticalSpaceTiny(context),
                                // Music Card
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(23),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                              sigmaX: 200, sigmaY: 200),
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            width: width * 0.42,
                                            height: height * 0.19,
                                            decoration: BoxDecoration(
                                              image: const DecorationImage(
                                                image: AssetImage(
                                                    AppConstants.music),
                                                fit: BoxFit.cover,
                                              ),
                                              color: AppColors
                                                  .secondaryVeryLight
                                                  .withAlpha(102),
                                              border: Border.all(
                                                  color: AppColors.secondary,
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
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    viewModel.skipBackward();
                                                  },
                                                  child: Image.asset(
                                                    AppConstants.backward,
                                                    color: AppColors.background,
                                                    width: width * 0.08,
                                                    height: height * 0.03,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    viewModel.togglePlayPause(
                                                        0, AppConstants.page);
                                                  },
                                                  child: Image.asset(
                                                    viewModel.isPlayingTrack(0)
                                                        ? AppConstants.pause
                                                        : AppConstants.play,
                                                    color: AppColors.background,
                                                    width: width * 0.06,
                                                    height: height * 0.03,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    viewModel.skipForward();
                                                  },
                                                  child: Image.asset(
                                                    AppConstants.forward,
                                                    color: AppColors.background,
                                                    width: width * 0.08,
                                                    height: height * 0.03,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Space.horizontalSpaceTiny(context),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(23),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                              sigmaX: 200, sigmaY: 200),
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            width: width * 0.42,
                                            height: height * 0.19,
                                            decoration: BoxDecoration(
                                              image: const DecorationImage(
                                                image: AssetImage(
                                                    AppConstants.music),
                                                fit: BoxFit.cover,
                                              ),
                                              color: AppColors
                                                  .secondaryVeryLight
                                                  .withAlpha(102),
                                              border: Border.all(
                                                  color: AppColors.secondary,
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
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    viewModel.skipBackward();
                                                  },
                                                  child: Image.asset(
                                                    AppConstants.backward,
                                                    color: AppColors.background,
                                                    width: width * 0.08,
                                                    height: height * 0.03,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    viewModel.togglePlayPause(
                                                        1, AppConstants.page);
                                                  },
                                                  child: Image.asset(
                                                    viewModel.isPlayingTrack(1)
                                                        ? AppConstants.pause
                                                        : AppConstants.play,
                                                    color: AppColors.background,
                                                    width: width * 0.06,
                                                    height: height * 0.03,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    viewModel.skipForward();
                                                  },
                                                  child: Image.asset(
                                                    AppConstants.forward,
                                                    color: AppColors.background,
                                                    width: width * 0.08,
                                                    height: height * 0.03,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Space.horizontalSpaceTiny(context),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(23),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                              sigmaX: 200, sigmaY: 200),
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            width: width * 0.42,
                                            height: height * 0.19,
                                            decoration: BoxDecoration(
                                              image: const DecorationImage(
                                                image: AssetImage(
                                                    AppConstants.music),
                                                fit: BoxFit.cover,
                                              ),
                                              color: AppColors
                                                  .secondaryVeryLight
                                                  .withAlpha(102),
                                              border: Border.all(
                                                  color: AppColors.secondary,
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
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    viewModel.skipBackward();
                                                  },
                                                  child: Image.asset(
                                                    AppConstants.backward,
                                                    color: AppColors.background,
                                                    width: width * 0.08,
                                                    height: height * 0.03,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    viewModel.togglePlayPause(
                                                        2, AppConstants.page);
                                                  },
                                                  child: Image.asset(
                                                    viewModel.isPlayingTrack(2)
                                                        ? AppConstants.pause
                                                        : AppConstants.play,
                                                    color: AppColors.background,
                                                    width: width * 0.06,
                                                    height: height * 0.03,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    viewModel.skipForward();
                                                  },
                                                  child: Image.asset(
                                                    AppConstants.forward,
                                                    color: AppColors.background,
                                                    width: width * 0.08,
                                                    height: height * 0.03,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
                padding: const EdgeInsets.fromLTRB(0, 0, 20, 170),
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
                        width: width * 0.25,
                        height: height * 0.115,
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage(AppConstants.santa),
                            fit: BoxFit.scaleDown,
                          ),
                          color: AppColors.secondaryVeryLight.withAlpha(50),
                          border:
                              Border.all(color: AppColors.secondary, width: 2),
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
      },
    );
  }
}
