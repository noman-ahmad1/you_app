import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/chatbot_service.dart';
import 'package:you_app/services/monetization_service.dart';
import 'package:you_app/ui/views/paywall/paywall_helper.dart';

class ChatbotViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _chatbotService = locator<ChatbotService>();
  final _analytics = locator<AnalyticsService>();
  final _authService = locator<AuthenticationService>();
  final _monetizationService = locator<MonetizationService>();
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

  /// True once the free daily Dodo cap has been hit this session. Drives the
  /// persistent "unlock unlimited Dodo" button in the chat.
  bool _dailyCapReached = false;
  bool get dailyCapReached => _dailyCapReached;

  ChatbotViewModel() {
    _loadMessages();
    // Show the "limit reached" button immediately if the user is already capped
    // (persists across restarts until Premium or the daily reset), and keep it
    // in sync when Premium is granted mid-session.
    _refreshCapStatus();
    _authService.addListener(_refreshCapStatus);
  }

  Future<void> _refreshCapStatus() async {
    final capped = await _monetizationService.isDodoDailyCapReached();
    if (capped != _dailyCapReached) {
      _dailyCapReached = capped;
      notifyListeners();
    }
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

  /// Opens the Premium paywall from the Dodo cap-reached button.
  Future<void> openPaywall() async {
    _analytics.logGateHit(feature: PaywallFeature.dodo);
    await PaywallHelper.show(feature: PaywallFeature.dodo);
  }

  /// Sends the current message in the input field to Gemini API
  Future<void> sendMessage() async {
    // Already capped today — don't waste a call; nudge to the paywall instead.
    if (_dailyCapReached) {
      await openPaywall();
      return;
    }

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
      // 2. Fetch Dodo's response via the callable (server enforces the cap).
      final DodoResponse response =
          await _chatbotService.generateResponse(_messages);

      // 2a. Free daily cap reached — surface a gentle note + persistent upgrade
      // button (via _dailyCapReached), and open the paywall once immediately.
      if (response.capReached) {
        _analytics.logGateHit(feature: PaywallFeature.dodo);
        _dailyCapReached = true;
        _messages.add({
          'isMe': 'false',
          'text':
              "You've reached today's free messages with me. I'll be right here "
                  "again tomorrow — or unlock unlimited chats with Premium. 💛"
        });
        _saveMessages();
        setBusy(false);
        notifyListeners();
        await PaywallHelper.show(feature: PaywallFeature.dodo);
        return;
      }

      // 3. Add AI response to UI
      _messages.add({'isMe': 'false', 'text': response.reply});
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
    _authService.removeListener(_refreshCapStatus);
    messageController.dispose();
    super.dispose();
  }
}
