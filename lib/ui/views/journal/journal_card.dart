import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/shared/custom_lottie_loader.dart';

class JournalCard extends StatelessWidget {
  final String category;
  final String title;
  final String description;
  final String date;
  final bool showEdit;
  final bool isVoice;
  final String? durationLabel;
  final String? audioUrl;
  final VoidCallback? onEditTap;
  final VoidCallback onTap;

  const JournalCard({
    super.key,
    required this.category,
    required this.title,
    required this.description,
    required this.date,
    this.showEdit = true,
    this.isVoice = false,
    this.durationLabel,
    this.audioUrl,
    this.onEditTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return InkWell(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
          child: Container(
            padding: const EdgeInsets.all(10),
            width: width * 0.9,
            height: height * 0.195,
            decoration: BoxDecoration(
              color: AppColors.background.withAlpha(200),
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
              children: [
                // Row with Category + Edit button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _blurChip(
                      text: category,
                      width: width * 0.2,
                      height: height * 0.03,
                    ),
                    if (showEdit)
                      GestureDetector(
                        onTap: onEditTap,
                        child: _blurIcon(
                          width: width * 0.07,
                          height: height * 0.03,
                          child: Image.asset(
                            AppConstants.edit,
                            width: width * 0.05,
                            height: height * 0.018,
                            fit: BoxFit.contain,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                  ],
                ),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.crimsonPro(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),

                // Description — text preview, or a playable voice-note pill.
                if (isVoice)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: VoiceNotePill(
                      audioUrl: audioUrl,
                      durationLabel: durationLabel ?? '0:00',
                    ),
                  )
                else
                  Text(
                    description,
                    textAlign: TextAlign.left,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.crimsonPro(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryVeryDark,
                    ),
                  ),
                SizedBox(height: 5),
                // Date chip
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: _blurChip(
                      text: date,
                      width: width * 0.35,
                      height: height * 0.03,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _blurChip({
    required String text,
    required double width,
    required double height,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(35),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.secondaryVeryLight.withAlpha(200),
            border: Border.all(color: AppColors.secondaryVeryLight, width: 2),
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
              text,
              style: GoogleFonts.crimsonPro(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _blurIcon({
    required double width,
    required double height,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.secondaryVeryLight.withAlpha(102),
            border: Border.all(color: AppColors.secondaryVeryLight, width: 2),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// A WhatsApp-style playable voice-note pill: a maroon play/pause button, a
/// gradient waveform, and the clip duration. Plays [audioUrl] inline with a
/// lazily-created player so list scrolling stays cheap.
class VoiceNotePill extends StatefulWidget {
  final String? audioUrl;
  final String durationLabel;
  const VoiceNotePill({
    super.key,
    required this.audioUrl,
    required this.durationLabel,
  });

  @override
  State<VoiceNotePill> createState() => _VoiceNotePillState();
}

class _VoiceNotePillState extends State<VoiceNotePill> {
  AudioPlayer? _player;
  bool _isPlaying = false;
  bool _isLoading = false;
  late final Duration _total = _parseLabel(widget.durationLabel);

  /// Lazily build the player and wire a single state listener that keeps the
  /// button (play / pause / loading) in sync.
  AudioPlayer _ensurePlayer() {
    return _player ??= AudioPlayer()
      ..playerStateStream.listen((state) {
        if (!mounted) return;
        if (state.processingState == ProcessingState.completed) {
          _player?.seek(Duration.zero);
          _player?.pause();
        }
        setState(() {
          _isLoading = state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;
          _isPlaying = state.playing &&
              state.processingState != ProcessingState.completed;
        });
      });
  }

  Future<void> _toggle() async {
    if (widget.audioUrl == null) return;
    final player = _ensurePlayer();
    try {
      if (player.processingState == ProcessingState.idle) {
        setState(() => _isLoading = true);
        await player.setUrl(widget.audioUrl!);
      }
      if (player.playing) {
        await player.pause();
      } else {
        await player.play();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPlaying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightPink.withAlpha(110),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
            color: AppColors.secondaryVeryLight.withAlpha(120), width: 1),
      ),
      child: Row(
        children: [
          // Play / pause / loading
          GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary,
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _buttonChild(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: _WaveBars()),
          const SizedBox(width: 10),
          _timeLabel(),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buttonChild() {
    if (_isLoading) {
      return const CustomLottieLoader(
        key: ValueKey('loading'),
        width: 24,
        height: 24,
        loaderWidth: 90,
        loaderHeight: 90,
      );
    }
    return Image.asset(
      _isPlaying ? AppConstants.pause : AppConstants.play,
      key: ValueKey(_isPlaying),
      width: 15,
      height: 15,
      color: AppColors.background,
      fit: BoxFit.contain,
    );
  }

  /// Counts down the remaining time while playing; shows the full length at rest.
  Widget _timeLabel() {
    final player = _player;
    final style = GoogleFonts.crimsonPro(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.secondary.withAlpha(180),
    );
    if (player == null) {
      return Text(_fmt(_total), style: style);
    }
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snapshot) {
        final total = player.duration ?? _total;
        final pos = snapshot.data ?? Duration.zero;
        Duration remaining = total - pos;
        if (remaining.isNegative) remaining = Duration.zero;
        final atRest = !_isPlaying && pos == Duration.zero;
        return Text(_fmt(atRest ? total : remaining), style: style);
      },
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static Duration _parseLabel(String s) {
    final parts = s.split(':');
    if (parts.length == 2) {
      return Duration(
        minutes: int.tryParse(parts[0].trim()) ?? 0,
        seconds: int.tryParse(parts[1].trim()) ?? 0,
      );
    }
    return Duration.zero;
  }
}

/// Decorative waveform: fixed-height bars tinted along a maroon→pink gradient.
class _WaveBars extends StatelessWidget {
  const _WaveBars();

  // Normalized bar heights — a fixed, natural-looking pattern.
  static const List<double> _bars = [
    0.35, 0.6, 0.45, 0.8, 0.55, 0.95, 0.5, 0.7, 0.4, 0.85, 0.6, 1.0, //
    0.55, 0.75, 0.45, 0.65, 0.5, 0.9, 0.6, 0.8, 0.4, 0.72, 0.5, 0.62,
  ];
  static const double _maxHeight = 24;

  @override
  Widget build(BuildContext context) {
    final n = _bars.length;
    return SizedBox(
      height: _maxHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int i = 0; i < n; i++)
            Container(
              width: 2.5,
              height: math.max(4, _bars[i] * _maxHeight),
              decoration: BoxDecoration(
                color: Color.lerp(
                    AppColors.secondary, AppColors.pink, i / (n - 1)),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}
