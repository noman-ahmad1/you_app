import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/views/mood_tracker/mood_tracker_viewmodel.dart';

class AnimatedMoodScreen extends StatefulWidget {
  final String emoji;
  const AnimatedMoodScreen({super.key, required this.emoji});

  @override
  State<AnimatedMoodScreen> createState() => _AnimatedMoodScreenState();
}

class _AnimatedMoodScreenState extends State<AnimatedMoodScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;

  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Fixed scale animation - no TweenSequence, using safe curves
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.4).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.bounceOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _rotateAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Start animation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return ViewModelBuilder<MoodTrackerViewModel>.reactive(
      viewModelBuilder: () => MoodTrackerViewModel(),
      onModelReady: (viewModel) {
        if (!_isDisposed && mounted) {
          viewModel.init(() async {
            if (!_isDisposed && mounted) {
              try {
                await _controller.reverse();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                debugPrint("Error during animation reverse: $e");
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            }
          }, screenSize);
        }
      },
      builder: (context, viewModel, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.withOpacity(0.8),
                  Colors.blueAccent.withOpacity(0.6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                // Background Painter
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) => CustomPaint(
                      painter: _BackgroundPainter(animation: _controller),
                    ),
                  ),
                ),

                // Particles
                if (viewModel.particles.isNotEmpty)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ParticlePainter(viewModel.particles),
                    ),
                  ),

                // Main Content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Text(
                            "Mood Updated!",
                            style: GoogleFonts.crimsonPro(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: AppColors.background),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      AnimatedBuilder(
                        animation: _rotateAnimation,
                        builder: (context, child) => Transform.rotate(
                          angle: _rotateAnimation.value,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.2),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: _buildEmojiWidget(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: 200,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 1.0, end: 0.0),
                          duration: viewModel.autoCloseDuration,
                          builder: (context, value, child) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: value,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmojiWidget() {
    // Handle both asset path and direct emoji
    if (widget.emoji.contains('/') || widget.emoji.contains('.')) {
      // It's an asset path
      return Image.asset(
        widget.emoji,
        width: 100,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to text emoji if asset fails
          return const Text(
            '😊', // default emoji
            style: TextStyle(fontSize: 100),
          );
        },
      );
    } else {
      // It's a text emoji
      return Text(
        widget.emoji,
        style: const TextStyle(fontSize: 100),
      );
    }
  }
}

// ----------------- Painters -----------------
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return;

    final paint = Paint();
    for (var p in particles) {
      if (p.life > 0) {
        // Safety check
        paint.color =
            Colors.white.withOpacity(0.7 * (p.life / 30).clamp(0.0, 1.0));
        canvas.drawCircle(
            Offset(p.x.clamp(0, size.width), p.y.clamp(0, size.height)),
            (p.size / 2).clamp(0.5, 10.0),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) =>
      particles.length != oldDelegate.particles.length;
}

class _BackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  _BackgroundPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return; // Safety check

    final animValue = animation.value.clamp(0.0, 1.0);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.purpleAccent.withOpacity(0.2 * animValue),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: (size.width * 0.6 * animValue).clamp(0.0, size.width),
      ));

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      (size.width * 0.6 * animValue).clamp(0.0, size.width),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) => true;
}
