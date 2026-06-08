import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/models/app_user.dart';
import 'package:you_app/ui/shared/in_app_notification_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/models/chat_request_model.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/user_service.dart';
import 'package:you_app/services/volunteer_service.dart';
import 'package:you_app/services/mood_service.dart';
import 'package:you_app/services/journal_service.dart';
import 'package:you_app/services/chat_service.dart';
import 'package:you_app/services/chat_request_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/services/community_service.dart';

class VolunteerHomeViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _authenticationService = locator<AuthenticationService>();
  final _dialogService = locator<DialogService>();

  StreamSubscription? _requestsSubscription;
  List<ChatRequest> _pendingRequests = [];
  List<ChatRequest> get pendingRequests =>
      _pendingRequests; // Renamed for clarity

  // --- State for Active Chats (Accepted Requests) ---
  StreamSubscription? _activeChatsSubscription;
  List<ChatRequest> _activeChats = [];
  List<ChatRequest> get activeChats =>
      _activeChats; // New list for active chats

  StreamSubscription? _notificationsSubscription;
  int _unreadNotificationsCount = 0;
  int get unreadNotificationsCount => _unreadNotificationsCount;

  bool _isBusyRequests = false;
  bool get isBusyRequests => _isBusyRequests;

  bool _isBusyActiveChats = false;
  bool get isBusyActiveChats => _isBusyActiveChats;

  final ReactiveValue<bool> _isAvailable = ReactiveValue<bool>(false);
  bool get isAvailable => _isAvailable.value;
  String get availabilityStatusString => isAvailable ? "Online" : "Offline";

  String get currentUserName =>
      _authenticationService.currentUser?.firstName ?? 'Volunteer';

  String? get currentUserProfileUrl =>
      _authenticationService.currentUser?.profilePictureUrl;

  AppUser? get currentUser => _authenticationService.currentUser;

  final GlobalKey requestsKey = GlobalKey();
  final GlobalKey homeFeedKey = GlobalKey();
  final GlobalKey dashboardKey = GlobalKey();

  Future<void> checkAndStartShowcase(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenVolunteerShowcase') ?? false;
    if (!hasSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShowCaseWidget.of(context).startShowCase([
          requestsKey,
          homeFeedKey,
          dashboardKey,
        ]);
      });
      await prefs.setBool('hasSeenVolunteerShowcase', true);
    }
  }

  VolunteerHomeViewModel() {
    _fetchInitialAvailability();
    listenForRequests();
    listenForActiveChats();
    listenForNotifications();
  }

  int _counter = 0;
  int currentIndex = 1;
  void onTabTapped(int index) {
    currentIndex = index;
    notifyListeners();
  }

  void incrementCounter() {
    _counter++;
    rebuildUi();
  }

  void initialize() {
    // Load initial data, etc.
  }

  final List<GlobalKey<NavigatorState>> navigatorKeys = [
    GlobalKey<NavigatorState>(), // Pending Chat
    GlobalKey<NavigatorState>(), // Active Chat
    GlobalKey<NavigatorState>(), // Dashboard
  ];

  Future<void> _fetchInitialAvailability() async {
    final userId = _authenticationService.currentUser?.uid;
    if (userId == null) return;
    try {
      final userDoc = await locator<UserService>().get(userId);
      final currentStatus = userDoc?['availabilityStatus'] as String?;
      _isAvailable.value = (currentStatus == 'online');
    } catch (e) {
      print("Error fetching availability status: $e");
      _isAvailable.value = false; // Default to offline on error
    }
    notifyListeners(); // Update UI with fetched status
  }

  /// Toggles the volunteer's availability status.
  Future<void> toggleAvailability(bool newStatus) async {
    final userId = _authenticationService.currentUser?.uid;
    if (userId == null) return;

    final newStatusString = newStatus ? "online" : "offline";

    // Optimistically update the UI first
    _isAvailable.value = newStatus;
    notifyListeners();

    // Then update Firestore in the background
    try {
      await locator<UserService>()
          .updateUserAvailability(userId, newStatusString);
    } catch (e) {
      // Revert UI on error and show message
      _isAvailable.value = !newStatus; // Revert
      notifyListeners();
      _dialogService.showDialog(
          title: 'Error',
          description: 'Could not update your status. Please try again.');
      print("Error updating availability: $e");
    }
  }

  /// Listens for incoming PENDING chat requests.
  void listenForRequests() {
    final volunteerId = _authenticationService.currentUser?.uid;
    if (volunteerId == null) return;

    _isBusyRequests = true; // Use specific flag
    notifyListeners(); // Update UI immediately

    _requestsSubscription?.cancel();
    _requestsSubscription = locator<ChatRequestService>()
        .getVolunteerPendingChatsStream(volunteerId)
        .listen((newRequests) {
      _pendingRequests = newRequests;
      _isBusyRequests = false; // Clear specific flag
      notifyListeners();
    }, onError: (error) {
      _isBusyRequests = false; // Clear specific flag
      print("Error listening for pending requests: $error");
      notifyListeners();
    });
  }

  /// Listens for ACCEPTED chat requests (active chats).
  void listenForActiveChats() {
    final volunteerId = _authenticationService.currentUser?.uid;
    if (volunteerId == null) return;

    _isBusyActiveChats = true; // Use specific flag
    notifyListeners(); // Update UI immediately

    _activeChatsSubscription?.cancel();
    _activeChatsSubscription = locator<ChatRequestService>()
        .getVolunteerActiveChatsStream(volunteerId)
        .listen((newChats) {
      _activeChats = newChats;
      _isBusyActiveChats = false; // Clear specific flag
      notifyListeners();
    }, onError: (error) {
      _isBusyActiveChats = false; // Clear specific flag
      print("Error listening for active chats: $error");
      notifyListeners();
    });
  }

  /// Accepts a request, creates the chat, and navigates to the chat screen.
  Future<void> acceptRequest(ChatRequest request) async {
    // Show loading specifically for this action
    setBusyForObject(request.id, true);
    try {
      await locator<ChatRequestService>()
          .acceptRequest(request, currentUserName, currentUserProfileUrl);
      // Pending list updates automatically via stream.
      // Active chat list updates automatically via stream.

      // Navigate to the chat view
      _navigationService.navigateToChatView(
        volunteerId: request.requesterId,
        volunteerName: request.requesterName,
        requestId: request.id!,
      );
    } catch (e) {
      print("Error accepting request: $e");
      _dialogService.showDialog(
          title: 'Error', description: 'Could not accept request.');
    } finally {
      setBusyForObject(request.id, false);
      // Ensure main busy state reflects combined stream loading
      setBusy(_pendingRequests.isEmpty && _activeChats.isEmpty);
    }
  }

  Future<void> declineRequest(ChatRequest request) async {
    if (request.id == null) return;
    setBusyForObject(
        request.id, true); // Indicate activity for this specific request
    try {
      await locator<ChatRequestService>().declineRequest(request.id!);
      // Request disappears automatically via the pending stream listener.
    } catch (e) {
      print("Error declining request: $e");
      _dialogService.showDialog(
          title: 'Error', description: 'Could not decline request.');
    } finally {
      setBusyForObject(request.id, false);
      // Ensure main busy state reflects combined stream loading
      setBusy(_pendingRequests.isEmpty && _activeChats.isEmpty);
    }
  }

  void navigateToActiveChat(ChatRequest acceptedRequest) {
    _navigationService.navigateToChatView(
      volunteerId: acceptedRequest.requesterId,
      volunteerName: acceptedRequest.requesterName,
      requestId: acceptedRequest.id ?? "",
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

  void navigateToVolunteerEditProfile() {
    _navigationService.navigateTo(Routes.volunteerEditProfileView);
  }

  void setTab(int index) {
    if (index == 0) {
      markAllNotificationsAsRead();
    }
    if (index == currentIndex) {
      navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      currentIndex = index;
      notifyListeners();
    }
  }

  /// Listens for unread In-App notifications in the user's subcollection in real-time.
  void listenForNotifications() {
    final volunteerId = _authenticationService.currentUser?.uid;
    if (volunteerId == null) return;

    _notificationsSubscription?.cancel();

    bool isInitial = true;
    _notificationsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(volunteerId)
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
              if (type == 'request_received' || type == 'chat_request') {
                onTap = () {
                  setTab(0);
                };
              } else if (type == 'new_message') {
                final chatId = customData?['chatId'] as String?;
                if (chatId != null) {
                  onTap = () {
                    final parts = chatId.split('_');
                    final requesterId = parts.firstWhere(
                        (id) => id != volunteerId,
                        orElse: () => '');
                    _navigationService.navigateToChatView(
                      volunteerId: requesterId,
                      volunteerName: "User",
                      requestId: requesterId,
                    );
                  };
                }
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

  /// Marks all unread volunteer notifications as read in Firestore.
  Future<void> markAllNotificationsAsRead() async {
    final volunteerId = _authenticationService.currentUser?.uid;
    if (volunteerId == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .doc(volunteerId)
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
    _requestsSubscription?.cancel();
    _activeChatsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    super.dispose();
  }
}
