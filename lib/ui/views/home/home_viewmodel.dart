import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:you_app/ui/shared/in_app_notification_banner.dart';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:you_app/app/app.bottomsheets.dart';
import 'package:you_app/app/app.dialogs.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/models/app_user.dart';
import 'package:you_app/models/chat_request_model.dart';
import 'package:you_app/models/mood_model.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/ui/views/paywall/paywall_helper.dart';
import 'package:you_app/ui/views/premium/premium_helper.dart';
import 'package:you_app/services/app_content_service.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/base/app_log.dart';
import 'package:you_app/services/block_service.dart';
import 'package:you_app/services/user_service.dart';
import 'package:you_app/services/volunteer_service.dart';
import 'package:you_app/services/mood_service.dart';
import 'package:you_app/services/journal_service.dart';
import 'package:you_app/services/chat_service.dart';
import 'package:you_app/services/chat_request_service.dart';
import 'package:you_app/services/community_service.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/app_strings.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class HomeViewModel extends ReactiveViewModel {
  final _navigationService = locator<NavigationService>();
  final _authenticationService = locator<AuthenticationService>();

  @override
  List<ListenableServiceMixin> get listenableServices =>
      [_authenticationService];
  // Secondary player for short sound effects (e.g., swipe)
  final AudioPlayer _fxPlayer = AudioPlayer();
  // Main player for soothing music audio
  final AudioPlayer _player = AudioPlayer();
  final _dialogService = locator<DialogService>();
  final _bottomSheetService = locator<BottomSheetService>();

  List<AppUser> _volunteers = [];
  List<AppUser> get volunteers => _volunteers;
  AppUser? get currentUser => _authenticationService.currentUser;

  Map<String, List<String>> _volunteerTags = {};
  Map<String, List<String>> get volunteerTags => _volunteerTags;

  Map<String, double> _volunteerRatings = {};
  Map<String, double> get volunteerRatings => _volunteerRatings;

  List<String> _selectedFilterTags = [];
  List<String> get selectedFilterTags => _selectedFilterTags;

  List<AppUser> get filteredVolunteers {
    if (_selectedFilterTags.isEmpty) return _volunteers;
    return _volunteers.where((volunteer) {
      final tags = _volunteerTags[volunteer.uid] ?? [];
      // Show volunteer if they have AT LEAST ONE of the selected tags
      return _selectedFilterTags.any((tag) => tags.contains(tag));
    }).toList();
  }

  void toggleFilterTag(String tag) {
    if (_selectedFilterTags.contains(tag)) {
      _selectedFilterTags.remove(tag);
    } else {
      _selectedFilterTags.add(tag);
    }
    notifyListeners();
  }

  StreamSubscription? _sentRequestsSubscription;
  ChatRequest? _pendingRequest; // Holds the user's single pending request
  ChatRequest? get pendingRequest => _pendingRequest;
  ChatRequest? _activeChatRequest; // Holds the user's single accepted request
  ChatRequest? get activeChatRequest => _activeChatRequest;

  StreamSubscription? _notificationsSubscription;
  int _unreadNotificationsCount = 0;
  int get unreadNotificationsCount => _unreadNotificationsCount;

  StreamSubscription? _volunteersSubscription;

  // Consecutive-day mood-logging streak (for the home drawer card).
  StreamSubscription? _moodStreakSubscription;
  int _moodStreak = 0;
  int get moodStreak => _moodStreak;

  bool get hasActiveInteraction =>
      pendingRequest != null || activeChatRequest != null;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;
  String get counterLabel => 'Counter is: $_counter';
  String get currentUserName =>
      _authenticationService.currentUser?.firstName ?? 'there';
  String get currentUserEmail =>
      _authenticationService.currentUser?.email ?? 'visitor@you.app';

  int _counter = 0;
  int currentIndex = 1;

  String _todayWhisper = 'Some days, surviving is a form of bravery';
  String get todayWhisper => _todayWhisper;

  final GlobalKey moodKey = GlobalKey();
  final GlobalKey journalKey = GlobalKey();
  final GlobalKey communitiesKey = GlobalKey();
  final GlobalKey volunteersKey = GlobalKey();
  final GlobalKey soothingSoundsKey = GlobalKey();
  final GlobalKey breatheKey = GlobalKey();
  final GlobalKey dodoKey = GlobalKey();

  /// Called when the first-run feature tour finishes (ShowCaseWidget.onFinish).
  void onShowcaseFinished() =>
      locator<AnalyticsService>().logOnboardingCompleted(tour: 'home');

  Future<void> checkAndStartShowcase(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenHomeShowcase') ?? false;
    if (!hasSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShowCaseWidget.of(context).startShowCase([
          moodKey,
          journalKey,
          communitiesKey,
          volunteersKey,
          soothingSoundsKey,
          breatheKey,
          dodoKey,
        ]);
      });
      await prefs.setBool('hasSeenHomeShowcase', true);
    }
  }

  HomeViewModel() {
    listenToVolunteers();
    listenForSentRequests();
    listenForNotifications();
    listenForMoodStreak();
    fetchTodayWhisper();
  }

  /// Listens to the user's mood entries and keeps [moodStreak] (consecutive
  /// days with a logged mood) up to date for the home drawer streak card.
  void listenForMoodStreak() {
    final userId = _authenticationService.currentUser?.uid;
    if (userId == null) return;
    _moodStreakSubscription?.cancel();
    _moodStreakSubscription =
        locator<MoodService>().getUserMoodStream(userId).listen((entries) {
      _moodStreak = _computeMoodStreak(entries);
      notifyListeners();
    }, onError: (error) {
      AppLog.error('HomeViewModel.listenForMoodStreak', error);
    });
  }

  /// Counts consecutive days (ending today or yesterday) with a mood entry.
  int _computeMoodStreak(List<MoodEntry> entries) {
    if (entries.isEmpty) return 0;

    // Collapse to unique calendar days, newest first.
    final uniqueDays = <DateTime>{};
    for (final e in entries) {
      DateTime d;
      try {
        d = DateTime.parse(e.timestamp);
      } catch (_) {
        continue;
      }
      uniqueDays.add(DateTime(d.year, d.month, d.day));
    }
    if (uniqueDays.isEmpty) return 0;

    final days = uniqueDays.toList()..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Streak only counts if the latest entry is today or yesterday.
    if (days.first.isBefore(today.subtract(const Duration(days: 1)))) return 0;

    int streak = 0;
    DateTime expected = days.first; // today or yesterday
    for (final day in days) {
      if (day == expected) {
        streak++;
        expected = expected.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Future<void> fetchTodayWhisper() async {
    try {
      final response = await http.get(Uri.parse('https://zenquotes.io/api/today'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty && data[0]['q'] != null) {
          _todayWhisper = data[0]['q'];
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch today's whisper: $e");
    }
  }

  void onTabTapped(int index) {
    currentIndex = index;
    notifyListeners();
  }

  void navigateToSoothingSounds() {
    locator<NavigationService>().navigateToSoothingSoundsView();
  }

  void navigateToBreathe() {
    locator<NavigationService>().navigateToBreatheView();
  }

  void navigateToPremium() {
    PremiumHelper.open(source: 'home_drawer');
  }

  void setIndex(int value) {
    _counter++;
    rebuildUi();
  }

  void incrementCounter() {
    _counter++;
    rebuildUi();
  }

  bool isCommunityJoined(String communityId) {
    final user = _authenticationService.currentUser;
    if (user == null) return false;
    return user.joinedCommunities.contains(communityId);
  }

  // Per-community join-in-progress tracking so each card shows its own spinner.
  final Set<String> _joiningCommunities = {};
  bool isJoiningCommunity(String communityId) =>
      _joiningCommunities.contains(communityId);

  Future<void> joinCommunity(String communityId) async {
    if (_joiningCommunities.contains(communityId)) return;
    _joiningCommunities.add(communityId);
    notifyListeners();
    try {
      await locator<CommunityService>().joinCommunity(communityId);
      await _authenticationService
          .checkCurrentUserStatus(); // Refresh user data locally
      HapticFeedback.lightImpact();
      InAppNotificationBanner.show(
        title: 'Joined Community!',
        body: 'You can now participate and post threads.',
        type: 'request_accepted',
      );
    } catch (e) {
      debugPrint("Error joining community: $e");
    } finally {
      _joiningCommunities.remove(communityId);
      notifyListeners();
    }
  }

  Future<void> sendChatRequest(AppUser volunteer) async {
    final currentUser = _authenticationService.currentUser;
    if (currentUser == null) return;

    setBusy(true); // Show loading while checking
    try {
      // Block check: admins can temporarily bar a volunteer from a user.
      final isBlocked = await locator<BlockService>()
          .isBlocked(currentUser.uid, volunteer.uid);
      if (isBlocked) {
        await _dialogService.showDialog(
          title: 'Unavailable',
          description:
              'You can\'t start a chat with this volunteer right now. Please choose another volunteer.',
          buttonTitle: 'OK',
        );
        setBusy(false);
        return;
      }

      // ✅ Check for existing request first
      bool requestExists = await locator<ChatRequestService>()
          .checkExistingRequest(currentUser.uid, volunteer.uid);

      if (requestExists) {
        await _dialogService.showDialog(
          title: 'Request Already Sent',
          description:
              'You already have an active or pending request with this volunteer.',
          buttonTitle: 'OK',
        );
        setBusy(false);
        return; // Stop execution
      }

      // --- If no request exists, proceed to create one ---
      final request = ChatRequest(
        requesterId: currentUser.uid,
        requesterName: currentUser.fullName,
        requesterAvatarUrl: currentUser.profilePictureUrl,
        volunteerId: volunteer.uid,
      );
      final result =
          await locator<ChatRequestService>().sendChatRequest(request);

      // Free user is out of welcome chats — show the paywall instead.
      if (result.capReached) {
        locator<AnalyticsService>().logGateHit(feature: PaywallFeature.welcomeChat);
        setBusy(false);
        await PaywallHelper.show(feature: PaywallFeature.welcomeChat);
        return;
      }
      // Success is handled by the stream listener updating the UI state.
    } catch (e) {
      await _dialogService.showDialog(
          title: 'Error', description: 'Could not send request.');
    } finally {
      setBusy(false);
    }
  }

  void listenForSentRequests() {
    final userId = _authenticationService.currentUser?.uid;
    if (userId == null) return;

    _sentRequestsSubscription?.cancel();
    _sentRequestsSubscription = locator<ChatRequestService>()
        .getUserSentRequestsStream(userId)
        .listen((requests) {
      // Prioritized Logic:
      final acceptedRequest = requests.firstWhereOrNull(
        (req) => req.status == 'accepted',
      );

      ChatRequest? foundPendingRequest; // Temporary variable

      if (acceptedRequest != null) {
        _activeChatRequest = acceptedRequest;
        _pendingRequest = null;
      } else {
        _activeChatRequest = null;
        // Use the temporary variable here
        foundPendingRequest = requests.firstWhereOrNull(
          (req) => req.status == 'pending',
        );
        _pendingRequest = foundPendingRequest;
      }

      // --- Update volunteer list visibility ---
      if (hasActiveInteraction) {
        if (_volunteers.isNotEmpty) {
          _volunteers = [];
          _volunteersSubscription?.cancel();
          // No need for extra notifyListeners here, the one at the end handles it
        }
      } else if (_volunteers.isEmpty && !isBusy) {
        listenToVolunteers();
      }

      notifyListeners(); // Update UI with the correct state
    }, onError: (error) {
      debugPrint("Error fetching sent requests: $error");
      _pendingRequest = null; // Clear state on error
      _activeChatRequest = null;
      notifyListeners();
    });
  }

  Future<void> cancelRequest(ChatRequest request) async {
    if (request.id == null || request.status != 'pending') return;

    final response = await _dialogService.showConfirmationDialog(
        title: 'Cancel Request',
        description: 'Are you sure you want to cancel your request to chat?',
        confirmationTitle: 'Yes, Cancel',
        cancelTitle: 'No');

    if (response?.confirmed == true) {
      try {
        await locator<ChatRequestService>().cancelRequest(request.id!);
      } catch (e) {
        await _dialogService.showDialog(
            title: 'Error', description: 'Could not cancel request.');
      }
    }
  }

  void navigateToActiveChat() {
    if (activeChatRequest == null) return;

    final volunteerId = activeChatRequest!.volunteerId;
    final requestId = activeChatRequest!.id!;
    final AppUser? volunteer = _volunteers.firstWhereOrNull(
      (v) => v.uid == volunteerId, // Correct way to handle orElse with null
    );
    String volunteerName = volunteer?.fullName ?? "Volunteer";

    // 4. Navigate to the chat view.
    _navigationService.navigateToChatView(
      volunteerId: volunteerId,
      volunteerName: volunteerName,
      requestId: requestId,
    );
  }

  void listenToVolunteers() {
    // CONDITION ADDED: Only fetch if no pending/active request exists.
    if (hasActiveInteraction) return;

    setBusy(true);
    _volunteersSubscription?.cancel();
    _volunteersSubscription = locator<UserService>()
        .streamAvailableVolunteers()
        .listen((volunteersList) async {
      // Exclude volunteers this user is temporarily blocked from (admin action).
      var roster = volunteersList;
      final userId = currentUser?.uid;
      if (userId != null) {
        final blocked =
            await locator<BlockService>().activeBlockedVolunteerIds(userId);
        if (blocked.isNotEmpty) {
          roster = roster.where((v) => !blocked.contains(v.uid)).toList();
        }
      }
      _volunteers = roster;

      final uids = roster.map((v) => v.uid).toSet();

      // Prune cached tags/ratings for volunteers no longer in the roster
      // (prevents unbounded growth of these maps over the session).
      _volunteerTags.removeWhere((uid, _) => !uids.contains(uid));
      _volunteerRatings.removeWhere((uid, _) => !uids.contains(uid));

      // Batch-fetch info only for volunteers we haven't loaded yet — a single
      // query instead of one read per volunteer (fixes the N+1).
      final missing =
          uids.where((uid) => !_volunteerTags.containsKey(uid)).toList();
      if (missing.isNotEmpty) {
        try {
          final infos = await locator<VolunteerService>().getMany(missing);
          for (final uid in missing) {
            final info = infos[uid];
            _volunteerTags[uid] = info?.tags ?? [];
            _volunteerRatings[uid] =
                (info != null && info.averageRating > 0)
                    ? info.averageRating
                    : 4.0;
          }
        } catch (e) {
          AppLog.error('HomeViewModel.listenToVolunteers', e);
        }
      }

      setBusy(false);
      notifyListeners();
    }, onError: (error) {
      AppLog.error('HomeViewModel.listenToVolunteers', error);
      setBusy(false);
    });
  }

  /// Live home-screen announcement (admin-authored), or null when none is
  /// active — the view then renders nothing.
  Stream<String?> get homeAnnouncement =>
      locator<AppContentService>().homeAnnouncement();

  Stream<List<Map<String, dynamic>>>? _communitiesStream;

  Stream<List<Map<String, dynamic>>> getCommunitiesStream() {
    _communitiesStream ??= locator<CommunityService>().getCommunities();
    return _communitiesStream!;
  }

  /// Gender-restricted communities, keyed by normalised name. A community not
  /// listed here is visible to everyone. The values are the genders allowed to
  /// see it (matched case-insensitively against the user's selected gender).
  static const Map<String, List<String>> _genderRestrictedCommunities = {
    "women's emotional wellness": ['female'],
    "new mothers support": ['female'],
    "men's mental health": ['male'],
    // "other than male or female" — the app's remaining gender options.
    'beyond binary support': ['other', 'prefer not to say'],
  };

  String _normalizeName(String value) =>
      value.trim().toLowerCase().replaceAll('’', "'");

  /// Filters the full [communities] list down to those the current user is
  /// allowed to see, based on their selected gender. Gender-restricted
  /// communities are hidden when the user's gender is unset or doesn't match.
  List<Map<String, dynamic>> visibleCommunities(
      List<Map<String, dynamic>> communities) {
    final gender = currentUser?.gender?.trim().toLowerCase();
    return communities.where((community) {
      // Prefer the explicit server-side list when present; it supersedes the
      // legacy name-based map (and is the eventual migration target).
      final explicit = (community['allowedGenders'] as List?)
          ?.map((e) => e.toString().trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();
      if (explicit != null && explicit.isNotEmpty) {
        if (gender == null) return false; // restricted, but user has no gender
        return explicit.contains(gender);
      }

      // Fallback: legacy name-based restriction (unchanged).
      final name = _normalizeName(community['name'] as String? ?? '');
      final allowedGenders = _genderRestrictedCommunities[name];
      if (allowedGenders == null) return true; // unrestricted → everyone
      if (gender == null) return false; // restricted, but user has no gender
      return allowedGenders.contains(gender);
    }).toList();
  }

  /// Navigates to the Community Chat View
  void navigateToCommunityChat({
    required String communityId,
    required String communityName,
  }) {
    // Assuming you have defined a CommunityChatView in your AppRouter.
    // Replace 'navigateToCommunityChatView' with your exact router method name.
    _navigationService.navigateToCommunityChatView(
      communityId: communityId,
      communityName: communityName,
    );
  }

  Future<void> logout() async {
    // Show loading state while signing out
    setBusy(true);
    try {
      await _authenticationService.signOut();
      // Navigate to the Welcome View after successful sign out
      _navigationService.replaceWith(Routes.welcomeView);
    } catch (e) {
      // Handle the error (e.g., show a dialog or snackbar)
      setError('Logout failed: $e');
      AppLog.error('HomeViewModel.logout', e);
    } finally {
      setBusy(false);
    }
  }

  void navigateToProfile() {
    _navigationService.navigateToProfileView();
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

  /// Listens for unread In-App notifications in the user's subcollection in real-time.
  void listenForNotifications() {
    final userId = _authenticationService.currentUser?.uid;
    if (userId == null) return;

    _notificationsSubscription?.cancel();

    bool isInitial = true;
    _notificationsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      _unreadNotificationsCount = snapshot.docs.length;
      notifyListeners();

      // Show sliding banner overlay in real-time when new notification document is added
      if (!isInitial) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data != null) {
              final title = data['title'] as String? ?? 'Notification';
              final body = data['body'] as String? ?? '';
              final type = data['type'] as String? ?? '';
              final customData = data['data'] as Map<String, dynamic>?;

              VoidCallback? onTap;
              if (type == 'request_accepted') {
                final requestId = customData?['requestId'] as String?;
                if (requestId != null) {
                  onTap = () {
                    _navigationService.replaceWithHomeView(initialIndex: 2);
                  };
                }
              } else if (type == 'new_message') {
                final chatId = customData?['chatId'] as String?;
                if (chatId != null) {
                  onTap = () {
                    final parts = chatId.split('_');
                    final volunteerId = parts.firstWhere((id) => id != userId,
                        orElse: () => '');
                    locator<NavigationService>().navigateToChatView(
                      volunteerId: volunteerId,
                      volunteerName: "Volunteer",
                      requestId: volunteerId,
                    );
                  };
                }
              } else if (type == 'request_received' || type == 'chat_request') {
                onTap = () {
                  setTab(0);
                };
              }

              // Show the sliding custom overlay banner
              InAppNotificationBanner.show(
                title: title,
                body: body,
                type: type,
                onTap: onTap,
              );
            }
          }
        }
      }
      isInitial = false;
    }, onError: (error) {
      debugPrint("Error listening for notifications: $error");
    });
  }

  /// Marks all unread user notifications as read in Firestore.
  Future<void> markAllNotificationsAsRead() async {
    final userId = _authenticationService.currentUser?.uid;
    if (userId == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      if (query.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in query.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint("Error marking notifications as read: $e");
    }
  }

  @override
  void dispose() {
    _sentRequestsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _volunteersSubscription?.cancel();
    _moodStreakSubscription?.cancel();
    super.dispose();
  }
}
