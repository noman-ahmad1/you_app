import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:you_app/services/base/app_log.dart';

/// Centralised, privacy-safe wrapper around Firebase Analytics + Crashlytics.
///
/// This is a mental-health app: free-text content (journal/mood/chat/community
/// text, OTP codes, full phone numbers) must NEVER be sent to analytics. The
/// typed `log*` methods below only accept structural metadata (ids, enum
/// labels, counts, durations, booleans), which makes leaking content hard by
/// construction. Use these methods instead of calling FirebaseAnalytics
/// directly.
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  static const String _consentKey = 'analytics_consent';

  /// Collection is on by default; the user can opt out in settings.
  bool _enabled = true;
  bool get isEnabled => _enabled;

  /// Navigator observer that auto-logs `screen_view` from route names.
  /// Cached so MaterialApp rebuilds reuse the same instance.
  late final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Loads persisted consent and applies it to both SDKs. Call once at startup.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_consentKey) ?? true;
      await _applyCollection(_enabled);
    } catch (e) {
      AppLog.error('AnalyticsService.init', e);
    }
  }

  /// Enables/disables collection for Analytics + Crashlytics and persists it.
  Future<void> setCollectionEnabled(bool enabled) async {
    _enabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_consentKey, enabled);
      await _applyCollection(enabled);
    } catch (e) {
      AppLog.error('AnalyticsService.setCollectionEnabled', e);
    }
  }

  Future<void> _applyCollection(bool enabled) async {
    await _analytics.setAnalyticsCollectionEnabled(enabled);
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  // --- User identity / properties (no PII beyond uid) ---

  Future<void> setUser({
    required String uid,
    String? role,
    String? gender,
    String? status,
  }) async {
    if (!_enabled) return;
    await _safe('setUser', () async {
      await _analytics.setUserId(id: uid);
      await _crashlytics.setUserIdentifier(uid);
      if (role != null) await _analytics.setUserProperty(name: 'role', value: role);
      if (gender != null) {
        await _analytics.setUserProperty(name: 'gender', value: gender);
      }
      if (status != null) {
        await _analytics.setUserProperty(name: 'account_status', value: status);
      }
    });
  }

  Future<void> clearUser() async {
    await _safe('clearUser', () async {
      await _analytics.setUserId(id: null);
    });
  }

  // --- Auth ---
  Future<void> logSignUp({required String method, required String role}) =>
      _log('sign_up', {'method': method, 'role': role});
  Future<void> logLogin({required String method}) =>
      _log('login', {'method': method});
  Future<void> logLogout() => _log('logout', null);
  Future<void> logAccountDeleted({required String role}) =>
      _log('account_deleted', {'role': role});
  Future<void> logPhoneOtpSent() => _log('phone_otp_sent', null);
  Future<void> logPhoneVerified() => _log('phone_verified', null);

  // --- Email verification ---
  // [context] is a coarse label for WHERE it fired (e.g. 'premium_purchase',
  // 'nudge_home', 'nudge_profile', 'volunteer_block', 'volunteer_profile').
  // Never log the email address or any PII.
  Future<void> logVerificationGateHit({required String context}) =>
      _log('verification_gate_hit', {'context': context});
  Future<void> logVerificationPrompted({required String context}) =>
      _log('verification_prompted', {'context': context});
  Future<void> logVerificationEmailSent({required String context}) =>
      _log('verification_email_sent', {'context': context});
  Future<void> logVerificationCompleted({required String context}) =>
      _log('verification_completed', {'context': context});

  // --- Journal ---
  Future<void> logJournalCreated({String? label}) =>
      _log('journal_created', {'label': label});
  Future<void> logJournalUpdated({String? label}) =>
      _log('journal_updated', {'label': label});
  Future<void> logJournalDeleted() => _log('journal_deleted', null);

  // --- Mood ---
  Future<void> logMoodLogged({required String moodLabel}) =>
      _log('mood_logged', {'mood_label': moodLabel});
  Future<void> logMoodStreak({required int days}) =>
      _log('mood_streak', {'days': days});

  // --- Chatbot (Dodo) ---
  Future<void> logChatbotMessageSent() => _log('chatbot_message_sent', null);
  Future<void> logChatbotResponse({int? latencyMs}) =>
      _log('chatbot_response', {'latency_ms': latencyMs});

  // --- Community ---
  Future<void> logCommunityPost({required String communityId}) =>
      _log('community_post_created', {'community_id': communityId});
  Future<void> logCommunityReply({required String postId}) =>
      _log('community_reply_created', {'post_id': postId});
  Future<void> logCommunityJoined({required String communityId}) =>
      _log('community_joined', {'community_id': communityId});
  Future<void> logPostLiked({required bool liked}) =>
      _log('community_post_like', {'liked': liked});

  // --- Peer chat ---
  Future<void> logChatRequestSent() => _log('chat_request_sent', null);
  Future<void> logChatRequestAccepted() => _log('chat_request_accepted', null);
  Future<void> logChatRequestDeclined() => _log('chat_request_declined', null);
  Future<void> logChatMessageSent() => _log('chat_message_sent', null);
  Future<void> logChatEnded({bool? reviewed}) =>
      _log('chat_ended', {'reviewed': reviewed});

  // --- Monetization ---
  Future<void> logSubscriptionGate(
          {required bool required, required int daysSinceLogin}) =>
      _log('subscription_gate',
          {'required': required, 'days_since_login': daysSinceLogin});

  /// A free user hit a premium gate for [feature] (e.g. 'dodo', 'welcome_chat',
  /// 'journal_history', 'mood_window').
  Future<void> logGateHit({required String feature}) =>
      _log('premium_gate_hit', {'feature': feature});

  /// The paywall screen was shown, attributed to the [feature] that triggered it.
  Future<void> logPaywallShown({required String feature}) =>
      _log('paywall_shown', {'feature': feature});

  /// The user tapped the upgrade CTA on the paywall.
  Future<void> logUpgradeCtaTapped({required String feature}) =>
      _log('paywall_upgrade_tapped', {'feature': feature});

  /// A purchase flow was launched for [plan] ('monthly' | 'yearly'). No amounts
  /// or payment/PII data are ever logged.
  Future<void> logPurchaseStarted({required String plan}) =>
      _log('purchase_started', {'plan': plan});

  /// A purchase completed for [plan].
  Future<void> logPurchaseCompleted({required String plan}) =>
      _log('purchase_completed', {'plan': plan});

  /// A purchase failed. [reason] is a coarse code (e.g. 'cancelled', 'network',
  /// 'store_error') — never a raw message or payment detail.
  Future<void> logPurchaseFailed({required String reason}) =>
      _log('purchase_failed', {'reason': reason});

  /// The user tapped "Restore purchase".
  Future<void> logRestoreTapped() => _log('restore_tapped', null);

  // --- Onboarding ---
  Future<void> logOnboardingCompleted({required String tour}) =>
      _log('onboarding_completed', {'tour': tour});

  // --- Moderation ---
  Future<void> logContentBlocked({required String source, String? category}) =>
      _log('content_blocked', {'source': source, 'category': category});
  Future<void> logContentFlagged({required String source, String? category}) =>
      _log('content_flagged', {'source': source, 'category': category});

  // --- Internals ---

  /// Logs an event, dropping null params. No-op when collection is disabled.
  Future<void> _log(String name, Map<String, Object?>? params) async {
    if (!_enabled) return;
    final clean = <String, Object>{};
    params?.forEach((key, value) {
      if (value == null) return;
      // Firebase Analytics only accepts String/num param values and asserts on
      // anything else in debug builds. Coerce bools to 1/0 so no event (current
      // or future) can trip that assertion — e.g. subscription_gate.required.
      clean[key] = value is bool ? (value ? 1 : 0) : value;
    });
    await _safe(name, () => _analytics.logEvent(
          name: name,
          parameters: clean.isEmpty ? null : clean,
        ));
  }

  Future<void> _safe(String context, Future<void> Function() op) async {
    try {
      await op();
    } catch (e) {
      // Analytics must never break a user flow.
      AppLog.error('AnalyticsService.$context', e);
    }
  }
}
