import 'dart:async';
import 'package:stacked/stacked.dart';

enum BreathePhase { inhale, hold, exhale, idle }

class BreatheViewModel extends BaseViewModel {
  Timer? _timer;

  BreathePhase _currentPhase = BreathePhase.idle;
  BreathePhase get currentPhase => _currentPhase;

  int _secondsRemaining = 0;
  int get secondsRemaining => _secondsRemaining;

  bool get isActive => _currentPhase != BreathePhase.idle;

  String get instructionText {
    switch (_currentPhase) {
      case BreathePhase.inhale:
        return 'Breathe In';
      case BreathePhase.hold:
        return 'Hold';
      case BreathePhase.exhale:
        return 'Breathe Out';
      case BreathePhase.idle:
      default:
        return ' Let\'s breathe together.';
    }
  }

  void toggleBreathing() {
    if (isActive) {
      _stopBreathing();
    } else {
      _startBreathing();
    }
    notifyListeners();
  }

  void _startBreathing() {
    _startInhale();
  }

  void _stopBreathing() {
    _timer?.cancel();
    _currentPhase = BreathePhase.idle;
    _secondsRemaining = 0;
  }

  void _startInhale() {
    _currentPhase = BreathePhase.inhale;
    _secondsRemaining = 4; // 4 seconds inhale
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        _startHold();
      }
    });
  }

  void _startHold() {
    _currentPhase = BreathePhase.hold;
    _secondsRemaining = 7; // 7 seconds hold
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        _startExhale();
      }
    });
  }

  void _startExhale() {
    _currentPhase = BreathePhase.exhale;
    _secondsRemaining = 8; // 8 seconds exhale
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        // Loop back to inhale
        _startInhale();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
