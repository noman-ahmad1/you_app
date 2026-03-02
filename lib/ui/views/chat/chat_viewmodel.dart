import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/models/chat_messaage_model.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/firestore_service.dart';

class ChatViewModel extends BaseViewModel {
  // --- Services ---
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _firestoreService = locator<FirestoreService>();
  final _authenticationService = locator<AuthenticationService>();

  // --- Properties passed from the View ---
  final String volunteerId;
  final String volunteerName;
  final String requestId;

  // --- State ---
  final messageController = TextEditingController();
  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  StreamSubscription? _messageStreamSubscription;
  String? _chatId;

  ChatViewModel({
    required this.volunteerId,
    required this.volunteerName,
    required this.requestId,
  });

  /// The current user's ID, for checking who sent a message.
  String? get currentUserId => _authenticationService.currentUser?.uid;

  /// Initializes the chat by creating the chat ID and listening for messages.
  void listenToMessages() {
    final userId = currentUserId;
    if (userId == null) {
      // Handle error: user not logged in
      return;
    }

    // Sort UIDs to create a consistent, predictable chat ID.
    // This ensures both the user and volunteer access the same chat room.
    final ids = [userId, volunteerId];
    ids.sort();
    _chatId = ids.join('_');

    setBusy(true);

    // Listen to the real-time stream of messages from Firestore.
    _messageStreamSubscription = _firestoreService.chat
        .getChatMessagesStream(_chatId!)
        .listen((newMessages) {
      _messages = newMessages;
      setBusy(false);
      notifyListeners(); // Rebuild the UI with the new messages
    }, onError: (error) {
      setBusy(false);
      // Handle stream errors
      print("Error fetching chat messages: $error");
    });
  }

  /// Sends a message to Firestore.
  Future<void> sendMessage() async {
    final textToSend = messageController.text.trim();
    if (textToSend.isEmpty || _chatId == null || currentUserId == null) {
      return;
    }

    // Create the message object. The timestamp will be set by the server.
    final message = ChatMessage(
      senderId: currentUserId!,
      text: textToSend,
    );

    // Clear the input field immediately for a snappy UI response.
    messageController.clear();

    // Call the service to send the message.
    try {
      await _firestoreService.chat.sendMessage(_chatId!, message);
    } catch (e) {
      // Handle potential send errors (e.g., show a 'failed to send' icon)
      print("Error sending message: $e");
    }
  }

  Future<void> deleteChat() async {
    // 1. Show Confirmation Dialog FIRST
    final response = await _dialogService.showConfirmationDialog(
      title: 'Delete Chat',
      description:
          'Are you sure you want to permanently delete this chat and the original request? This action cannot be undone.',
      confirmationTitle: 'Delete', // Text for the confirmation button
      cancelTitle: 'Cancel', // Text for the cancel button
    );

    // 2. Check if the user confirmed
    if (response?.confirmed == true) {
      // 3. Proceed with deletion ONLY if confirmed
      setBusy(true);
      try {
        await _firestoreService.chat.deleteChatAndRequest(
          chatId: _chatId!,
          requestId: requestId,
        );
        _navigationService.back(); // Go back after successful deletion
      } catch (e) {
        setBusy(false); // Make sure busy is false on error
        // Show error dialog
        await _dialogService.showDialog(
            // Use await for dialogs
            title: 'Error',
            description: 'Could not delete chat. Please try again.');
      }
      // No finally block needed here
    }
    // If response?.confirmed is false or null, do nothing.
  }

  void back() {
    _navigationService.back();
  }

  @override
  void dispose() {
    // CRITICAL: Cancel the stream subscription to prevent memory leaks.
    _messageStreamSubscription?.cancel();
    messageController.dispose();
    super.dispose();
  }
}
