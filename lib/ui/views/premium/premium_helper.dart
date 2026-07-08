import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:stacked_services/stacked_services.dart';

/// Centralized entry point for opening the full YOU+ screen. Call from
/// any trigger (drawer, profile, paywall CTA…). [source] is attached to
/// analytics so we can see which entry points drive interest.
class PremiumHelper {
  static Future<void> open({String source = 'unknown'}) async {
    locator<AnalyticsService>()
        .logPaywallShown(feature: 'premium_screen:$source');
    await locator<NavigationService>().navigateToPremiumView();
  }
}
