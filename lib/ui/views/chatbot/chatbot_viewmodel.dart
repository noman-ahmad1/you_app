import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/chatbot_service.dart';

class ChatbotViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _chatbotService = locator<ChatbotService>();

  final TextEditingController messageController = TextEditingController();

  // Local state for chat history
  // Messages format: {'isMe': 'true'/'false', 'text': 'message string'}
  final List<Map<String, String>> _messages = [
    {
      'isMe': 'false', 
      'text': 'Hi there! I am Dodo, your mental health companion. How are you feeling today?'
    }
  ];

  List<Map<String, String>> get messages => _messages;

  /// Sends the current message in the input field to Gemini API
  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    // 1. Add user message to UI immediately
    _messages.add({'isMe': 'true', 'text': text});
    messageController.clear();
    
    // Set busy state to show loading indicator for Dodo's typing
    setBusy(true);

    try {
      // 2. Fetch response from Gemini via Service Layer
      String response = await _chatbotService.generateResponse(_messages);
      
      // 3. Add AI response to UI
      _messages.add({'isMe': 'false', 'text': response});
    } catch (e) {
      // Setup error response if fetch fails
      _messages.add({
        'isMe': 'false', 
        'text': "I'm sorry, I'm having trouble connecting right now. Can we try again?"
      });
    } finally {
      // Turn off loading state to render new messages
      setBusy(false);
    }
  }

  Future<void> back() async {
    _navigationService.back();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}
