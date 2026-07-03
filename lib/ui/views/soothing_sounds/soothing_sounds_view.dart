import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/views/soothing_sounds/sound_track_card.dart';
import 'package:you_app/ui/views/soothing_sounds/soothing_sounds_viewmodel.dart';

class SoothingSoundsView extends StatefulWidget {
  const SoothingSoundsView({Key? key}) : super(key: key);

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
      end: AppColors.secondary.withOpacity(0.8),
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
                            .withOpacity(0.4),
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
                            .withOpacity(0.3),
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
                        color: AppColors.secondaryVeryLight.withOpacity(0.2),
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
                          Expanded(
                            child: ListView.builder(
                              scrollDirection: Axis.vertical,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24.0),
                              itemCount: viewModel.soundTracks.length,
                              itemBuilder: (context, index) {
                                final track = viewModel.soundTracks[index];
                                return SoundTrackCard(
                                  track: track,
                                  isPlaying: viewModel.isPlayingTrack(track.id),
                                  positionStream: viewModel.positionStream,
                                  durationStream: viewModel.durationStream,
                                  onPlayPause: () => viewModel.togglePlayPause(
                                      track.id, track.audioAsset),
                                  onSkipBackward: viewModel.skipBackward,
                                  onSkipForward: viewModel.skipForward,
                                );
                              },
                            ),
                          ),
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
}
