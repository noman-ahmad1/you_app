import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/ui/common/app_constants.dart';

class VolunteerSignupInfoViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final AudioPlayer _fxPlayer = AudioPlayer();
  int _currentIndex = 1;
  int get currentIndex => _currentIndex;

  void setTab(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  Future<void> playSwipeSound({bool isComplete = false}) async {
    try {
      final soundPath = isComplete
          ? AppConstants.page // ✅ completion sound
          : AppConstants.page; // ✅ during swipe sound
      await _fxPlayer.stop(); // Stop any current sound
      await _fxPlayer.setAsset(soundPath);
      await _fxPlayer.play();
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  Future back() async {
    _navigationService.back();
  }

  Future navigateToNewJournalEntry() async {
    _navigationService.navigateToNewJournalEntryView();
  }
}
