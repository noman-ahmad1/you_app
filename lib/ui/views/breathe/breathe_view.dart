import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/widgets.dart';
import 'package:you_app/ui/views/breathe/breathe_viewmodel.dart';

class BreatheView extends StatefulWidget {
  const BreatheView({Key? key}) : super(key: key);

  @override
  State<BreatheView> createState() => _BreatheViewState();
}

class _BreatheViewState extends State<BreatheView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Default duration; will be overridden by the phase logic
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPhaseChanged(BreathePhase newPhase) {
    switch (newPhase) {
      case BreathePhase.inhale:
        _animationController.duration = const Duration(seconds: 4);
        _animationController.forward(from: 0.0);
        break;
      case BreathePhase.hold:
        // Keep it at full size (1.0), do nothing
        break;
      case BreathePhase.exhale:
        _animationController.duration = const Duration(seconds: 8);
        _animationController.reverse(from: 1.0);
        break;
      case BreathePhase.idle:
        _animationController.duration = const Duration(milliseconds: 500);
        _animationController.reverse(); // animate back to 0.5 smoothly
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<BreatheViewModel>.reactive(
      viewModelBuilder: () => BreatheViewModel(),
      onViewModelReady: (viewModel) {
        // We will listen to viewmodel changes to trigger animations
      },
      builder: (context, viewModel, child) {
        // In a real reactive architecture, we want to trigger the animation
        // when the phase changes. Since ViewModelBuilder rebuilds on notifyListeners,
        // we can check if the phase has changed.
        // A cleaner way is doing this through an event or checking state diff.
        // For simplicity in build, we can use a helper or state variable.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // If we track the last phase to trigger animations:
          // We can maintain _lastPhase in state.
        });

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
              'Breathe',
              style: GoogleFonts.crimsonPro(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryVeryDark,
                  AppColors.primaryDark,
                ],
              ),
            ),
            child: _BreatheAnimationContent(
              viewModel: viewModel,
              animationController: _animationController,
              scaleAnimation: _scaleAnimation,
              onPhaseChanged: _onPhaseChanged,
            ),
          ),
        );
      },
    );
  }
}

class _BreatheAnimationContent extends StatefulWidget {
  final BreatheViewModel viewModel;
  final AnimationController animationController;
  final Animation<double> scaleAnimation;
  final Function(BreathePhase) onPhaseChanged;

  const _BreatheAnimationContent({
    Key? key,
    required this.viewModel,
    required this.animationController,
    required this.scaleAnimation,
    required this.onPhaseChanged,
  }) : super(key: key);

  @override
  State<_BreatheAnimationContent> createState() =>
      _BreatheAnimationContentState();
}

class _BreatheAnimationContentState extends State<_BreatheAnimationContent> {
  BreathePhase _lastPhase = BreathePhase.idle;

  @override
  void didUpdateWidget(covariant _BreatheAnimationContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.viewModel.currentPhase != _lastPhase) {
      _lastPhase = widget.viewModel.currentPhase;
      widget.onPhaseChanged(_lastPhase);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: widget.animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: widget.scaleAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.secondary.withOpacity(0.8),
                        AppColors.primaryLight.withOpacity(0.4),
                        Colors.transparent,
                      ],
                      stops: const [0.2, 0.7, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: Center(
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 200,
                          height: 200,
                          color: Colors.white.withOpacity(0.1),
                          child: Center(
                            child: widget.viewModel.isActive
                                ? Text(
                                    '${widget.viewModel.secondsRemaining}',
                                    style: GoogleFonts.crimsonPro(
                                      fontSize: 64,
                                      fontWeight: FontWeight.w200,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    Icons.play_arrow_rounded,
                                    size: 64,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 100.0),
            child: Column(
              children: [
                Text(
                  widget.viewModel.instructionText,
                  style: GoogleFonts.crimsonPro(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                Space.verticalSpaceTiny(context),
                Text(
                  widget.viewModel.isActive
                      ? '4-7-8 Breathing Technique'
                      : 'Take a moment to focus on your breath. Inhale for 4s, hold for 7s, exhale for 8s.',
                  style: GoogleFonts.crimsonPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                Space.verticalSpaceSmall(context),
                CustomButton(
                  text: widget.viewModel.isActive ? 'Stop' : 'Start',
                  onPressed: widget.viewModel.toggleBreathing,
                  backgroundColor: AppColors.secondary,
                ),
                // InkWell(
                //   onTap: widget.viewModel.toggleBreathing,
                //   borderRadius: BorderRadius.circular(30),
                //   child: Container(
                //     padding: const EdgeInsets.symmetric(
                //         horizontal: 40, vertical: 16),
                //     decoration: BoxDecoration(
                //       color: AppColors.secondary,
                //       borderRadius: BorderRadius.circular(30),
                //       boxShadow: [
                //         BoxShadow(
                //           color: AppColors.secondary.withOpacity(0.3),
                //           blurRadius: 10,
                //           offset: const Offset(0, 5),
                //         ),
                //       ],
                //     ),
                //     child: Text(
                //       widget.viewModel.isActive ? 'Stop' : 'Start',
                //       style: GoogleFonts.crimsonPro(
                //         color: Colors.white,
                //         fontSize: 18,
                //         fontWeight: FontWeight.w600,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
