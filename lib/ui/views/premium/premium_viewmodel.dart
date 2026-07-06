import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/monetization_service.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';

enum BillingPeriod { monthly, yearly }

/// A headline perk shown as a glass feature tile. [tint] colours the icon box.
class PremiumHighlight {
  final String imageAsset;
  final String title;
  final String subtitle;
  final Color tint;
  const PremiumHighlight(this.imageAsset, this.title, this.subtitle, this.tint);
}

/// A single Free-vs-Premium comparison row (shown in the Compare sheet). An
/// empty [free]/[premium] renders as a "not included" dash.
class PlanRow {
  final String feature;
  final String free;
  final String premium;
  const PlanRow(this.feature, {required this.free, required this.premium});
}

class PremiumViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _analytics = locator<AnalyticsService>();
  final _monetizationService = locator<MonetizationService>();

  bool get isPremium => _monetizationService.isPremium;
  Color get accent => AppColors.secondary;

  // --- Billing plan selection ---
  BillingPeriod _selected = BillingPeriod.yearly; // yearly = best value, default
  BillingPeriod get selected => _selected;
  bool isSelected(BillingPeriod p) => _selected == p;
  void selectPlan(BillingPeriod p) {
    if (_selected == p) return;
    _selected = p;
    notifyListeners();
  }

  // --- Pricing (easily tunable placeholders) ---
  // Monthly is our established PKR 300; yearly is a ~17%-off annual plan.
  // TODO(premium-pricing): confirm final numbers with the business.
  String get currency => AppConstants.defaultCurrencyCode; // 'PKR'
  String get monthlyPrice => '$currency 300';
  String get yearlyPrice => '$currency 3,000';
  String get yearlyPerMonth => '$currency 250 / mo';
  String get yearlySaveLabel => 'Save 17%';

  /// Primary CTA. Our free tier already lets people use the app, and billing
  /// isn't wired yet, so instead of a time-boxed "7-day free trial" we use a
  /// straightforward, honest subscribe CTA.
  String get ctaLabel => 'Subscribe to You+';
  String get ctaSubline => _selected == BillingPeriod.yearly
      ? 'Billed $yearlyPrice / year · Cancel anytime'
      : 'Billed $monthlyPrice / month · Cancel anytime';

  /// Feature tiles — copy from the new design, icons from our current screen.
  List<PremiumHighlight> get highlights => [
        PremiumHighlight(
          AppConstants.dodoCut,
          'Unlimited Dodo',
          'Talk to your AI companion as long as you need — no daily caps.',
          AppColors.pink.withAlpha(46),
        ),
        PremiumHighlight(
          AppConstants.brain,
          'Priority listeners',
          'Skip the queue and connect with a trained listener first.',
          AppColors.secondary.withAlpha(36),
        ),
        PremiumHighlight(
          AppConstants.journalImg,
          'Unlimited journaling + voice',
          'Your full history, forever — write it or speak it.',
          AppColors.green.withAlpha(36),
        ),
        PremiumHighlight(
          AppConstants.emoji_2,
          'Deeper mood insights',
          'Patterns, triggers and gentle weekly reflections.',
          AppColors.teal.withAlpha(56),
        ),
      ];

  /// The full Free-vs-Premium breakdown, shown in the Compare sheet.
  List<PlanRow> get comparison => const [
        PlanRow('Dodo AI companion', free: 'Daily limit', premium: 'Unlimited'),
        PlanRow('Listener chats',
            free: '2–3 welcome', premium: 'Priority & unlimited'),
        PlanRow('Journaling history', free: 'Recent only', premium: 'Unlimited'),
        PlanRow('Voice journaling', free: '', premium: 'Included'),
        PlanRow('Mood insights', free: 'Basic', premium: 'Advanced reports'),
        PlanRow('Community threads', free: 'Limited / mo', premium: 'Unlimited'),
        PlanRow('Community replies', free: 'Limited / mo', premium: 'Unlimited'),
        PlanRow('Mention people in replies', free: '', premium: 'Included'),
        PlanRow('Ads', free: 'None', premium: 'None'),
        PlanRow('Crisis support', free: 'Always free', premium: 'Always free'),
      ];

  /// THE subscription entry point. Real billing (RevenueCat / store IAP) plugs
  /// in here for the selected plan; on success the entitlement propagates via
  /// the users-doc listener. For now it logs intent and reassures the user.
  Future<void> subscribe() async {
    _analytics.logUpgradeCtaTapped(feature: 'premium_screen:${_selected.name}');
    // TODO(premium-billing): start the purchase flow for [_selected] here.
    await _dialogService.showDialog(
      title: 'Premium is coming soon',
      description:
          "Thanks for wanting You+! We're putting the finishing touches on "
          "payments. Reach out to our team and we'll help you get early access.",
      buttonTitle: 'Got it',
    );
  }

  /// Placeholder for the legal / restore links until billing is integrated.
  Future<void> onLegalTap(String which) async {
    await _dialogService.showDialog(
      title: which,
      description: 'This will be available once subscriptions go live.',
      buttonTitle: 'OK',
    );
  }

  void close() => _navigationService.back();
}
