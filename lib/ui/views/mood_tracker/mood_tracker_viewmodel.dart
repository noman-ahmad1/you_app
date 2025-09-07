import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/views/mood_tracker/animated_mood.dart';

class MoodTrackerViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final AudioPlayer _fxPlayer = AudioPlayer();

  bool swiped = false;
  final List<Particle> particles = [];
  final Random _random = Random();

  Ticker? _ticker; // Make it nullable and initialize properly
  bool _isDisposed = false; // Track disposal state

  final Duration autoCloseDuration = const Duration(seconds: 4);

  Future<void> _initFxPlayer() async {
    try {
      await _fxPlayer.setLoopMode(LoopMode.off);
    } catch (e) {
      debugPrint("Error initializing FX player: $e");
    }
  }

  MoodTrackerViewModel() {
    _initFxPlayer();
  }

  void init(VoidCallback onAutoClose, Size screenSize) {
    if (_isDisposed) return; // Prevent initialization after disposal

    // Start auto close after 4s
    Future.delayed(autoCloseDuration, () {
      if (!_isDisposed) {
        onAutoClose();
      }
    });

    // Initialize and start ticker
    _ticker = Ticker((elapsed) {
      if (!_isDisposed) {
        _updateParticles(screenSize);
        notifyListeners();
      }
    });

    _ticker?.start();
  }

  void _updateParticles(Size screenSize) {
    if (_isDisposed) return;

    // Move and remove old particles
    for (var i = particles.length - 1; i >= 0; i--) {
      if (i < particles.length) {
        // Safety check
        particles[i].update();
        if (particles[i].life <= 0) {
          particles.removeAt(i);
        }
      }
    }

    // Randomly add new particles (limit total count to prevent memory issues)
    if (_random.nextDouble() < 0.2 && particles.length < 50) {
      particles.add(
        Particle(
          x: _random.nextDouble() * screenSize.width,
          y: _random.nextDouble() * screenSize.height,
          size: _random.nextDouble() * 4 + 2,
          speed: _random.nextDouble() * 2 + 1,
          angle: _random.nextDouble() * 2 * pi,
          life: _random.nextDouble() * 20 + 10,
        ),
      );
    }
  }

  Future<void> playSwipeSound({bool isComplete = false}) async {
    if (_isDisposed) return;

    try {
      final soundPath = isComplete ? AppConstants.drop : '';
      if (soundPath.isEmpty) return;

      await _fxPlayer.stop();
      await _fxPlayer.setAsset(soundPath);
      await _fxPlayer.play();

      if (!_isDisposed) {
        swiped = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  Future<void> onEmojiSelected(String emoji) async {
    if (_isDisposed) return;

    try {
      // 1. Haptic feedback
      HapticFeedback.mediumImpact();

      // 2. Play sound
      playSwipeSound(isComplete: true);

      // 3. Navigate
      _navigationService.navigateWithTransition(
        AnimatedMoodScreen(emoji: emoji),
        transition: 'fade',
        duration: const Duration(milliseconds: 1000),
      );
    } catch (e) {
      debugPrint("Failed to handle emoji selection: $e");
    }
  }

  Future<void> back() async {
    if (!_isDisposed) {
      await _navigationService.back();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    // Stop and dispose ticker
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;

    // Clear particles
    particles.clear();

    // Dispose audio player
    _fxPlayer.dispose();

    super.dispose();
  }
}

class Particle {
  double x, y;
  double size;
  double speed;
  double angle;
  double life;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
    required this.life,
  });

  void update() {
    x += cos(angle) * speed;
    y += sin(angle) * speed;
    life--;
  }
}
