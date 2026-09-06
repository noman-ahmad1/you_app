import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:you_app/ui/common/animation_decoder.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/custom_lottie_loader.dart';
import 'package:you_app/ui/views/new_journal_entry/journal_entry_tabs/journal_save_row.dart';
import 'package:you_app/ui/views/new_journal_entry/new_journal_entry_viewmodel.dart';

/// The voice-journal form (title + recorder panel + save row). Records a short
/// clip that gets uploaded on save; supports a play/pause preview and re-record.
class VoiceJournalEntryView extends StatelessWidget {
  final NewJournalEntryViewModel viewModel;
  const VoiceJournalEntryView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            viewModel.isEditing ? 'Edit Entry' : 'New Voice Entry',
            textAlign: TextAlign.center,
            style: GoogleFonts.crimsonPro(
                fontSize: 25,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary),
          ),
          Space.verticalSpaceTiny(context),
          ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                width: width * 0.9,
                height: height * 0.7,
                decoration: BoxDecoration(
                  color: AppColors.secondaryVeryLight.withAlpha(102),
                  border: Border.all(color: AppColors.secondary, width: 2),
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
                    Text(
                      'Say what’s on your mind.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.crimsonPro(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary),
                    ),
                    Space.verticalSpaceVTiny(context),
                    // Title
                    ClipRRect(
                      borderRadius: BorderRadius.circular(23),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
                        child: Container(
                          padding: EdgeInsets.all(width * 0.007),
                          width: width * 0.8,
                          height: height * 0.065,
                          decoration: BoxDecoration(
                            color: AppColors.background.withAlpha(200),
                            border: Border.all(
                                color: AppColors.background, width: 2),
                            borderRadius: BorderRadius.circular(23),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(25),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: viewModel.titleController,
                            cursorColor: AppColors.secondary,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Title',
                              hintStyle: GoogleFonts.crimsonPro(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary.withAlpha(150)),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Space.verticalSpaceVTiny(context),
                    // Recorder panel
                    Expanded(
                      child: _RecorderPanel(viewModel: viewModel),
                    ),
                    Space.verticalSpaceVTiny(context),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: JournalSaveRow(viewModel: viewModel),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The interactive recording area — idle / recording (live + paused) / captured
/// preview states. The live recording view mirrors a dedicated voice-recorder:
/// a status pill, a large timer, an animated waveform, and discard / pause /
/// accept controls.
class _RecorderPanel extends StatelessWidget {
  final NewJournalEntryViewModel viewModel;
  const _RecorderPanel({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return ClipRRect(
      borderRadius: BorderRadius.circular(23),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
        child: Container(
          width: width * 0.8,
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
          child: _content(context),
        ),
      ),
    );
  }

  // The recorder view covers every phase — idle, live, paused and captured —
  // with one composition, so the discard / center / accept trio never shifts.
  Widget _content(BuildContext context) {
    final session =
        viewModel.isRecording; // a take is in progress (live/paused)
    final live = viewModel.isRecordingLive;
    final captured = !session && viewModel.hasAudio; // accepted / existing clip
    final active = session || captured; // something exists → side actions on

    final busy = viewModel.isBusy; // saving / uploading the clip
    final processing =
        viewModel.isProcessing; // start/stop transition in flight
    final locked = busy || processing; // controls inert while either is true

    // Center: re-record (refresh) once captured, else mic/pause. Shows a spinner
    // while a transition is resolving so a tap always gives instant feedback.
    final String centerAsset = captured
        ? AppConstants.refresh
        : (!session
            ? AppConstants.mic
            : (live ? AppConstants.pause : AppConstants.mic));
    final VoidCallback centerAction = captured || !session
        ? viewModel.startRecording
        : (live ? viewModel.pauseRecording : viewModel.resumeRecording);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statusPill(
              session: session, live: live, captured: captured, busy: busy),
          Text(
            viewModel.durationLabel,
            style: GoogleFonts.crimsonPro(
              fontSize: 42,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
              letterSpacing: 1,
            ),
          ),
          // Animated wave while capturing; a still, flat line otherwise.
          SizedBox(
            height: 56,
            width: double.infinity,
            child: live
                ? Lottie.asset(
                    AppConstants.wave,
                    decoder: customDecoder,
                    fit: BoxFit.fill,
                    repeat: true,
                  )
                : const Center(child: _FlatWave()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Discard / accept are only meaningful once a take exists, and go
              // inert while saving or mid-transition.
              _sideButton(
                asset: AppConstants.cancel,
                onTap: viewModel.discardRecording,
                enabled: active && !locked,
              ),
              _centerButton(
                asset: centerAsset,
                busy: processing,
                onTap: locked ? null : centerAction,
              ),
              _sideButton(
                asset: AppConstants.tick,
                onTap: viewModel.acceptRecording,
                enabled: active && !locked,
              ),
            ],
          ),
          Text(
            busy
                ? 'Saving your voice…'
                : 'Speak freely — this stays between you and you.',
            textAlign: TextAlign.center,
            style: GoogleFonts.crimsonPro(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: AppColors.secondary.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }

  // ● RECORDING / ● PAUSED / SAVING…, or a gentle prompt when idle / captured.
  Widget _statusPill({
    required bool session,
    required bool live,
    required bool captured,
    required bool busy,
  }) {
    final String label;
    if (busy) {
      label = 'SAVING…';
    } else if (session) {
      label = live ? 'RECORDING' : 'PAUSED';
    } else if (captured) {
      label = 'TAP TO RE-RECORD';
    } else {
      label = 'TAP TO RECORD';
    }
    final textColor = busy
        ? AppColors.secondary
        : (!session
            ? AppColors.secondary.withAlpha(150)
            : (live ? AppColors.secondaryLight : AppColors.secondary));
    final dotColor = (session && !busy)
        ? AppColors.red
        : AppColors.secondary.withAlpha(busy ? 200 : 90);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.crimsonPro(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // Light, bordered side action (cancel / tick). Dimmed + inert until a take
  // exists, so the trio can show from the start without misfiring.
  Widget _sideButton({
    required String asset,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(60),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.background,
            border: Border.all(
                color: AppColors.secondary.withAlpha(70), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              asset,
              width: 22,
              height: 22,
              color: AppColors.secondary,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  // Filled primary action (mic / pause / refresh). Renders a spinner while
  // [busy], and goes inert + dimmed when [onTap] is null.
  Widget _centerButton({
    required String asset,
    bool busy = false,
    required VoidCallback? onTap,
    double size = 84,
  }) {
    // Keyed so the AnimatedSwitcher pops the new glyph in whenever it changes
    // (mic ↔ pause ↔ refresh ↔ spinner).
    final Widget glyph = busy
        ? CustomLottieLoader(
            key: const ValueKey('busy'),
            width: size * 0.72,
            height: size * 0.72,
            loaderWidth: size * 2.6,
            loaderHeight: size * 2.6,
          )
        : Image.asset(
            asset,
            key: ValueKey<String>(asset),
            width: size * 0.4,
            height: size * 0.4,
            color: AppColors.background,
            fit: BoxFit.contain,
          );
    // Dim when disabled (but not while busy — the spinner already reads as
    // active).
    final disabled = onTap == null && !busy;
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.secondary,
            border: Border.all(color: AppColors.background, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withAlpha(90),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: glyph,
            ),
          ),
        ),
      ),
    );
  }
}

/// A static, evenly-spaced tick line shown when idle or paused (the resting
/// counterpart to the animated wave.lottie).
class _FlatWave extends StatelessWidget {
  const _FlatWave();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          46,
          (_) => Container(
            width: 2.5,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(120),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}
