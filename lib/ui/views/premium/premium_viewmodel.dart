import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/base/app_log.dart';
import 'package:you_app/services/billing_service.dart';
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

class PremiumViewModel extends ReactiveViewModel {
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _analytics = locator<AnalyticsService>();
  final _monetizationService = locator<MonetizationService>();
  final _billing = locator<BillingService>();
  final _authService = locator<AuthenticationService>();

  // React to the live user doc so premium unlock (written by the backend after
  // purchase) flips this screen to the member block automatically.
  @override
  List<ListenableServiceMixin> get listenableServices => [_authService];

  bool get isPremium => _monetizationService.isPremium;
  Color get accent => AppColors.secondary;

  // --- Store packages (loaded from RevenueCat offerings) ---
  Package? _monthlyPkg;
  Package? _yearlyPkg;

  // --- Purchase flow state ---
  bool _purchasing = false; // store purchase sheet in flight
  bool _activating = false; // verifying entitlement with the backend
  bool get isWorking => _purchasing || _activating;
  String? _purchaseError;
  String? get purchaseError => _purchaseError;

  /// Load the store offerings so the plan cards show real, localized prices.
  Future<void> init() async {
    final plans = await _billing.loadPlans();
    _monthlyPkg = plans.monthly;
    _yearlyPkg = plans.yearly;
    notifyListeners();
  }

  // --- Billing plan selection ---
  BillingPeriod _selected = BillingPeriod.yearly; // yearly = best value, default
  BillingPeriod get selected => _selected;
  bool isSelected(BillingPeriod p) => _selected == p;
  void selectPlan(BillingPeriod p) {
    if (_selected == p) return;
    _selected = p;
    notifyListeners();
  }

  // --- Pricing: real localized store prices, with placeholders as fallback
  // if offerings haven't loaded (offline / not yet configured). ---
  String get currency => AppConstants.defaultCurrencyCode; // 'PKR'
  String get monthlyPrice =>
      _monthlyPkg?.storeProduct.priceString ?? '$currency 300';
  String get yearlyPrice =>
      _yearlyPkg?.storeProduct.priceString ?? '$currency 3,000';
  String get yearlyPerMonth => '$currency 250 / mo';
  String get yearlySaveLabel => 'Save 17%';

  String get ctaLabel => _activating ? 'Activating…' : 'Subscribe to You+';
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

  /// THE subscription entry point — launches the real Google Play purchase via
  /// RevenueCat. On success it asks the backend to verify + write entitlement;
  /// the app unlocks only from that Firestore state (never from the client).
  Future<void> subscribe() async {
    if (isWorking) return;
    final plan = _selected;
    final package = plan == BillingPeriod.yearly ? _yearlyPkg : _monthlyPkg;
    if (package == null) {
      await _dialogService.showDialog(
        title: 'Just a moment',
        description:
            "This plan isn't available right now. Please check your connection "
            'and try again shortly.',
        buttonTitle: 'OK',
      );
      return;
    }

    _purchaseError = null;
    _purchasing = true;
    notifyListeners();
    _analytics.logPurchaseStarted(plan: plan.name);

    final result = await _billing.purchase(package);
    _purchasing = false;

    switch (result.outcome) {
      case PurchaseOutcome.cancelled:
        _analytics.logPurchaseFailed(reason: 'cancelled');
        notifyListeners(); // silent — user backed out, no scolding
        return;
      case PurchaseOutcome.error:
        _analytics.logPurchaseFailed(reason: 'store_error');
        _purchaseError =
            result.message ?? 'Something went wrong. Please try again.';
        notifyListeners();
        return;
      case PurchaseOutcome.success:
        _analytics.logPurchaseCompleted(plan: plan.name);
        break;
    }

    await _activateAndReassure(
      title: "You're all set 💛",
      pending:
          "Thank you for supporting You. We're activating your YOU+ now — it'll "
          'appear in just a moment.',
    );
  }

  /// Real "Restore purchase" flow (reinstall / new device).
  Future<void> _restore() async {
    if (isWorking) return;
    _analytics.logRestoreTapped();
    _purchaseError = null;
    _purchasing = true;
    notifyListeners();

    final result = await _billing.restore();
    _purchasing = false;

    if (result.outcome == PurchaseOutcome.error) {
      _purchaseError = result.message;
      notifyListeners();
      return;
    }

    await _activateAndReassure(
      title: 'Welcome back 💛',
      pending: "We're checking your subscription — it'll refresh in a moment.",
      noneFound:
          "We didn't find an active subscription on this account. If you think "
          'this is a mistake, reach out and we’ll help.',
    );
  }

  /// Ask the backend to verify entitlement with RevenueCat and write it to
  /// Firestore (instant, server-verified). The users-doc listener then flips
  /// `isPremium`, re-rendering this screen. If it hasn't landed yet, reassure.
  Future<void> _activateAndReassure({
    required String title,
    required String pending,
    String? noneFound,
  }) async {
    _activating = true;
    notifyListeners();
    await _syncEntitlement();
    _activating = false;
    notifyListeners();

    if (isPremium) return; // view already swapped to the member block
    await _dialogService.showDialog(
      title: noneFound != null ? 'Nothing to restore' : title,
      description: noneFound ?? pending,
      buttonTitle: 'OK',
    );
  }

  Future<void> _syncEntitlement() async {
    try {
      await FirebaseFunctions.instance.httpsCallable('refreshEntitlement').call();
    } catch (e) {
      // Non-fatal: the webhook path will still unlock shortly.
      AppLog.error('PremiumViewModel.refreshEntitlement', e);
    }
  }

  Future<void> onLegalTap(String which) async {
    if (which == 'Restore purchase') {
      await _restore();
      return;
    }
    await _dialogService.showDialog(
      title: which,
      description: 'This will be available once subscriptions go live.',
      buttonTitle: 'OK',
    );
  }

  void close() => _navigationService.back();
}
