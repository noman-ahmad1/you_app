import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/models/sound_track.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';

class SoundTrackCard extends StatelessWidget {
  final SoundTrack track;
  final bool isPlaying;
  final Stream<Duration> positionStream;
  final Stream<Duration?> durationStream;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipBackward;
  final VoidCallback onSkipForward;

  const SoundTrackCard({
    Key? key,
    required this.track,
    required this.isPlaying,
    required this.positionStream,
    required this.durationStream,
    required this.onPlayPause,
    required this.onSkipBackward,
    required this.onSkipForward,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
          child: Container(
            width: double.infinity,
            height: height * 0.22,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(track.imageAsset),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withAlpha(80),
                  BlendMode.darken,
                ),
              ),
              color: AppColors.secondaryVeryLight.withAlpha(102),
              border: Border.all(color: AppColors.background, width: 2),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Info Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        style: GoogleFonts.crimsonPro(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        track.subtitle,
                        style: GoogleFonts.crimsonPro(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Controls & Progress
                Column(
                  children: [
                    // Controls Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: onSkipBackward,
                            child: Image.asset(
                              AppConstants.backward,
                              color: Colors.white,
                              width: width * 0.07,
                              height: height * 0.025,
                              fit: BoxFit.contain,
                            ),
                          ),
                          Space.horizontalSpaceVTiny(context),
                          InkWell(
                            onTap: onPlayPause,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isPlaying
                                    ? AppColors.secondary
                                    : Colors.white24,
                              ),
                              child: Image.asset(
                                isPlaying
                                    ? AppConstants.pause
                                    : AppConstants.play,
                                color: Colors.white,
                                width: width * 0.05,
                                height: height * 0.025,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Space.horizontalSpaceVTiny(context),
                          InkWell(
                            onTap: onSkipForward,
                            child: Image.asset(
                              AppConstants.forward,
                              color: Colors.white,
                              width: width * 0.07,
                              height: height * 0.025,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Space.verticalSpaceVTiny(context),
                    // Progress Bar
                    StreamBuilder<Duration?>(
                      stream: durationStream,
                      builder: (context, durationSnapshot) {
                        final duration = durationSnapshot.data ?? Duration.zero;

                        return StreamBuilder<Duration>(
                          stream: positionStream,
                          builder: (context, positionSnapshot) {
                            var position =
                                positionSnapshot.data ?? Duration.zero;

                            if (position > duration) {
                              position = duration;
                            }

                            double progress = 0.0;
                            if (duration.inMilliseconds > 0 && isPlaying) {
                              progress = position.inMilliseconds /
                                  duration.inMilliseconds;
                            }

                            return Container(
                              height: 4,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white30,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progress.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
