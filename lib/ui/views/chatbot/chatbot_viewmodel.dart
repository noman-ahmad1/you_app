import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/chatbot_service.dart';

class ChatbotViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _chatbotService = locator<ChatbotService>();
  final _analytics = locator<AnalyticsService>();
  final Box _box = Hive.box('chatbot_history');

  final TextEditingController messageController = TextEditingController();

  // Local state for chat history
  // Messages format: {'isMe': 'true'/'false', 'text': 'message string'}
  final List<Map<String, String>> _messages = [
    {
      'isMe': 'false',
      'text':
          'Hi there! I am Dodo, your mental health companion. How are you feeling today?'
    }
  ];

  List<Map<String, String>> get messages => _messages;

  ChatbotViewModel() {
    _loadMessages();
  }

  /// Loads stored messages from Hive if available
  void _loadMessages() {
    final stored = _box.get('messages');
    if (stored is List) {
      _messages.clear();
      for (var item in stored) {
        if (item is Map) {
          _messages.add({
            'isMe': item['isMe']?.toString() ?? 'false',
            'text': item['text']?.toString() ?? '',
          });
        }
      }
    }
  }

  /// Saves the current messages list to Hive
  void _saveMessages() {
    final serializable = _messages
        .map((m) => {
              'isMe': m['isMe'] ?? 'false',
              'text': m['text'] ?? '',
            })
        .toList();
    _box.put('messages', serializable);
  }

  /// Sends the current message in the input field to Gemini API
  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    // 1. Add user message to UI immediately
    _messages.add({'isMe': 'true', 'text': text});
    _saveMessages();
    messageController.clear();
    notifyListeners();
    _analytics.logChatbotMessageSent(); // metadata only, never the text

    // Set busy state to show loading indicator for Dodo's typing
    setBusy(true);
    final stopwatch = Stopwatch()..start();

    try {
      // 2. Fetch response from Gemini via Service Layer
      String response = await _chatbotService.generateResponse(_messages);

      // 3. Add AI response to UI
      _messages.add({'isMe': 'false', 'text': response});
      _saveMessages();
      _analytics.logChatbotResponse(latencyMs: stopwatch.elapsedMilliseconds);
    } catch (e) {
      // Setup error response if fetch fails
      _messages.add({
        'isMe': 'false',
        'text':
            // 'DEBUG ERROR: $e'
            "I'm sorry, I'm having trouble connecting right now. Can we try again?"
      });
      _saveMessages();
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
