import 'package:just_audio/just_audio.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/models/sound_track.dart';
import 'package:you_app/ui/common/app_constants.dart';

class SoothingSoundsViewModel extends BaseViewModel {
  final AudioPlayer _player = AudioPlayer();

  int? _currentTrackIndex;
  int? get currentTrackIndex => _currentTrackIndex;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  final List<SoundTrack> soundTracks = const [
    SoundTrack(
      id: 0,
      title: 'Nature Resonance',
      subtitle: 'Ambient Water',
      imageAsset: AppConstants.soothing,
      audioAsset: AppConstants.natureWater,
    ),
    SoundTrack(
      id: 1,
      title: 'Calm Mindfulness',
      subtitle: 'Soft Reading',
      imageAsset: AppConstants.soothing2,
      audioAsset: AppConstants.calm,
    ),
    SoundTrack(
      id: 2,
      title: 'Deep Focus',
      subtitle: 'Gentle Swipes',
      imageAsset: AppConstants.breathe,
      audioAsset: AppConstants.focus,
    ),
  ];

  bool isPlayingTrack(int trackId) {
    return _currentTrackIndex == trackId && _player.playing;
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
    if (_player.duration == null) return;
    final newPosition = _player.position + const Duration(seconds: 10);
    if (newPosition < _player.duration!) {
      await _player.seek(newPosition);
    } else {
      await _player.seek(_player.duration!);
    }
  }

  Future<void> skipBackward() async {
    final newPosition = _player.position - const Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      await _player.seek(newPosition);
    } else {
      await _player.seek(Duration.zero);
    }
  }

  @override
  void dispose() {
    _player.dispose(); // Ensure player is destroyed when user leaves screen
    super.dispose();
  }
}
