import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/views/mood_tracker/animated_mood.dart';

// Import the necessary model and service
import 'package:you_app/services/user_service.dart';
import 'package:you_app/services/volunteer_service.dart';
import 'package:you_app/services/mood_service.dart';
import 'package:you_app/services/journal_service.dart';
import 'package:you_app/services/chat_service.dart';
import 'package:you_app/services/chat_request_service.dart';
import 'package:you_app/services/community_service.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/monetization_service.dart';
import 'package:you_app/models/mood_model.dart';
import 'package:you_app/ui/views/paywall/paywall_helper.dart';

class MoodTrackerViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _authenticationService = locator<AuthenticationService>();
  final _monetizationService = locator<MonetizationService>();
  final AudioPlayer _fxPlayer = AudioPlayer();

  // --- Freemium ---
  bool get isPremium => _monetizationService.isPremium;
  late bool _wasPremium = isPremium;

  /// Advanced insights (deep patterns, reports) are Premium-only.
  bool get insightsLocked => !isPremium;
  Key chartKey = UniqueKey();

  int moodStreak = 0;
  String dailyQuote = "Taking a moment to acknowledge your feelings\nis a step toward self-care.";
  StreamSubscription<List<MoodEntry>>? _moodSubscription;

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
    _initializeData();
    // React to live subscription changes (e.g. an admin grants Premium): widen
    // the mood window and drop the insights teaser without needing a restart.
    _authenticationService.addListener(_onSubscriptionChanged);
  }

  void _onSubscriptionChanged() {
    if (isPremium != _wasPremium) {
      _wasPremium = isPremium;
      _subscribeMood(); // re-subscribe with the new window
      notifyListeners(); // refresh the insights teaser
    }
  }

  void _initializeData() {
    _setDailyQuote();
    _subscribeMood();
  }

  void _subscribeMood() {
    final userId = _authenticationService.currentUser?.uid;
    if (userId == null) return;
    _moodSubscription?.cancel();
    // Free tier sees a recent window; premium the full 30-day view.
    final windowDays = isPremium ? 30 : _monetizationService.moodWindowDays;
    _moodSubscription = locator<MoodService>()
        .getUserMoodStream(userId, windowDays: windowDays)
        .listen((entries) {
      _calculateStreak(entries);
    });
  }

  /// Free-tier "unlock advanced insights" action → gate analytics + paywall.
  Future<void> onUnlockInsights() async {
    locator<AnalyticsService>().logGateHit(feature: PaywallFeature.moodWindow);
    await PaywallHelper.show(feature: PaywallFeature.moodWindow);
  }

  /// Premium members open the full Mood Insights screen instead of the basic
  /// on-screen chart.
  Future<void> navigateToMoodInsights() async {
    await _navigationService.navigateToMoodInsightsView();
  }

  void _calculateStreak(List<MoodEntry> entries) {
    if (entries.isEmpty) {
      moodStreak = 0;
      notifyListeners();
      return;
    }

    // Use the string timestamp to create DateTime objects
    List<DateTime> entryDates = entries.map((e) {
      try {
        return DateTime.parse(e.timestamp);
      } catch (_) {
        return DateTime.now();
      }
    }).toList();

    entryDates.sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime now = DateTime.now();
    DateTime currentDate = DateTime(now.year, now.month, now.day);
    
    // Check if the first entry is from today or yesterday
    DateTime firstEntryDate = DateTime(entryDates.first.year, entryDates.first.month, entryDates.first.day);
    if (firstEntryDate.isBefore(currentDate.subtract(const Duration(days: 1)))) {
       moodStreak = 0;
       notifyListeners();
       return;
    }

    Set<String> uniqueDates = {};
    for (var date in entryDates) {
       uniqueDates.add("${date.year}-${date.month}-${date.day}");
    }

    List<DateTime> sortedUniqueDates = uniqueDates.map((s) {
       var parts = s.split('-');
       return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    }).toList();
    
    sortedUniqueDates.sort((a, b) => b.compareTo(a));

    DateTime checkDate = currentDate;
    for (int i = 0; i < sortedUniqueDates.length; i++) {
        if (i == 0) {
            if (sortedUniqueDates[i] == checkDate || sortedUniqueDates[i] == checkDate.subtract(const Duration(days: 1))) {
                streak++;
                checkDate = sortedUniqueDates[i];
            } else {
                break;
            }
        } else {
            if (sortedUniqueDates[i] == checkDate.subtract(const Duration(days: 1))) {
                streak++;
                checkDate = sortedUniqueDates[i];
            } else {
                break;
            }
        }
    }

    moodStreak = streak;
    notifyListeners();
  }

  void _setDailyQuote() {
    final quotes = [
      "Taking a moment to acknowledge your feelings\nis a step toward self-care.",
      "Your emotions are valid, no matter what they are.",
      "Every day is a fresh start. Take a deep breath.",
      "You are stronger than your hardest days.",
      "Check in with yourself, you deserve it."
    ];
    dailyQuote = quotes[DateTime.now().day % quotes.length];
    notifyListeners();
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

  Future<void> onEmojiSelected(String emojiAssetPath) async {
    if (_isDisposed) return;

    try {
      // 1. **Data Saving Logic (NEW)**
      final moodLabel = assetToLabelMap[emojiAssetPath];

      if (moodLabel != null) {
        final userId = _authenticationService.currentUser?.uid ?? "";
        final newMoodEntry = MoodEntry.create(
          userId, // Use the user ID from the service
          moodLabel,
          extraField: 'Recorded via MoodTrackerView', // Optional extra data
        );

        // Save the entry to Firestore
        await locator<MoodService>().saveMoodEntry(newMoodEntry);

        chartKey = UniqueKey();
      } else {
        debugPrint(
            'Error: Could not find mood label for asset path: $emojiAssetPath');
      }

      // 2. Haptic feedback
      HapticFeedback.mediumImpact();

      // 3. Play sound
      playSwipeSound(isComplete: true);

      // 4. Navigate (Uses the original emojiAssetPath for the AnimatedMoodScreen)
      _navigationService.navigateWithTransition(
        AnimatedMoodScreen(emoji: emojiAssetPath),
        transition: 'fade',
        duration: const Duration(milliseconds: 1000),
      );
    } catch (e) {
      debugPrint("Failed to handle emoji selection: $e");
      locator<SnackbarService>().showSnackbar(
        title: 'Could not save',
        message: "We couldn't save your mood. Please try again.",
      );
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
    _authenticationService.removeListener(_onSubscriptionChanged);
    _moodSubscription?.cancel();

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
