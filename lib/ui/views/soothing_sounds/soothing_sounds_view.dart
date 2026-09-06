import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/skeleton.dart';
import 'package:you_app/ui/views/soothing_sounds/sound_track_card.dart';
import 'package:you_app/ui/views/soothing_sounds/soothing_sounds_viewmodel.dart';

class SoothingSoundsView extends StatefulWidget {
  const SoothingSoundsView({super.key});

  @override
  State<SoothingSoundsView> createState() => _SoothingSoundsViewState();
}

class _SoothingSoundsViewState extends State<SoothingSoundsView>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimController;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _color1 = ColorTween(
      begin: AppColors.primaryVeryDark,
      end: AppColors.secondary.withValues(alpha: 0.8),
    ).animate(CurvedAnimation(
      parent: _bgAnimController,
      curve: Curves.easeInOutSine,
    ));

    _color2 = ColorTween(
      begin: AppColors.secondary,
      end: AppColors.primaryLight,
    ).animate(CurvedAnimation(
      parent: _bgAnimController,
      curve: Curves.easeInOutSine,
    ));
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SoothingSoundsViewModel>.reactive(
      viewModelBuilder: () => SoothingSoundsViewModel(),
      builder: (context, viewModel, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Image.asset(
                AppConstants.back,
                color: Colors.white,
                width: 24,
                height: 24,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Soothing Sounds',
              style: GoogleFonts.crimsonPro(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: AnimatedBuilder(
            animation: _bgAnimController,
            builder: (context, child) {
              return Stack(
                children: [
                  // Base dark gradient
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryVeryDark,
                          AppColors.primaryDark,
                        ],
                      ),
                    ),
                  ),
                  // Animated blurred blob 1
                  Positioned(
                    top: -100 + (50 * _bgAnimController.value),
                    left: -50,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (_color1.value ?? AppColors.secondary)
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  // Animated blurred blob 2
                  Positioned(
                    bottom: -100 + (50 * (1 - _bgAnimController.value)),
                    right: -50,
                    child: Container(
                      width: 350,
                      height: 350,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (_color2.value ?? AppColors.primaryLight)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  // Animated blurred blob 3
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.4 +
                        (30 * _bgAnimController.value),
                    right: 50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            AppColors.secondaryVeryLight.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  // Full screen blur
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                  // Content
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(
                              "Relax & Breathe",
                              style: GoogleFonts.crimsonPro(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Space.verticalSpaceTiny(context),
                          Expanded(child: _buildBody(context, viewModel)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Sounds are fetched from Firestore, so there are three states to render.
  ///
  /// Offline is mostly a non-event: Firestore replays the list from its own disk
  /// cache, and a sound already played once plays again from the audio cache. The
  /// empty state below is really only reached on a first-ever open with no
  /// network — or when the admin has published nothing yet.
  Widget _buildBody(BuildContext context, SoothingSoundsViewModel viewModel) {
    if (viewModel.isBusy) return const _SoundSkeletonList();

    if (viewModel.hasError || viewModel.sounds.isEmpty) {
      return _EmptyState(
        hasError: viewModel.hasError,
        onRetry: viewModel.retry,
      );
    }

    return ListView.builder(
      scrollDirection: Axis.vertical,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      itemCount: viewModel.sounds.length,
      itemBuilder: (context, index) {
        final track = viewModel.sounds[index];
        return SoundTrackCard(
          track: track,
          isPlaying: viewModel.isPlayingTrack(track.id),
          isLoading: viewModel.isLoadingTrack(track.id),
          isLocked: viewModel.isLocked(track),
          positionStream: viewModel.positionStream,
          durationStream: viewModel.durationStream,
          onPlayPause: () => viewModel.togglePlayPause(track),
          onSkipBackward: viewModel.skipBackward,
          onSkipForward: viewModel.skipForward,
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasError;
  final VoidCallback onRetry;

  const _EmptyState({required this.hasError, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasError ? Icons.cloud_off_rounded : Icons.music_note_rounded,
              color: Colors.white38,
              size: 44,
            ),
            Space.verticalSpaceSmall(context),
            Text(
              hasError
                  ? "We couldn't load your sounds."
                  : 'No sounds here yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.crimsonPro(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Space.verticalSpaceVTiny(context),
            Text(
              hasError
                  ? 'Check your connection and try again.'
                  : 'New soundscapes are on their way — check back soon.',
              textAlign: TextAlign.center,
              style: GoogleFonts.crimsonPro(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
            Space.verticalSpaceSmall(context),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.secondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'Try again',
                style: GoogleFonts.crimsonPro(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// First-load placeholder for the sounds list.
///
/// The sounds (and their cover images) now come from Firestore + Storage, so
/// there's a real gap before the first card can paint. This mirrors the shape of
/// [SoundTrackCard] — same 0.22-of-screen height, same 23px radius, same 24px
/// horizontal padding — so nothing shifts when the real cards arrive.
///
/// It uses the shared [Shimmer] but a DARK card surface: the app's SkeletonCard
/// is tuned for the light background everywhere else, and its white slabs would
/// glare against this screen's dark gradient.
class _SoundSkeletonList extends StatelessWidget {
  const _SoundSkeletonList();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(3, (_) => const _SoundSkeletonCard()),
      ),
    );
  }
}

class _SoundSkeletonCard extends StatelessWidget {
  const _SoundSkeletonCard();

  Widget _box({double? width, double height = 14, double radius = 8}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(46),
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        width: double.infinity,
        height: height * 0.22, // matches SoundTrackCard exactly
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          border: Border.all(color: Colors.white24, width: 2),
          borderRadius: BorderRadius.circular(23),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title + subtitle
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(width: 150, height: 18),
                  const SizedBox(height: 8),
                  _box(width: 90, height: 12),
                ],
              ),
            ),
            // Controls + progress bar
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _box(width: 22, height: 20),
                    const SizedBox(width: 18),
                    _box(width: 44, height: 44, radius: 22),
                    const SizedBox(width: 18),
                    _box(width: 22, height: 20),
                  ],
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: _box(height: 4, radius: 2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
