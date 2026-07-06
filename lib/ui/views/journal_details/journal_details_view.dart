import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/models/journal_model.dart';
import 'package:you_app/ui/common/animation_decoder.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/topbar.dart';

import 'journal_details_viewmodel.dart';

class JournalDetailsView extends StackedView<JournalDetailsViewModel> {
  final JournalEntry journalEntry;
  const JournalDetailsView({
    Key? key,
    required this.journalEntry,
  }) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    JournalDetailsViewModel viewModel,
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
              // mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TopBar(
                  leadingIconAsset: AppConstants.back, // Your 'Y' logo asset
                  onLeadingPressed: () {
                    Navigator.pop(context);
                  },
                  title: 'Journal Details',
                  subtitle: DateFormat('EEEE, MMMM d').format(DateTime.now()),
                  trailingActions: [
                    // Icon 1 (e.g., Notifications)
                    // InkWell(
                    //   onTap: () {},
                    //   child: Container(
                    //     padding: const EdgeInsets.all(8),
                    //     decoration: BoxDecoration(
                    //       shape: BoxShape.circle,
                    //       border: Border.all(
                    //           color: AppColors.primaryVeryDark.withAlpha(50)),
                    //     ),
                    //     child: Icon(Icons.notifications_none,
                    //         color: AppColors.primaryVeryDark),
                    //   ),
                    // ),
                    // // Icon 2 (e.g., Profile/Flower)
                    // InkWell(
                    //   onTap: () {},
                    //   child: Container(
                    //     padding: const EdgeInsets.all(4),
                    //     decoration: BoxDecoration(
                    //       shape: BoxShape.circle,
                    //       border: Border.all(
                    //           color: AppColors.primaryVeryDark.withAlpha(50)),
                    //     ),
                    //     child: Image.asset('assets/images/avatar.png',
                    //         width: 24, height: 24),
                    //   ),
                    // ),
                  ],
                ),
                Space.verticalSpaceSmall(context),
                ClipRRect(
                  borderRadius: BorderRadius.circular(23),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                      width: width * 0.9,
                      height: height * 0.7,
                      decoration: BoxDecoration(
                        color: AppColors.background.withAlpha(200),
                        border:
                            Border.all(color: AppColors.background, width: 2),
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
                                  viewModel.deleteEntry();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 200, sigmaY: 200),
                                      child: Container(
                                        padding: EdgeInsets.all(width * 0.007),
                                        width: width * 0.085,
                                        height: height * 0.038,
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryVeryLight
                                              .withAlpha(102),
                                          border: Border.all(
                                              color: AppColors.secondary,
                                              width: 2),
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withAlpha(25),
                                              blurRadius: 20,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Image.asset(
                                            AppConstants.delete,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Space.horizontalSpaceMedium(context),
                              Text(
                                'Entry',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.crimsonPro(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary),
                              ),
                              Space.horizontalSpaceTiny(context),
                              Space.horizontalSpaceVTiny(context),
                              Text(
                                viewModel.date,
                                style: GoogleFonts.crimsonPro(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primaryVeryDark),
                              ),
                            ],
                          ),
                          Space.verticalSpaceVTiny(context),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(23),
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 200, sigmaY: 200),
                              child: Container(
                                padding: EdgeInsets.all(width * 0.007),
                                width: width * 0.8,
                                height: height * 0.065,
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryVeryLight
                                      .withAlpha(102),
                                  border: Border.all(
                                      color: AppColors.secondary, width: 2),
                                  borderRadius: BorderRadius.circular(23),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(25),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    viewModel.entry.title,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.crimsonPro(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.secondary),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Space.verticalSpaceVTiny(context),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(23),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 200, sigmaY: 200),
                                child: Container(
                                  padding: EdgeInsets.all(width * 0.007),
                                  width: width * 0.8,
                                  // height: height * 0.45,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryVeryLight
                                        .withAlpha(102),
                                    border: Border.all(
                                        color: AppColors.secondary, width: 2),
                                    borderRadius: BorderRadius.circular(23),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(25),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(7.0),
                                    child: viewModel.isVoice
                                        ? _VoicePlayer(viewModel: viewModel)
                                        : Text(
                                            viewModel.entry.content,
                                            style: GoogleFonts.crimsonPro(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    AppColors.primaryVeryDark),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Space.verticalSpaceVTiny(context),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(35),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 200, sigmaY: 200),
                                    child: Container(
                                      padding: EdgeInsets.all(width * 0.007),
                                      width: width * 0.25,
                                      height: height * 0.065,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withAlpha(102),
                                        border: Border.all(
                                            color: AppColors.primaryVeryDark,
                                            width: 2),
                                        borderRadius: BorderRadius.circular(35),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(25),
                                            blurRadius: 20,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          viewModel
                                              .category, // Capitalizes "personal" or "work"
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.crimsonPro(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primaryVeryDark),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    viewModel.navigateToNewJournalEntry();
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(35),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 200, sigmaY: 200),
                                      child: Container(
                                        padding: EdgeInsets.all(width * 0.007),
                                        width: width * 0.53,
                                        height: height * 0.065,
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryVeryLight
                                              .withAlpha(102),
                                          border: Border.all(
                                              color: AppColors.secondary,
                                              width: 2),
                                          borderRadius:
                                              BorderRadius.circular(35),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withAlpha(25),
                                              blurRadius: 20,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Edit',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.crimsonPro(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.secondary),
                                          ),
                                        ),
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
              ],
            )));
  }

  @override
  JournalDetailsViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      JournalDetailsViewModel(entry: journalEntry);

  @override
  void onViewModelReady(JournalDetailsViewModel viewModel) =>
      viewModel.initAudio();
}

/// Inline audio player for a voice journal entry: a play/pause button, an
/// animated waveform that comes alive while playing, and a countdown time.
class _VoicePlayer extends StatelessWidget {
  final JournalDetailsViewModel viewModel;
  const _VoicePlayer({required this.viewModel});

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final playing = viewModel.isPlaying;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: viewModel.togglePlay,
            borderRadius: BorderRadius.circular(80),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary,
                border: Border.all(color: AppColors.background, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: Image.asset(
                    playing ? AppConstants.pause : AppConstants.play,
                    key: ValueKey(playing),
                    width: 30,
                    height: 30,
                    color: AppColors.background,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          // The waveform animates while playing and rests on a still frame when
          // paused — replaces the old progress slider.
          SizedBox(
            height: 64,
            width: double.infinity,
            child: Lottie.asset(
              AppConstants.wave,
              decoder: customDecoder,
              animate: playing,
              repeat: true,
              fit: BoxFit.fill,
            ),
          ),
          const SizedBox(height: 18),
          StreamBuilder<Duration>(
            stream: viewModel.positionStream,
            builder: (context, snapshot) {
              final total = viewModel.totalDuration;
              final pos = snapshot.data ?? Duration.zero;
              Duration remaining = total - pos;
              if (remaining.isNegative) remaining = Duration.zero;
              final atRest = !playing && pos == Duration.zero;
              return Text(
                _fmt(atRest ? total : remaining),
                style: GoogleFonts.crimsonPro(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
