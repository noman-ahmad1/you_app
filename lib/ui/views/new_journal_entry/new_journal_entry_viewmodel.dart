import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/models/journal_model.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/journal_service.dart';
import 'package:you_app/services/monetization_service.dart';
import 'package:you_app/services/storage_service.dart';
import 'package:you_app/ui/shared/app_banner.dart';
import 'package:you_app/ui/views/paywall/paywall_helper.dart';

class NewJournalEntryViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _authenticationService = locator<AuthenticationService>();
  final _monetizationService = locator<MonetizationService>();
  final _analytics = locator<AnalyticsService>();

  final titleController = TextEditingController();
  final contentController = TextEditingController();

  final JournalEntry? _editingEntry;

  // 0 = Text, 1 = Voice (the entry *medium*).
  int _currentIndex;
  int get currentIndex => _currentIndex;
  bool get isEditing => _editingEntry != null;
  bool get isVoiceTab => _currentIndex == 1;

  bool get isPremium => _monetizationService.isPremium;

  // The Work/Personal category — now chosen via a dropdown in the save row
  // instead of the top bar.
  JournalLabel _selectedLabel;
  JournalLabel get selectedLabel => _selectedLabel;

  // --- Recording state ---
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _preview = AudioPlayer();
  StreamSubscription<PlayerState>? _previewSub;

  // A recording *session* is active from the first tap until it's accepted or
  // discarded — it stays active (just paused) when the user taps pause.
  bool _isRecording = false;
  bool get isRecording => _isRecording;

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  /// Actively capturing audio right now (session active and not paused).
  bool get isRecordingLive => _isRecording && !_isPaused;

  bool _isPreviewPlaying = false;
  bool get isPreviewPlaying => _isPreviewPlaying;

  String? _localPath; // freshly recorded clip on disk
  String? _remoteAudioUrl; // existing clip when editing a voice entry
  int? _existingDurationMs;

  Timer? _timer;
  Duration _recordDuration = Duration.zero;
  Duration get recordDuration => _recordDuration;

  /// True when there's audio to save/play (a new recording or the existing one).
  bool get hasAudio => _localPath != null || _remoteAudioUrl != null;

  NewJournalEntryViewModel({JournalEntry? entry})
      : _editingEntry = entry,
        _currentIndex = (entry?.type == JournalType.voice) ? 1 : 0,
        _selectedLabel = entry?.label ?? JournalLabel.personal;

  void initialize() {
    if (isEditing) {
      titleController.text = _editingEntry!.title;
      contentController.text = _editingEntry!.content;
      _remoteAudioUrl = _editingEntry!.audioUrl;
      _existingDurationMs = _editingEntry!.audioDurationMs;
      if (_existingDurationMs != null) {
        _recordDuration = Duration(milliseconds: _existingDurationMs!);
      }
    }
  }

  void setTab(int index) {
    if (index == _currentIndex) return;
    // Voice journaling is a YOU+ feature — gate free users before switching.
    if (index == 1 && !isPremium) {
      _analytics.logGateHit(feature: PaywallFeature.voiceJournal);
      PaywallHelper.show(feature: PaywallFeature.voiceJournal);
      return; // stay on Text
    }
    _currentIndex = index;
    notifyListeners();
  }

  void setLabel(JournalLabel label) {
    if (_selectedLabel == label) return;
    _selectedLabel = label;
    notifyListeners();
  }

  String get durationLabel => _formatDuration(_recordDuration);

  static String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // --- Recording controls ---

  // Serialize control taps so rapid presses can't stack recorders / stop calls,
  // and expose a flag the UI reflects as a spinner on the primary button while
  // an async transition (permission, start, stop) is in flight.
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  Future<void> startRecording() => _runControl(_startRecording);
  Future<void> pauseRecording() => _runControl(_pauseRecording);
  Future<void> resumeRecording() => _runControl(_resumeRecording);
  Future<void> acceptRecording() => _runControl(_acceptRecording);
  Future<void> discardRecording() => _runControl(_discardRecording);

  Future<void> _runControl(Future<void> Function() action) async {
    if (_isProcessing || isBusy) return; // ignore taps mid-transition / mid-save
    _isProcessing = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        _dialogService.showDialog(
          title: 'Microphone needed',
          description:
              'Please allow microphone access to record a voice journal.',
        );
        return;
      }
      // Drop any previous preview / clip before starting a fresh take.
      await _stopPreview();
      await _deleteFile(_localPath); // clean up a re-recorded clip
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/journal_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path);
      HapticFeedback.mediumImpact(); // a satisfying "recording started" thunk

      _localPath = null;
      _remoteAudioUrl = null; // a new take replaces the old clip
      _isRecording = true;
      _isPaused = false;
      _recordDuration = Duration.zero;
      _startTimer();
      notifyListeners();
    } catch (e) {
      _isRecording = false;
      _isPaused = false;
      notifyListeners();
      _dialogService.showDialog(
        title: 'Recording failed',
        description: 'We could not start recording. Please try again.',
      );
    }
  }

  /// Pause the active recording (timer + waveform freeze).
  Future<void> _pauseRecording() async {
    if (!isRecordingLive) return;
    HapticFeedback.lightImpact();
    _timer?.cancel();
    try {
      await _recorder.pause();
    } catch (_) {}
    _isPaused = true;
    notifyListeners();
  }

  /// Resume a paused recording, continuing the timer.
  Future<void> _resumeRecording() async {
    if (!_isRecording || !_isPaused) return;
    HapticFeedback.lightImpact();
    try {
      await _recorder.resume();
    } catch (_) {}
    _isPaused = false;
    _startTimer();
    notifyListeners();
  }

  /// Finish the session and keep the clip. Idempotent once accepted, so tapping
  /// the tick again in the captured state can't wipe the saved recording.
  Future<void> _acceptRecording() async {
    if (!_isRecording) return;
    HapticFeedback.mediumImpact(); // confirm the take is kept
    _timer?.cancel();
    try {
      final path = await _recorder.stop();
      _localPath = path;
    } catch (_) {
      // keep whatever we had
    }
    _isRecording = false;
    _isPaused = false;
    notifyListeners();
  }

  /// Abandon the in-progress or captured recording and return to idle. Cleans
  /// up both the just-stopped file and any already-captured clip.
  Future<void> _discardRecording() async {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    String? stopped;
    try {
      stopped = await _recorder.stop();
    } catch (_) {}
    final captured = _localPath;
    _isRecording = false;
    _isPaused = false;
    _localPath = null;
    _remoteAudioUrl = null;
    _recordDuration = Duration.zero;
    notifyListeners();
    await _deleteFile(stopped);
    await _deleteFile(captured);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _recordDuration += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  /// Discard the captured clip and let the user record again.
  Future<void> deleteRecording() async {
    await _stopPreview();
    final path = _localPath;
    _localPath = null;
    _remoteAudioUrl = null;
    _recordDuration = Duration.zero;
    notifyListeners();
    await _deleteFile(path);
  }

  Future<void> _deleteFile(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  Future<void> togglePreview() async {
    if (_isPreviewPlaying) {
      await _stopPreview();
      return;
    }
    try {
      if (_localPath != null) {
        await _preview.setFilePath(_localPath!);
      } else if (_remoteAudioUrl != null) {
        await _preview.setUrl(_remoteAudioUrl!);
      } else {
        return;
      }
      _previewSub ??= _preview.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPreviewPlaying = false;
          _preview.seek(Duration.zero);
          _preview.pause();
          notifyListeners();
        }
      });
      _isPreviewPlaying = true;
      notifyListeners();
      await _preview.play();
    } catch (_) {
      _isPreviewPlaying = false;
      notifyListeners();
    }
  }

  Future<void> _stopPreview() async {
    if (_preview.playing) await _preview.pause();
    await _preview.seek(Duration.zero);
    _isPreviewPlaying = false;
    notifyListeners();
  }

  // --- Save ---

  /// Single entry point for the shared save row — routes to create/update.
  Future<void> submit() async {
    if (isEditing) {
      await _updateJournalEntry();
    } else {
      await _createJournalEntry();
    }
  }

  Future<void> _createJournalEntry() async {
    if (titleController.text.trim().isEmpty) {
      _incompleteDialog();
      return;
    }
    if (isVoiceTab) {
      if (!hasAudio) {
        _dialogService.showDialog(
          title: 'Nothing recorded yet',
          description: 'Record a short voice note before saving your entry.',
        );
        return;
      }
    } else if (contentController.text.trim().isEmpty) {
      _incompleteDialog();
      return;
    }

    setBusy(true);
    try {
      final userId = _authenticationService.currentUser?.uid;
      if (userId == null) throw Exception('No user is currently logged in.');

      String? audioUrl;
      int? audioDurationMs;
      if (isVoiceTab && _localPath != null) {
        audioUrl = await _uploadRecording(userId, _localPath!);
        if (audioUrl == null) throw Exception('Audio upload failed.');
        audioDurationMs = _recordDuration.inMilliseconds;
      }

      final newEntry = JournalEntry(
        userId: userId,
        title: titleController.text.trim(),
        content: contentController.text.trim(),
        label: _selectedLabel,
        type: isVoiceTab ? JournalType.voice : JournalType.text,
        audioUrl: audioUrl,
        audioDurationMs: audioDurationMs,
      );

      await locator<JournalService>().addJournalEntry(newEntry);

      await _dialogService.showDialog(
        title: 'Saved!',
        description: 'Your journal entry has been successfully saved.',
        buttonTitle: 'Great!',
      );
      _navigationService.back();
    } catch (e) {
      _dialogService.showDialog(
        title: 'Error',
        description:
            'We could not save your entry at this time. Please try again.',
      );
    } finally {
      setBusy(false);
    }
  }

  Future<void> _updateJournalEntry() async {
    if (!isEditing) return;
    if (titleController.text.trim().isEmpty) {
      _incompleteDialog();
      return;
    }

    setBusy(true);
    try {
      final data = <String, dynamic>{
        'title': titleController.text.trim(),
        'label': _selectedLabel.name,
      };

      if (isVoiceTab) {
        // Re-recorded → upload the new clip; otherwise keep the existing audio.
        if (_localPath != null) {
          final url = await _uploadRecording(_editingEntry!.userId, _localPath!);
          if (url == null) throw Exception('Audio upload failed.');
          data['audioUrl'] = url;
          data['audioDurationMs'] = _recordDuration.inMilliseconds;
        }
      } else {
        data['content'] = contentController.text.trim();
      }

      await locator<JournalService>().updateJournalEntry(
        userId: _editingEntry!.userId,
        entryId: _editingEntry!.id!,
        data: data,
      );
      _navigationService.back();
    } catch (e) {
      _dialogService.showDialog(
        title: 'Error',
        description:
            'We could not update your entry at this time. Please try again.',
      );
    } finally {
      setBusy(false);
    }
  }

  Future<String?> _uploadRecording(String userId, String localPath) {
    final storagePath =
        'journal_audio/$userId/${DateTime.now().millisecondsSinceEpoch}.m4a';
    return locator<StorageService>().uploadFile(File(localPath), storagePath);
  }

  void _incompleteDialog() {
    _dialogService.showDialog(
      title: 'Incomplete Entry',
      description: isVoiceTab
          ? 'Please add a title for your voice entry.'
          : 'Please make sure to fill out both the title and the content of your entry.',
    );
  }

  void showAppBanner(BuildContext context,
      {required String title, required String description}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: AppBanner(title: title, description: description),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Future back() async {
    _navigationService.back();
  }

  Future navigateToJournal() async {
    _navigationService.navigateToJournalView();
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    _timer?.cancel();
    _previewSub?.cancel();
    _recorder.dispose();
    _preview.dispose();
    super.dispose();
  }
}
