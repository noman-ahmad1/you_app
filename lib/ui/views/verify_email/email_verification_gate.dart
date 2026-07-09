import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/auth_service.dart';

/// The single reusable email-verification gate for HARD gates (currently just
/// premium purchase). It is never used on any support flow — crisis, chat,
/// journal, mood, community, and Dodo never call this.
///
/// Returns `true` when the caller may proceed:
///   • the user is already verified, or signed in with Google (always verified,
///     so [AuthenticationService.needsEmailVerification] is false) → returns
///     immediately with no UI, OR
///   • the user completed verification in the [VerifyEmailView].
/// Returns `false` when an email/password user backs out still unverified — the
/// caller should abort quietly.
class EmailVerificationGate {
  const EmailVerificationGate._();

  static Future<bool> ensure({required String context}) async {
    final auth = locator<AuthenticationService>();
    if (!auth.needsEmailVerification) return true; // verified / Google

    final analytics = locator<AnalyticsService>();
    analytics.logVerificationGateHit(context: context);
    analytics.logVerificationPrompted(context: context);

    final result = await locator<NavigationService>()
        .navigateToVerifyEmailView(source: context);
    return result == true;
  }
}
