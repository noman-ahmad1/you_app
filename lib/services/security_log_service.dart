import 'package:cloud_functions/cloud_functions.dart';
import 'package:you_app/services/base/app_log.dart';

/// Coarse, disclosed safety actions. Kept in sync with the backend
/// `CLIENT_SECURITY_ACTIONS` allow-list in `functions/index.js`.
class SecurityAction {
  static const String signup = 'signup';
  static const String signin = 'signin';
  static const String messageSent = 'message_sent';
  static const String reportFiled = 'report_filed';
}

/// Fires a minimal safety-log event to the backend, which captures the client
/// IP SERVER-SIDE and appends to the isolated, admin-only `security_logs`
/// collection.
///
/// SAFETY METADATA, NOT ANALYTICS: this must never touch [AnalyticsService], and
/// it is always fire-and-forget — a failure here can never block or break a user
/// flow. The client sends ONLY the coarse action label; the uid, IP, role and
/// timestamp are all server-authoritative (the client never sends an IP).
class SecurityLogService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Fire-and-forget: records [action] for the current user. Safe to call
  /// without awaiting; errors are swallowed.
  void log(String action) {
    _send(action);
  }

  Future<void> _send(String action) async {
    try {
      await _functions
          .httpsCallable('logSecurityEvent')
          .call(<String, dynamic>{'action': action});
    } catch (e) {
      // Soft-fail only — safety logging must never surface to the user.
      AppLog.error('SecurityLogService.log', e);
    }
  }
}
