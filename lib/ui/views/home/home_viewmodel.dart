import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:you_app/services/auth_service.dart';
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
  List<ListenableServiceMixin> get listenableServices => [_authenticationService];
  // Secondary player for short sound effects (e.g., swipe)
  final AudioPlayer _fxPlayer = AudioPlayer();
  // Main player for soothing music audio
  final AudioPlayer _player = AudioPlayer();
  final _dialogService = locator<DialogService>();
  final _bottomSheetService = locator<BottomSheetService>();

  List<AppUser> _volunteers = [];
  List<AppUser> get volunteers => _volunteers;

  StreamSubscription? _sentRequestsSubscription;
  ChatRequest? _pendingRequest; // Holds the user's single pending request
  ChatRequest? get pendingRequest => _pendingRequest;
  ChatRequest? _activeChatRequest; // Holds the user's single accepted request
  ChatRequest? get activeChatRequest => _activeChatRequest;

  StreamSubscription? _notificationsSubscription;
  int _unreadNotificationsCount = 0;
  int get unreadNotificationsCount => _unreadNotificationsCount;

  StreamSubscription? _volunteersSubscription;

  bool get hasActiveInteraction =>
      pendingRequest != null || activeChatRequest != null;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;
  String get counterLabel => 'Counter is: $_counter';
  String get currentUserName =>
      _authenticationService.currentUser?.firstName ?? 'there';
  String get currentUserEmail =>
      _authenticationService.currentUser?.email ?? 'visitor@you.app';

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
    listenToVolunteers();
    listenForSentRequests();
    listenForNotifications();
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

  // Inside HomeViewModel...

  bool isCommunityJoined(String communityId) {
    final user = _authenticationService.currentUser;
    if (user == null) return false;
    return user.joinedCommunities.contains(communityId);
  }

  Future<void> joinCommunity(String communityId) async {
    try {
      await locator<CommunityService>().joinCommunity(communityId);
      await _authenticationService.checkCurrentUserStatus(); // Refresh user data locally
      notifyListeners();
      InAppNotificationBanner.show(
        title: 'Joined Community!',
        body: 'You can now participate and post threads.',
        type: 'request_accepted',
      );
    } catch (e) {
      debugPrint("Error joining community: $e");
    }
  }

  Future<void> sendChatRequest(AppUser volunteer) async {
    final currentUser = _authenticationService.currentUser;
    if (currentUser == null) return;

    setBusy(true); // Show loading while checking
    try {
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
      await locator<ChatRequestService>().sendChatRequest(request);
      // Success is handled by the stream listener updating the UI state.
    } catch (e) {
      await _dialogService.showDialog(
          title: 'Error', description: 'Could not send request.');
    } finally {
      setBusy(false);
    }
  }

  // Inside HomeViewModel...

  void listenForSentRequests() {
    final userId = _authenticationService.currentUser?.uid;
    if (userId == null) return;

    _sentRequestsSubscription?.cancel();
    _sentRequestsSubscription = locator<ChatRequestService>()
        .getUserSentRequestsStream(userId)
        .listen((requests) {
      // --- DEBUG PRINTS ---
      print(
          "Received ${requests.length} requests from Firestore."); // Should print 0
      if (requests.isEmpty) {
        print("Requests list is EMPTY.");
      }
      // --------------------

      // Prioritized Logic:
      final acceptedRequest = requests.firstWhereOrNull(
        (req) => req.status == 'accepted',
      );

      ChatRequest? foundPendingRequest = null; // Temporary variable

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

      // --- MORE DEBUG PRINTS ---
      print(
          "After processing: _activeChatRequest is null? ${_activeChatRequest == null}");
      print(
          "After processing: _pendingRequest is null? ${_pendingRequest == null}");
      // -------------------------

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

  // In HomeViewModel...

  Future<void> cancelRequest(ChatRequest request) async {
    if (request.id == null || request.status != 'pending') return;

    final response = await _dialogService.showConfirmationDialog(
        title: 'Cancel Request',
        description: 'Are you sure you want to cancel your request to chat?',
        confirmationTitle: 'Yes, Cancel',
        cancelTitle: 'No');

    if (response?.confirmed == true) {
      // ✅ Removed setBusy(true)
      try {
        await locator<ChatRequestService>().cancelRequest(request.id!);
        // The UI will update automatically when the stream listener
        // receives the empty list and calls notifyListeners.
        // fetchVolunteers will be triggered by the listener if needed.
      } catch (e) {
        // ✅ Removed setBusy(false) here - handle error differently if needed
        await _dialogService.showDialog(
            title: 'Error', description: 'Could not cancel request.');
      }
      // ✅ Removed finally { setBusy(false) }
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

  // void fetchVolunteers() async {
  //   setBusy(true);
  //   _volunteers = await locator<UserService>().getAvailableVolunteers();
  //   setBusy(false);
  // }

  void listenToVolunteers() {
    // CONDITION ADDED: Only fetch if no pending/active request exists.
    if (hasActiveInteraction) return;

    setBusy(true);
    _volunteersSubscription?.cancel();
    _volunteersSubscription = locator<UserService>()
        .streamAvailableVolunteers()
        .listen((volunteersList) {
      _volunteers = volunteersList;
      setBusy(false);
      notifyListeners();
    }, onError: (error) {
      setBusy(false);
    });
  }

  Stream<List<Map<String, dynamic>>>? _communitiesStream;

  Stream<List<Map<String, dynamic>>> getCommunitiesStream() {
    _communitiesStream ??= locator<CommunityService>().getCommunities();
    return _communitiesStream!;
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
      // In a real app, you might want a better error display
      print('Logout Error: $e');
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
                    final volunteerId = parts.firstWhere((id) => id != userId, orElse: () => '');
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
    _player.dispose();
    _sentRequestsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _volunteersSubscription?.cancel();
    super.dispose();
  }
}
