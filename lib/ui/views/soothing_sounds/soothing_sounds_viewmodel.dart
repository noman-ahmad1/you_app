import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:just_audio/just_audio.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/models/sound_track.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/base/app_log.dart';
import 'package:you_app/services/monetization_service.dart';
import 'package:you_app/services/sound_service.dart';
import 'package:you_app/ui/views/paywall/paywall_helper.dart';

class SoothingSoundsViewModel extends StreamViewModel<List<SoundTrack>> {
  final _soundService = locator<SoundService>();
  final _monetizationService = locator<MonetizationService>();
  final _snackbarService = locator<SnackbarService>();

  final AudioPlayer _player = AudioPlayer();

  /// The sound currently loaded into the player — NOT cleared on pause, so that
  /// resuming continues from the current position instead of restarting.
  String? _currentSoundId;
  String? get currentSoundId => _currentSoundId;

  /// Where the current sound was when the user paused it.
  ///
  /// We don't trust the player to remember: a LockCachingAudioSource that is
  /// still filling its cache file can come back at zero after a pause, which
  /// made resume silently restart the track from the beginning. Capturing the
  /// position ourselves and seeking back to it on resume is deterministic
  /// regardless of what the source does underneath.
  ///
  /// Scoped to this screen only — leaving and returning builds a fresh view
  /// model, so a sound legitimately starts from the top again.
  Duration _pausedAt = Duration.zero;

  /// The sound whose audio we're resolving/buffering right now (the first play
  /// of a sound has to fetch a signed URL and stream it).
  String? _loadingSoundId;
  bool isLoadingTrack(String soundId) => _loadingSoundId == soundId;

  List<SoundTrack> get sounds => data ?? const [];

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  bool get isPremium => _monetizationService.isPremium;

  /// True when [track] is locked for this user — drives the card's lock badge.
  bool isLocked(SoundTrack track) => track.isPremium && !isPremium;

  SoothingSoundsViewModel() {
    // Rebuild the cards when playback starts/stops/completes, so the play/pause
    // icon follows the PLAYER's real state rather than our last guess at it.
    _player.playerStateStream.listen((_) => notifyListeners());
  }

  @override
  Stream<List<SoundTrack>> get stream => _soundService.streamSounds();

  @override
  void onError(error, StackTrace? stackTrace) {
    AppLog.error('SoothingSoundsViewModel.stream', error, stackTrace);
  }

  /// Re-subscribes after a failed load (the "Try again" button).
  void retry() => notifySourceChanged();

  bool isPlayingTrack(String soundId) =>
      _currentSoundId == soundId && _player.playing;

  Future<void> togglePlayPause(SoundTrack track) async {
    // The premium gate runs FIRST — before we so much as look at the disk cache.
    // A user who played this sound while subscribed and then lapsed must not get
    // it back for free from their own cache.
    if (isLocked(track)) {
      locator<AnalyticsService>()
          .logGateHit(feature: PaywallFeature.soothingSounds);
      await PaywallHelper.show(feature: PaywallFeature.soothingSounds);
      return;
    }

    // Same track, already playing → pause. Remember WHERE, and keep
    // _currentSoundId, so the next tap picks up from here.
    if (_currentSoundId == track.id && _player.playing) {
      _pausedAt = _player.position;
      await _player.pause();
      notifyListeners();
      return;
    }

    // Same track, paused → resume from where we left off.
    if (_currentSoundId == track.id) {
      // Seek explicitly rather than trusting the source to have held its
      // position — see [_pausedAt]. If the track had run to the end, start over.
      final finished = _player.processingState == ProcessingState.completed;
      await _player.seek(finished ? Duration.zero : _pausedAt);
      unawaited(_player.play());
      notifyListeners();
      return;
    }

    // A different track → load it.
    _loadingSoundId = track.id;
    notifyListeners();
    try {
      await _player.stop();
      await _player.setAudioSource(await _audioSourceFor(track));
      _currentSoundId = track.id;
      _pausedAt = Duration.zero; // a freshly loaded track starts at the top
      // NOT awaited — deliberately. just_audio's play() completes when playback
      // ENDS or is PAUSED, not when it starts. Awaiting it held this method open
      // for the whole track, so the `finally` never ran and the spinner stayed
      // spinning over an already-playing sound until you tapped pause.
      // setAudioSource() above has already done the loading we care about.
      unawaited(_player.play());
    } on FirebaseFunctionsException catch (e) {
      // The gate above should make this unreachable; if it fires, the client and
      // the server disagree about entitlement — trust the server.
      if (e.code == 'permission-denied') {
        await PaywallHelper.show(feature: PaywallFeature.soothingSounds);
      } else {
        _showPlaybackError(e);
      }
    } catch (e, s) {
      AppLog.error('SoothingSoundsViewModel.togglePlayPause', e, s);
      _showPlaybackError(e);
    } finally {
      _loadingSoundId = null;
      notifyListeners();
    }
  }

  /// Cached on disk → play the file directly (offline, and no callable round-trip).
  /// Otherwise fetch a signed URL and stream it, caching to disk as it goes, so
  /// the second play of a sound never touches the network.
  ///
  /// The cache file is keyed by sound id, not by URL — the signed URL rotates
  /// hourly, and a URL-keyed cache would re-download the file every session.
  Future<AudioSource> _audioSourceFor(SoundTrack track) async {
    final file = await _soundService.cacheFileFor(track.id);
    if (await file.exists()) return AudioSource.file(file.path);

    final url = await _soundService.getPlaybackUrl(track.id);
    // just_audio marks this experimental, but it's long-standing and it's the
    // only source that streams and caches in one pass. Without it, every play
    // re-downloads the file.
    // ignore: experimental_member_use
    return LockCachingAudioSource(Uri.parse(url), cacheFile: file);
  }

  /// Distinguishes "your network is down" from "the server couldn't serve this".
  ///
  /// Blaming the connection for a SERVER fault is worse than saying nothing: the
  /// user retries on wifi, on data, restarts the app — and none of it can work.
  /// (This is not hypothetical: a missing `signBlob` IAM role made every play
  /// fail with `internal`, and the app cheerfully told everyone to check their
  /// internet.)
  void _showPlaybackError(Object e) {
    AppLog.error('SoothingSoundsViewModel.playback', e);

    final serverFault =
        e is FirebaseFunctionsException && e.code != 'unavailable';

    _snackbarService.showSnackbar(
      title: 'Could not play',
      message: serverFault
          ? "This sound isn't available right now. We're on it — please try "
              'another one.'
          : 'Check your connection and try again.',
    );
  }

  Future<void> skipForward() async {
    final duration = _player.duration;
    if (_currentSoundId == null || duration == null) return;
    final next = _player.position + const Duration(seconds: 10);
    await _seekTo(next < duration ? next : duration);
  }

  Future<void> skipBackward() async {
    if (_currentSoundId == null) return;
    final previous = _player.position - const Duration(seconds: 10);
    await _seekTo(previous > Duration.zero ? previous : Duration.zero);
  }

  /// Seeks, keeping [_pausedAt] in step. Without this, skipping while PAUSED
  /// would be undone the moment you hit play — resume would seek back to where
  /// you originally paused and throw the skip away.
  Future<void> _seekTo(Duration position) async {
    _pausedAt = position;
    await _player.seek(position);
  }

  @override
  void dispose() {
    _player.dispose(); // playback stops when the user leaves the screen
    super.dispose();
  }
}
