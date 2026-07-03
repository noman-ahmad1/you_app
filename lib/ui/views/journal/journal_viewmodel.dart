import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/models/journal_model.dart'; // Make sure this is your JournalEntry model
import 'package:you_app/services/app_content_service.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/base/app_log.dart';
import 'package:you_app/services/user_service.dart';
import 'package:you_app/services/volunteer_service.dart';
import 'package:you_app/services/mood_service.dart';
import 'package:you_app/services/journal_service.dart';
import 'package:you_app/services/chat_service.dart';
import 'package:you_app/services/chat_request_service.dart';
import 'package:you_app/services/community_service.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/monetization_service.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/views/paywall/paywall_helper.dart';

class JournalViewModel extends BaseViewModel {
  // --- Services ---
  final _navigationService = locator<NavigationService>();
  final _authenticationService = locator<AuthenticationService>();
  final _monetizationService = locator<MonetizationService>();
  final AudioPlayer _fxPlayer = AudioPlayer();

  // --- Freemium ---
  bool get isPremium => _monetizationService.isPremium;
  late bool _wasPremium = isPremium;

  JournalViewModel() {
    // React to live subscription changes (e.g. an admin grants Premium): drop
    // the history window and hide the unlock button without needing a restart.
    _authenticationService.addListener(_onSubscriptionChanged);
  }

  void _onSubscriptionChanged() {
    if (isPremium != _wasPremium) {
      _wasPremium = isPremium;
      listenToJournalEntries(); // re-subscribe with the new window + rebuild UI
    }
  }

  /// True when the history shown is capped to the free-tier window (so the view
  /// can offer an "unlock full history" row).
  bool get historyLimited => !isPremium;

  /// Size (in days) of the free-tier journal history window.
  int get historyWindowDays => _monetizationService.journalHistoryDays;

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

    _journalStreamSubscription = locator<JournalService>()
        .getJournalEntriesStream(
          userId: userId,
          // Free users see a recent window; premium gets the full history.
          sinceDays: isPremium ? null : historyWindowDays,
        )
        .listen((entries) {
      _allEntries = entries; // Update the main list with new data
      setBusy(false); // Data has arrived
      notifyListeners(); // Rebuild the UI
    }, onError: (error) {
      setBusy(false);
      AppLog.error('JournalViewModel.getJournalEntries', error);
    });
  }

  /// The admin-scheduled prompt for today, or null when none is active.
  /// The view falls back to [defaultPrompt] so a prompt is always shown.
  Stream<String?> get promptOfTheDay =>
      locator<AppContentService>().promptOfTheDay();

  /// Gentle fallback used when there's no active prompt for today.
  String get defaultPrompt =>
      'What is one thing that brought you peace today?';

  /// Free-tier "unlock full history" action → gate analytics + paywall.
  Future<void> onUnlockHistory() async {
    locator<AnalyticsService>().logGateHit(feature: PaywallFeature.journalHistory);
    await PaywallHelper.show(feature: PaywallFeature.journalHistory);
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
    _authenticationService.removeListener(_onSubscriptionChanged);
    _journalStreamSubscription?.cancel();
    _fxPlayer.dispose();
    super.dispose();
  }
}
