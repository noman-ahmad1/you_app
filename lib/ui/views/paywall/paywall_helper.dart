import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:stacked_services/stacked_services.dart';

/// Canonical keys for the gate that triggered a paywall. Shared by every gate
/// and by [PaywallViewModel] so analytics/headlines stay in sync (no typos).
class PaywallFeature {
  static const String dodo = 'dodo';
  static const String welcomeChat = 'welcome_chat';
  static const String journalHistory = 'journal_history';
  static const String moodWindow = 'mood_window';
  static const String communityThreads = 'community_threads';
  static const String communityReplies = 'community_replies';
  static const String mention = 'mention';
}

/// Centralized entry point for showing the paywall. Call from any gate (view,
/// viewmodel or service) — no BuildContext required. Logs the impression,
/// attributed to [feature], and routes to the PaywallView.
class PaywallHelper {
  static Future<void> show({required String feature}) async {
    locator<AnalyticsService>().logPaywallShown(feature: feature);
    await locator<NavigationService>().navigateToPaywallView(feature: feature);
  }
}
