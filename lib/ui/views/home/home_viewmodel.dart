import 'dart:async';

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
import 'package:you_app/services/firestore_service.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/app_strings.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class HomeViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _authenticationService = locator<AuthenticationService>();
  final _firestoreService = locator<FirestoreService>();
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

  bool get hasActiveInteraction =>
      pendingRequest != null || activeChatRequest != null;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;
  String get counterLabel => 'Counter is: $_counter';
  String get currentUserName =>
      _authenticationService.currentUser?.firstName ?? 'there';

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
    fetchVolunteers();
    listenForSentRequests();
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

  Future<void> sendChatRequest(AppUser volunteer) async {
    final currentUser = _authenticationService.currentUser;
    if (currentUser == null) return;

    setBusy(true); // Show loading while checking
    try {
      // ✅ Check for existing request first
      bool requestExists = await _firestoreService.chatRequest
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
      await _firestoreService.chatRequest.sendChatRequest(request);
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
    _sentRequestsSubscription = _firestoreService.chatRequest
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
          // No need for extra notifyListeners here, the one at the end handles it
        }
      } else if (_volunteers.isEmpty && !isBusy) {
        fetchVolunteers();
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
        await _firestoreService.chatRequest.cancelRequest(request.id!);
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
  //   _volunteers = await _firestoreService.user.getAvailableVolunteers();
  //   setBusy(false);
  // }

  void fetchVolunteers() async {
    // CONDITION ADDED: Only fetch if no pending/active request exists.
    if (hasActiveInteraction) return;

    setBusy(true);
    try {
      _volunteers = await _firestoreService.user.getAvailableVolunteers();
    } catch (e) {
      // Handle error
    } finally {
      setBusy(false);
    }
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
    _sentRequestsSubscription?.cancel();
    super.dispose();
  }
}
