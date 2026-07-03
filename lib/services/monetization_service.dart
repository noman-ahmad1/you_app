import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/base/app_log.dart';
import 'package:you_app/services/base/firestore_base.dart';
import 'package:you_app/ui/common/app_constants.dart';

class MonetizationService with ListenableServiceMixin, FirestoreServiceMixin {
  final AuthenticationService _authService = locator<AuthenticationService>();
  AnalyticsService get _analytics => locator<AnalyticsService>();

  final ReactiveValue<bool> _isSubscriptionRequired = ReactiveValue<bool>(false);
  final ReactiveValue<int> _daysSinceLogin = ReactiveValue<int>(0);

  // Free-tier limits, live-tunable via app_settings/global_config. Each falls
  // back to the AppConstants default when the key is missing (fail-open).
  final ReactiveValue<int> _dodoDailyCap =
      ReactiveValue<int>(AppConstants.dodoDailyCapDefault);
  final ReactiveValue<int> _welcomeChats =
      ReactiveValue<int>(AppConstants.welcomeChatsDefault);
  final ReactiveValue<int> _journalHistoryDays =
      ReactiveValue<int>(AppConstants.journalHistoryDaysDefault);
  final ReactiveValue<int> _moodWindowDays =
      ReactiveValue<int>(AppConstants.moodWindowDaysDefault);
  final ReactiveValue<int> _communityThreadsMonthly =
      ReactiveValue<int>(AppConstants.communityThreadsMonthlyDefault);
  final ReactiveValue<int> _communityRepliesMonthly =
      ReactiveValue<int>(AppConstants.communityRepliesMonthlyDefault);

  bool get isSubscriptionRequired => _isSubscriptionRequired.value;
  int get daysSinceLogin => _daysSinceLogin.value;

  /// Single source of truth for the current user's entitlement.
  bool get isPremium => _authService.currentUser?.isPremium ?? false;

  int get dodoDailyCap => _dodoDailyCap.value;
  int get welcomeChats => _welcomeChats.value;
  int get journalHistoryDays => _journalHistoryDays.value;
  int get moodWindowDays => _moodWindowDays.value;
  int get communityThreadsMonthly => _communityThreadsMonthly.value;
  int get communityRepliesMonthly => _communityRepliesMonthly.value;

  MonetizationService() {
    listenToReactiveValues([
      _isSubscriptionRequired,
      _daysSinceLogin,
      _dodoDailyCap,
      _welcomeChats,
      _journalHistoryDays,
      _moodWindowDays,
      _communityThreadsMonthly,
      _communityRepliesMonthly,
    ]);

    // Listen to authentication changes
    _authService.addListener(_onAuthChange);

    // Also check immediately in case auth service is already initialized
    _onAuthChange();
  }

  void _onAuthChange() {
    final user = _authService.currentUser;
    if (user != null) {
      _initializeTracking(user.uid);
    } else {
      // Reset when logged out
      _isSubscriptionRequired.value = false;
      _daysSinceLogin.value = 0;
    }
  }

  Future<void> _initializeTracking(String uid) async {
    try {
      // 1. Fetch Global Toggle (Fail-open: defaults to false if it fails)
      final globalConfigDoc = await db.collection('app_settings').doc('global_config').get();
      if (globalConfigDoc.exists && globalConfigDoc.data() != null) {
        final data = globalConfigDoc.data()!;
        if (data.containsKey('is_subscription_required')) {
          _isSubscriptionRequired.value = data['is_subscription_required'] == true;
        } else {
          _isSubscriptionRequired.value = false;
        }
        // Live-tunable free-tier limits (fail-open to constant defaults).
        _dodoDailyCap.value =
            _asPositiveInt(data['dodo_daily_cap'], AppConstants.dodoDailyCapDefault);
        _welcomeChats.value =
            _asPositiveInt(data['welcome_chats'], AppConstants.welcomeChatsDefault);
        _journalHistoryDays.value = _asPositiveInt(
            data['journal_history_days'], AppConstants.journalHistoryDaysDefault);
        _moodWindowDays.value = _asPositiveInt(
            data['mood_window_days'], AppConstants.moodWindowDaysDefault);
        _communityThreadsMonthly.value = _asPositiveInt(
            data['community_threads_monthly'],
            AppConstants.communityThreadsMonthlyDefault);
        _communityRepliesMonthly.value = _asPositiveInt(
            data['community_replies_monthly'],
            AppConstants.communityRepliesMonthlyDefault);
      } else {
        _isSubscriptionRequired.value = false;
      }
    } catch (e) {
      AppLog.error('MonetizationService.globalConfig', e);
      _isSubscriptionRequired.value = false;
    }

    try {
      // 2. User Account Age Tracker (Fail-open: defaults to 0 if it fails)
      final userRef = db.collection('users').doc(uid);
      final userDoc = await userRef.get();
      
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        if (data.containsKey('first_login_at') && data['first_login_at'] != null) {
          final Timestamp firstLoginAt = data['first_login_at'] as Timestamp;
          final DateTime loginDate = firstLoginAt.toDate();
          final int days = DateTime.now().difference(loginDate).inDays;
          // Ensure it doesn't go below 0 due to time sync issues
          _daysSinceLogin.value = days < 0 ? 0 : days;
        } else {
          // Field doesn't exist, set it
          await userRef.update({
            'first_login_at': FieldValue.serverTimestamp(),
          });
          _daysSinceLogin.value = 0;
        }
      } else {
        _daysSinceLogin.value = 0;
      }
    } catch (e) {
      AppLog.error('MonetizationService.trackUserAge', e);
      _daysSinceLogin.value = 0;
    }

    _analytics.logSubscriptionGate(
      required: _isSubscriptionRequired.value,
      daysSinceLogin: _daysSinceLogin.value,
    );
  }

  /// Coerces a Firestore config value to a positive int, falling back to
  /// [fallback] when it is missing, non-numeric, or <= 0.
  int _asPositiveInt(dynamic value, int fallback) {
    final int? parsed = value is int
        ? value
        : (value is num ? value.toInt() : int.tryParse('$value'));
    return (parsed != null && parsed > 0) ? parsed : fallback;
  }

  // --- Current cap status (so gates can show a persistent "limit reached"
  // button that survives app restarts until Premium or the period resets). The
  // usage counters are written server-side by the Cloud Functions and are
  // readable by the owner; here we mirror the same PKT period logic to decide
  // whether the user is currently over the limit. Fail-open to "not capped". ---

  String _p2(int n) => n < 10 ? '0$n' : '$n';

  /// Asia/Karachi (UTC+5, no DST) day key `YYYY-MM-DD` for now — matches the
  /// server's `pktDateKey` used by the Dodo daily counter.
  String get _pktDateKey {
    final k = DateTime.now().toUtc().add(const Duration(hours: 5));
    return '${k.year}-${_p2(k.month)}-${_p2(k.day)}';
  }

  /// Asia/Karachi month key `YYYY-MM` for now — matches the server's
  /// `pktMonthKey` used by the community-thread monthly counter.
  String get _pktMonthKey {
    final k = DateTime.now().toUtc().add(const Duration(hours: 5));
    return '${k.year}-${_p2(k.month)}';
  }

  /// True when a FREE user has already hit today's Dodo message cap (PKT).
  Future<bool> isDodoDailyCapReached() =>
      _isCapReached('dodo', 'date', _pktDateKey, dodoDailyCap);

  /// True when a FREE user has already hit this month's community-thread cap.
  Future<bool> isCommunityThreadCapReached() => _isCapReached(
      'community_threads', 'month', _pktMonthKey, communityThreadsMonthly);

  /// True when a FREE user has already hit this month's community-reply cap.
  Future<bool> isCommunityReplyCapReached() => _isCapReached(
      'community_replies', 'month', _pktMonthKey, communityRepliesMonthly);

  Future<bool> _isCapReached(
      String feature, String periodField, String periodKey, int limit) async {
    if (isPremium) return false;
    final uid = _authService.currentUser?.uid;
    if (uid == null) return false;
    try {
      final doc = await db
          .collection('users')
          .doc(uid)
          .collection('usage')
          .doc(feature)
          .get();
      if (!doc.exists || doc.data() == null) return false;
      final data = doc.data()!;
      final count = data[periodField] == periodKey ? (data['count'] ?? 0) : 0;
      return (count is int ? count : 0) >= limit;
    } catch (e) {
      AppLog.error('MonetizationService.isCapReached.$feature', e);
      return false; // fail-open: don't block the composer on a read error
    }
  }
}
