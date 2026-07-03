import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:lottie/lottie.dart';
import 'package:you_app/ui/shared/app_showcase.dart';
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
    Widget _buildShowcase(
        {required GlobalKey key,
        required String title,
        required String description,
        required Widget child}) {
      return AppShowcase.step(
        key: key,
        title: title,
        description: description,
        child: child,
      );
    }

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
                leadingIconAsset: AppConstants.logoRound, // Your 'Y' logo asset
                onLeadingPressed: () {
                  // Handle tap
                },
                title: 'Hi, ${viewModel.currentUser?.firstName ?? "Friend"}',
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
                            : Image.asset(
                                user?.defaultAvatar ??
                                    AppConstants.avatarBinary,
                                width: 34,
                                height: 34,
                                fit: BoxFit.cover),
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
                            _HomeAnnouncement(viewModel: viewModel),
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
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.secondary),
                                      ),
                                      Text(
                                        viewModel.todayWhisper,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.crimsonPro(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryVeryDark),
                                      ),
                                      Space.verticalSpaceVTiny(context),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Space.verticalSpaceTiny(context),
                            // Mood Card
                            _buildShowcase(
                              key: viewModel.moodKey,
                              title: 'Mood Tracker',
                              description:
                                  'Log how you feel and track your emotional journey.',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(23),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 200, sigmaY: 200),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    width: width * 0.9,
                                    height: height * 0.19,
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.background.withAlpha(200),
                                      // AppColors.secondaryVeryLight
                                      //     .withAlpha(102),
                                      border: Border.all(
                                          color: AppColors.background,
                                          width: 2),
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
                                              fontSize: 18,
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
                                                      AppColors
                                                          .secondaryVeryLight
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
                            ),
                            Space.verticalSpaceTiny(context),
                            // Journal Card
                            _buildShowcase(
                              key: viewModel.journalKey,
                              title: 'Journaling',
                              description:
                                  'Swipe to express your thoughts in a safe space.',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(23),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 200, sigmaY: 200),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.fromLTRB(10, 10, 0, 0),
                                    width: width * 0.9,
                                    height: height * 0.19,
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.background.withAlpha(200),
                                      // AppColors.secondaryVeryLight
                                      //     .withAlpha(102),
                                      border: Border.all(
                                          color: AppColors.background,
                                          width: 2),
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
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.secondary),
                                        ),
                                        Space.verticalSpaceVTiny(context),
                                        Row(
                                          children: [
                                            Column(
                                              children: [
                                                Text(
                                                  'Your safe space to write',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.crimsonPro(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColors
                                                          .primaryVeryDark),
                                                ),
                                                Space.verticalSpaceTiny(
                                                    context),
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(35),
                                                  child: BackdropFilter(
                                                    filter: ImageFilter.blur(
                                                        sigmaX: 200,
                                                        sigmaY: 200),
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
                                                            BorderRadius
                                                                .circular(100),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withAlpha(25),
                                                            blurRadius: 20,
                                                            offset:
                                                                const Offset(
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
                                                            filter: ImageFilter
                                                                .blur(
                                                                    sigmaX: 200,
                                                                    sigmaY:
                                                                        200),
                                                            child: Container(
                                                              width:
                                                                  height * 0.05,
                                                              height:
                                                                  height * 0.05,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: AppColors
                                                                    .secondaryVeryLight
                                                                    .withAlpha(
                                                                        200),
                                                                border: Border.all(
                                                                    color: AppColors
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
                                                                            0,
                                                                            4),
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
                                                                  width:
                                                                      height *
                                                                          0.025,
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
                                                        child: FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: Row(
                                                            children: [
                                                              SizedBox(
                                                                  width: width *
                                                                      0.14),
                                                              Text(
                                                                "Swipe to express",
                                                                style: GoogleFonts
                                                                    .crimsonPro(
                                                                  fontSize: 14,
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
                                                                width:
                                                                    width * 0.1,
                                                                height: height *
                                                                    0.05,
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
                                            Space.horizontalSpaceTiny(context),
                                            Expanded(
                                              child: Image.asset(
                                                AppConstants.journalImg,
                                                width: width * 0.21,
                                                height: height * 0.13,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Space.verticalSpaceTiny(context),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildShowcase(
                                  key: viewModel.communitiesKey,
                                  title: 'Communities',
                                  description:
                                      'Find your people and connect with others.',
                                  child: InkWell(
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
                                                color:
                                                    Colors.black.withAlpha(25),
                                                blurRadius: 20,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Image.asset(
                                                AppConstants.community2,
                                                // color: AppColors.secondary,
                                                width: width * 0.135,
                                                height: height * 0.05,
                                                fit: BoxFit.cover,
                                              ),
                                              Text(
                                                'Communities',
                                                style: GoogleFonts.crimsonPro(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppColors.secondary),
                                              ),
                                              Text(
                                                'Find your people',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.crimsonPro(
                                                    fontSize: 14,
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
                                ),
                                _buildShowcase(
                                  key: viewModel.volunteersKey,
                                  title: 'Volunteers',
                                  description:
                                      'Caring listeners available to chat.',
                                  child: InkWell(
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
                                                color:
                                                    Colors.black.withAlpha(25),
                                                blurRadius: 20,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Image.asset(
                                                AppConstants.brain,
                                                // color: AppColors.secondary,
                                                width: width * 0.12,
                                                height: height * 0.05,
                                                fit: BoxFit.cover,
                                              ),
                                              Text(
                                                'Volunteers',
                                                style: GoogleFonts.crimsonPro(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppColors.secondary),
                                              ),
                                              Text(
                                                'Caring Listeners',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.crimsonPro(
                                                    fontSize: 14,
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
                                ),
                              ],
                            ),
                            Space.verticalSpaceTiny(context),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildShowcase(
                                  key: viewModel.soothingSoundsKey,
                                  title: 'Soothing Sounds',
                                  description:
                                      'Relax your mind with calming audio.',
                                  child: FeatureNavCard(
                                    title: 'Soothing Sounds',
                                    subtitle: 'Relax & Listen',
                                    imageAsset: AppConstants.soothing,
                                    onTap: viewModel.navigateToSoothingSounds,
                                  ),
                                ),
                                _buildShowcase(
                                  key: viewModel.breatheKey,
                                  title: 'Breathe',
                                  description:
                                      'Follow guided breathing exercises.',
                                  child: FeatureNavCard(
                                    title: 'Breathe',
                                    subtitle: 'Calm Your Mind',
                                    imageAsset: AppConstants.breathe,
                                    onTap: viewModel.navigateToBreathe,
                                  ),
                                ),
                              ],
                            ),
                            // const SizedBox(height: 120),
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
            child: _buildShowcase(
              key: viewModel.dodoKey,
              title: 'AI Dodo',
              description:
                  'Tap here to chat with your compassionate AI companion.',
              child: _AnimatedDodoIcon(
                onTap: () async {
                  viewModel.navigateToChatbot();
                },
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

class _AnimatedDodoIcon extends StatefulWidget {
  final VoidCallback onTap;

  const _AnimatedDodoIcon({Key? key, required this.onTap}) : super(key: key);

  @override
  State<_AnimatedDodoIcon> createState() => _AnimatedDodoIconState();
}

class _AnimatedDodoIconState extends State<_AnimatedDodoIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: InkWell(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
            child: Container(
              padding: const EdgeInsets.all(10),
              width: 100,
              height: 100,
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
    );
  }
}

/// A light, dismissible FYI strip for the admin-authored home announcement.
/// Renders nothing when there's no active announcement.
class _HomeAnnouncement extends StatefulWidget {
  final HomeViewModel viewModel;
  const _HomeAnnouncement({required this.viewModel});

  @override
  State<_HomeAnnouncement> createState() => _HomeAnnouncementState();
}

class _HomeAnnouncementState extends State<_HomeAnnouncement> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return StreamBuilder<String?>(
      stream: widget.viewModel.homeAnnouncement,
      builder: (context, snapshot) {
        final message = snapshot.data?.trim() ?? '';
        if (message.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          decoration: BoxDecoration(
            color: AppColors.secondaryVeryLight.withAlpha(110),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.secondary.withAlpha(40)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.campaign_outlined,
                  size: 18, color: AppColors.secondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.crimsonPro(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppColors.primaryVeryDark,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _dismissed = true),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close,
                      size: 16,
                      color: AppColors.primaryVeryDark.withAlpha(140)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
