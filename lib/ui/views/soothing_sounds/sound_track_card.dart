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

  /// The signed URL is being fetched / the stream is buffering (first play only).
  final bool isLoading;

  /// Premium sound, free user → show the lock and route the tap to the paywall.
  final bool isLocked;

  final Stream<Duration> positionStream;
  final Stream<Duration?> durationStream;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipBackward;
  final VoidCallback onSkipForward;

  const SoundTrackCard({
    super.key,
    required this.track,
    required this.isPlaying,
    this.isLoading = false,
    this.isLocked = false,
    required this.positionStream,
    required this.durationStream,
    required this.onPlayPause,
    required this.onSkipBackward,
    required this.onSkipForward,
  });

  /// The cover, which now streams from Cloud Storage rather than the bundle.
  ///
  /// Rendered as a widget (not a `DecorationImage`) so it can FADE IN — a
  /// decoration image pops in abruptly the instant the bytes land, which is very
  /// visible on a remote image. Falls back to the bundled placeholder when the
  /// admin hasn't uploaded a cover, or when the download fails.
  Widget _buildCover() {
    if (track.coverPhoto.isEmpty) {
      return Image.asset(
        AppConstants.soothing,
        fit: BoxFit.cover,
        color: Colors.black.withAlpha(80),
        colorBlendMode: BlendMode.darken,
      );
    }
    return Image.network(
      track.coverPhoto,
      fit: BoxFit.cover,
      color: Colors.black.withAlpha(80),
      colorBlendMode: BlendMode.darken,
      // Already-cached frames come back synchronously — don't fade those, or
      // every scroll back into view would re-animate.
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          child: child,
        );
      },
      // Until it arrives (and if it never does), the container's own tint shows
      // through — a muted card, never a broken one.
      errorBuilder: (context, _, __) => Image.asset(
        AppConstants.soothing,
        fit: BoxFit.cover,
        color: Colors.black.withAlpha(80),
        colorBlendMode: BlendMode.darken,
      ),
    );
  }

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
              color: AppColors.secondaryVeryLight.withAlpha(102),
              borderRadius: BorderRadius.circular(23),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            // The border lives in the FOREGROUND decoration, not the background
            // one. A BoxDecoration border paints BEHIND the child, so the cover
            // image was painting straight over it and the card's outline looked
            // clipped away at the corners. Foreground paints it back on top.
            foregroundDecoration: BoxDecoration(
              border: Border.all(color: AppColors.background, width: 2),
              borderRadius: BorderRadius.circular(23),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Rounded to the card's own radius. The Container's borderRadius
                // only shapes its decoration — it does NOT clip children — so
                // without this the cover renders as a hard-cornered rectangle
                // poking out under the rounded card.
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child: _buildCover(),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Info Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  track.title,
                                  style: GoogleFonts.crimsonPro(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isLocked) const _PremiumBadge(),
                            ],
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
                                  child: SizedBox(
                                    width: width * 0.05,
                                    height: height * 0.025,
                                    child: isLoading
                                        // First play: fetching the signed URL and
                                        // buffering the stream.
                                        ? const FittedBox(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : isLocked
                                            ? const FittedBox(
                                                child: Icon(Icons.lock_rounded,
                                                    color: Colors.white),
                                              )
                                            : Image.asset(
                                                isPlaying
                                                    ? AppConstants.pause
                                                    : AppConstants.play,
                                                color: Colors.white,
                                                fit: BoxFit.contain,
                                              ),
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
                            final duration =
                                durationSnapshot.data ?? Duration.zero;

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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The "YOU+" pill on a premium sound a free user can't play yet.
class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, color: Colors.white, size: 11),
          const SizedBox(width: 4),
          Text(
            'YOU+',
            style: GoogleFonts.crimsonPro(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
