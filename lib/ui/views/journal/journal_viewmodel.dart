import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/models/journal_model.dart'; // Make sure this is your JournalEntry model
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/firestore_service.dart';
import 'package:you_app/ui/common/app_constants.dart';

class JournalViewModel extends BaseViewModel {
  // --- Services ---
  final _navigationService = locator<NavigationService>();
  final _firestoreService = locator<FirestoreService>();
  final _authenticationService = locator<AuthenticationService>();
  final AudioPlayer _fxPlayer = AudioPlayer();

  // --- State ---
  int _currentIndex = 1; // Default to 'All' tab
  int get currentIndex => _currentIndex;

  List<JournalEntry> _allEntries = [];
  StreamSubscription? _journalStreamSubscription;

  // --- Filtered Lists for the UI ---
  // These getters efficiently filter the main list without re-fetching from Firestore.
  List<JournalEntry> get allEntries => _allEntries;

  List<JournalEntry> get personalEntries => _allEntries
      .where((entry) => entry.label == JournalLabel.personal)
      .toList();

  List<JournalEntry> get workEntries =>
      _allEntries.where((entry) => entry.label == JournalLabel.work).toList();

  /// **Initializes the ViewModel by fetching the journal entries.**
  /// This should be called from your `JournalView`.
  void listenToJournalEntries() {
    final userId = _authenticationService.currentUser?.uid;
    if (userId == null) {
      // Handle case where user is not logged in
      return;
    }

    setBusy(true);

    // Cancel any previous stream to prevent memory leaks
    _journalStreamSubscription?.cancel();

    _journalStreamSubscription = _firestoreService.journal
        .getJournalEntriesStream(userId: userId)
        .listen((entries) {
      _allEntries = entries; // Update the main list with new data
      setBusy(false); // Data has arrived
      notifyListeners(); // Rebuild the UI
    }, onError: (error) {
      setBusy(false);
      // Optionally show a dialog if fetching fails
      print("Error fetching journal entries: $error");
    });
  }

  /// Changes the active tab in the UI.
  void setTab(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  // --- Sound Effects ---
  Future<void> playSwipeSound({bool isComplete = false}) async {
    try {
      // You can use different sounds for start and end
      final soundPath = isComplete ? AppConstants.page : AppConstants.page;
      await _fxPlayer.stop();
      await _fxPlayer.setAsset(soundPath);
      await _fxPlayer.play();
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  // --- Navigation ---
  void back() {
    _navigationService.back();
  }

  void navigateToEditJournalEntry(JournalEntry entry) {
    _navigationService.navigateToNewJournalEntryView(journalEntry: entry);
  }

  void navigateToNewJournalEntry() {
    _navigationService.navigateToNewJournalEntryView();
  }

  void navigateToJournalDetails(JournalEntry entry) {
    _navigationService.navigateToJournalDetailsView(journalEntry: entry);
  }

  @override
  void dispose() {
    // IMPORTANT: Always cancel stream subscriptions to avoid memory leaks.
    _journalStreamSubscription?.cancel();
    _fxPlayer.dispose();
    super.dispose();
  }
}
