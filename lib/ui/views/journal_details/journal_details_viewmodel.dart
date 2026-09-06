import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/models/journal_model.dart';
import 'package:you_app/services/journal_service.dart';

class JournalDetailsViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();

  final JournalEntry entry;

  JournalDetailsViewModel({required this.entry});

  bool get isVoice => entry.isVoice;

  // --- Voice playback (just_audio) ---
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioPlayer get audioPlayer => _audioPlayer;
  bool get isPlaying => _audioPlayer.playing;

  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Duration get totalDuration =>
      _audioPlayer.duration ??
      Duration(milliseconds: entry.audioDurationMs ?? 0);

  /// Loads the recording once the view is ready. Safe no-op for text entries.
  Future<void> initAudio() async {
    if (!isVoice || entry.audioUrl == null) return;
    try {
      await _audioPlayer.setUrl(entry.audioUrl!);
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.pause();
        }
        notifyListeners();
      });
    } catch (e) {
      // Leave the player idle; the UI still shows controls.
    }
  }

  Future<void> togglePlay() async {
    if (_audioPlayer.processingState == ProcessingState.completed) {
      await _audioPlayer.seek(Duration.zero);
    }
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
    notifyListeners();
  }

  Future<void> seek(Duration position) => _audioPlayer.seek(position);

  String get category =>
      entry.label.name[0].toUpperCase() + entry.label.name.substring(1);

  /// Returns the entry's timestamp as a formatted string.
  String get date => entry.timestamp != null
      ? DateFormat('d MMMM, yyyy').format(entry.timestamp!)
      : 'Entry Details';

  Future<void> deleteEntry() async {
    final response = await _dialogService.showConfirmationDialog(
      title: 'Delete Entry',
      description:
          'Are you sure you want to delete this journal entry? This action cannot be undone.',
      confirmationTitle: 'Delete',
      cancelTitle: 'Cancel',
    );

    // If the user confirmed the deletion
    if (response?.confirmed == true) {
      setBusy(true);
      try {
        await locator<JournalService>().deleteJournalEntry(
          userId: entry.userId,
          entryId: entry.id!,
        );
        _navigationService.back(); // Go back after successful deletion
      } catch (e) {
        setBusy(false);
        await _dialogService.showDialog(
          title: 'Error',
          description: 'Could not delete the entry. Please try again.',
        );
      }
    }
  }

  void navigateToNewJournalEntry() {
    _navigationService.navigateToNewJournalEntryView(journalEntry: entry);
  }

  void back() {
    _navigationService.back();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
