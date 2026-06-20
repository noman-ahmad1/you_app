import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/app/app.router.dart';

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/models/chat_messaage_model.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/moderation_flag_service.dart';
import 'package:you_app/services/moderation_service.dart';
import 'package:you_app/services/user_service.dart';
import 'package:you_app/services/volunteer_service.dart';
import 'package:you_app/services/mood_service.dart';
import 'package:you_app/services/journal_service.dart';
import 'package:you_app/services/chat_service.dart';
import 'package:you_app/services/chat_request_service.dart';
import 'package:you_app/ui/views/chat/widgets/review_dialog.dart';
import 'package:you_app/services/community_service.dart';

class ChatViewModel extends StreamViewModel<List<ChatMessage>> {
  // --- Services ---
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _authenticationService = locator<AuthenticationService>();
  final _snackbarService = locator<SnackbarService>();

  // --- Properties passed from the View ---
  final String volunteerId;
  final String volunteerName;
  final String requestId;

  // --- State ---
  final messageController = TextEditingController();

  bool _isDeleting = false;

  List<ChatMessage> get messages => data ?? [];

  String? _chatId;

  static bool isActive = false;
  static String? activeChatId;

  StreamSubscription<DocumentSnapshot>? _chatStatusSubscription;

  ChatViewModel({
    required this.volunteerId,
    required this.volunteerName,
    required this.requestId,
  }) {
    isActive = true;
    _initPresence();
  }

  Future<void> _initPresence() async {
    final userId = currentUserId;
    if (userId == null) return;
    final ids = [userId, volunteerId];
    ids.sort();
    final chatId = ids.join('_');
    try {
      await locator<ChatService>().setChatPresence(chatId, userId, true);
    } catch (_) {}
  }

  /// The current user's ID, for checking who sent a message.
  String? get currentUserId => _authenticationService.currentUser?.uid;

  @override
  Stream<List<ChatMessage>> get stream {
    final userId = currentUserId;
    if (userId == null) {
      return const Stream.empty();
    }

    // Sort UIDs to create a consistent, predictable chat ID.
    final ids = [userId, volunteerId];
    ids.sort();
    _chatId = ids.join('_');
    activeChatId = _chatId;

    _listenToChatStatus();

    return locator<ChatService>().getChatMessagesStream(_chatId!);
  }

  @override
  void onData(List<ChatMessage>? data) {
    setBusy(false);
  }

  @override
  void onError(error, StackTrace? stackTrace) {
    if (_isDeleting) return;
    setBusy(false);
    _snackbarService.showSnackbar(
        message: "Error fetching chat messages: $error");
  }

  void _listenToChatStatus() {
    if (_chatId == null || _chatStatusSubscription != null) return;
    _chatStatusSubscription = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) {
        if (snapshot.metadata.isFromCache) return;
        _handleChatEndedRemotely();
        return;
      }
      final data = snapshot.data();
      if (data != null && data['status'] == 'completed') {
        if (snapshot.metadata.isFromCache) return;
        _handleChatEndedRemotely(byAdmin: data['endedBy'] == 'admin');
      }
    });
  }

  void _handleChatEndedRemotely({bool byAdmin = false}) {
    if (_isDeleting) return;
    _isDeleting = true;
    _snackbarService.showSnackbar(
      message: byAdmin
          ? "This chat was ended by a moderator."
          : "This chat has been ended.",
    );
    _navigateAway();
  }

  void _navigateAway() {
    final isVolunteer = _authenticationService.currentUser?.isVolunteer ?? false;
    if (isVolunteer) {
      _navigationService.clearStackAndShow(Routes.volunteerHomeView);
    } else {
      _navigationService.clearStackAndShow(Routes.homeView, arguments: const HomeViewArguments(initialIndex: 2));
    }
  }

  /// Sends a message to Firestore, after a moderation check.
  Future<void> sendMessage() async {
    final textToSend = messageController.text.trim();
    if (textToSend.isEmpty || _chatId == null || currentUserId == null) {
      return;
    }

    // --- Moderation gate (stricter chat context) ---
    final moderation = locator<ModerationService>()
        .inspect(textToSend, context: ModerationContext.chat);

    if (moderation.isBlocked) {
      // Severe content (hate/violence/sexual): do NOT send; warn the sender and
      // record an admin flag for the blocked attempt.
      await _dialogService.showDialog(
        title: 'Message not sent',
        description:
            'This message appears to violate our community guidelines and was not sent. Repeated violations may be reviewed by a moderator.',
        buttonTitle: 'OK',
      );
      locator<AnalyticsService>().logContentBlocked(
          source: 'chat', category: moderation.categoryNames.join(','));
      locator<ModerationFlagService>().recordBlocked(
        context: ModerationContext.chat,
        senderId: currentUserId!,
        recipientId: volunteerId,
        chatId: _chatId,
        text: textToSend,
        result: moderation,
      );
      return; // keep the text in the field so the sender can edit it
    }

    if (moderation.action == ModerationAction.maskSend) {
      _snackbarService.showSnackbar(
        message:
            'For your safety, sharing contact details is discouraged — it will be hidden from the other person.',
      );
    } else if (moderation.action == ModerationAction.warnSend) {
      _snackbarService.showSnackbar(
        message: 'Please keep the conversation supportive and on-topic.',
      );
    }

    // Create the message object. The timestamp will be set by the server.
    // Raw text is stored so moderators see the full content; the recipient's
    // client blurs PII at render time, and the Cloud Function flags it.
    final message = ChatMessage(
      senderId: currentUserId!,
      text: textToSend,
    );

    // Clear the input field immediately for a snappy UI response.
    messageController.clear();

    // Call the service to send the message.
    try {
      await locator<ChatService>().sendMessage(_chatId!, message);
    } catch (e) {
      // Handle potential send errors (e.g., show a 'failed to send' icon)
      _snackbarService.showSnackbar(
        title: 'Error',
        message: 'Could not send message. Please try again.',
      );
    }
  }

  Future<void> deleteChat() async {
    // 1. Show Confirmation Dialog FIRST
    final response = await _dialogService.showConfirmationDialog(
      title: 'Delete Chat',
      description:
          'Are you sure you want to permanently delete this chat and the original request? This action cannot be undone.',
      confirmationTitle: 'Delete',
      cancelTitle: 'Cancel',
    );

    if (response?.confirmed == true) {
      _isDeleting = true;
      setBusy(true);
      try {
        await locator<ChatService>().deleteChatAndRequest(
          chatId: _chatId!,
          requestId: requestId,
        );
        _navigateAway();
      } catch (e) {
        setBusy(false);
        await _dialogService.showDialog(
            title: 'Error',
            description: 'Could not delete chat. Please try again.');
      }
    }
  }

  Future<void> endChat() async {
    final isVolunteer = _authenticationService.currentUser?.isVolunteer ?? false;

    final response = await _dialogService.showConfirmationDialog(
      title: 'End Chat',
      description: 'Are you sure you want to end this conversation?',
      confirmationTitle: 'End Chat',
      cancelTitle: 'Cancel',
    );

    if (response?.confirmed == true) {
      // If the current user is NOT the volunteer, prompt for a review
      if (!isVolunteer && _navigationService.navigatorKey?.currentContext != null) {
        final context = _navigationService.navigatorKey!.currentContext!;
        final reviewResult = await showDialog<Map<String, dynamic>>(
          context: context,
          barrierDismissible: false,
          builder: (context) => ReviewDialog(volunteerName: volunteerName),
        );

        if (reviewResult != null) {
          final rating = reviewResult['rating'] as double;
          final comment = reviewResult['comment'] as String;
          setBusy(true);
          try {
            await locator<VolunteerService>().addReviewAndCompleteChat(
              volunteerId: volunteerId,
              userId: currentUserId!,
              rating: rating,
              comment: comment,
            );
          } catch (e) {
            debugPrint("Failed to save review: $e");
          }
        }
      }

      _isDeleting = true;
      setBusy(true);
      try {
        await locator<ChatService>().endChatAndRequest(
          chatId: _chatId!,
          requestId: requestId,
        );
        _navigateAway();
      } catch (e) {
        setBusy(false);
        await _dialogService.showDialog(
            title: 'Error',
            description: 'Could not end chat. Please try again.');
      }
    }
  }

  void back() {
    _navigationService.back();
  }

  @override
  void dispose() {
    _chatStatusSubscription?.cancel();
    isActive = false;
    activeChatId = null;
    if (_chatId != null && currentUserId != null) {
      locator<ChatService>().setChatPresence(_chatId!, currentUserId!, false);
    }
    messageController.dispose();
    super.dispose();
  }
}
