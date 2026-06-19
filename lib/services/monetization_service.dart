import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/base/app_log.dart';
import 'package:you_app/services/base/firestore_base.dart';

class MonetizationService with ListenableServiceMixin, FirestoreServiceMixin {
  final AuthenticationService _authService = locator<AuthenticationService>();
  AnalyticsService get _analytics => locator<AnalyticsService>();

  final ReactiveValue<bool> _isSubscriptionRequired = ReactiveValue<bool>(false);
  final ReactiveValue<int> _daysSinceLogin = ReactiveValue<int>(0);

  bool get isSubscriptionRequired => _isSubscriptionRequired.value;
  int get daysSinceLogin => _daysSinceLogin.value;

  MonetizationService() {
    listenToReactiveValues([_isSubscriptionRequired, _daysSinceLogin]);
    
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
}
