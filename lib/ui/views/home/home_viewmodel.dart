import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:you_app/app/app.bottomsheets.dart';
import 'package:you_app/app/app.dialogs.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/app_strings.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class HomeViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  // Secondary player for short sound effects (e.g., swipe)
  final AudioPlayer _fxPlayer = AudioPlayer();
  // Main player for soothing music audio
  final AudioPlayer _player = AudioPlayer();
  final _dialogService = locator<DialogService>();
  final _bottomSheetService = locator<BottomSheetService>();

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;
  String get counterLabel => 'Counter is: $_counter';

  bool isPlayingTrack(int trackIndex) {
    return _currentTrackIndex == trackIndex && _player.playing;
  }

  int? _currentTrackIndex; // which card is playing
  int? get currentTrackIndex => _currentTrackIndex;

  int _counter = 0;
  int currentIndex = 1;

  HomeViewModel() {
    _initPlayer();
    _player.playerStateStream.listen((state) {
      notifyListeners();
    });
  }

  Future<void> _initFxPlayer() async {
    _fxPlayer.setLoopMode(LoopMode.off);
  }

  Future<void> _initPlayer() async {
    _player.setLoopMode(LoopMode.one);
  }

  void onTabTapped(int index) {
    currentIndex = index;
    notifyListeners();
  }

  void incrementCounter() {
    _counter++;
    rebuildUi();
  }

  Future<void> togglePlayPause(int trackIndex, String assetPath) async {
    if (_currentTrackIndex == trackIndex && _player.playing) {
      // Pause if same track is playing
      await _player.pause();
      _currentTrackIndex = null;
    } else {
      // Load new track if switching
      if (_currentTrackIndex != trackIndex) {
        await _player.stop();
        await _player.setAsset(assetPath);
        _currentTrackIndex = trackIndex;
      }
      await _player.play();
    }
    notifyListeners();
  }

  Future<void> skipForward() async {
    final position = _player.position;
    final duration = _player.duration ?? Duration.zero;
    final newPosition = position + const Duration(seconds: 5);
    await _player.seek(newPosition < duration ? newPosition : duration);
  }

  Future<void> skipBackward() async {
    final position = _player.position;
    final newPosition = position - const Duration(seconds: 5);
    await _player
        .seek(newPosition > Duration.zero ? newPosition : Duration.zero);
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

  void showDialog() {
    _dialogService.showCustomDialog(
      variant: DialogType.infoAlert,
      title: 'Stacked Rocks!',
      description: 'Give stacked $_counter stars on Github',
    );
  }

  void showBottomSheet() {
    _bottomSheetService.showCustomSheet(
      variant: BottomSheetType.notice,
      title: ksHomeBottomSheetTitle,
      description: ksHomeBottomSheetDescription,
    );
  }

  final List<GlobalKey<NavigatorState>> navigatorKeys = [
    GlobalKey<NavigatorState>(), // Community
    GlobalKey<NavigatorState>(), // Home
    GlobalKey<NavigatorState>(), // Chat
  ];

  void setTab(int index) {
    if (index == currentIndex) {
      navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      currentIndex = index;
      notifyListeners();
    }
  }

  Future navigateToJournal() async {
    _navigationService.navigateToJournalView();
  }

  Future navigateToMoodTracker() async {
    _navigationService.navigateToMoodTrackerView();
  }

  Future navigateToChatbot() async {
    _navigationService.navigateToChatbotView();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
