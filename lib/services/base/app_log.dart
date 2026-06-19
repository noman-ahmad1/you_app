import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Single logging entry point for the app.
///
/// All diagnostic output should go through here instead of `print` /
/// scattered `debugPrint` calls. Console output is suppressed in release
/// builds, while handled (non-fatal) errors are forwarded to Crashlytics so
/// real-world failures are visible. Crashlytics respects the user's analytics
/// consent (see AnalyticsService.setCollectionEnabled), so opting out silences
/// these too.
class AppLog {
  const AppLog._();

  /// General informational message.
  static void info(String context, [Object? detail]) {
    if (kReleaseMode) return;
    debugPrint('ℹ️ [$context]${detail != null ? ' $detail' : ''}');
  }

  /// A non-fatal error caught and handled by the caller.
  static void error(String context, Object error, [StackTrace? stack]) {
    if (!kReleaseMode) {
      debugPrint('💥 [$context] $error');
      if (stack != null) debugPrint(stack.toString());
    }
    _recordNonFatal(context, error, stack);
  }

  /// A Firebase-specific failure (surfaces the error code when present).
  static void firebase(String context, Object error) {
    if (!kReleaseMode) {
      debugPrint('🔥 [$context] $error');
    }
    _recordNonFatal(context, error, null);
  }

  /// Forwards a handled error to Crashlytics as a non-fatal. Guarded so it is a
  /// no-op when Firebase isn't initialised (e.g. in unit tests).
  static void _recordNonFatal(String context, Object error, StackTrace? stack) {
    try {
      FirebaseCrashlytics.instance
          .recordError(error, stack, reason: context, fatal: false);
    } catch (_) {
      // Crashlytics unavailable — ignore so logging never throws.
    }
  }
}
