import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:stacked/stacked.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/base/app_log.dart';
import 'package:you_app/services/billing_service.dart';
import 'package:you_app/services/monetization_service.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/views/verify_email/email_verification_gate.dart';

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

  // A one-shot celebration overlay shown right after a successful subscribe.
  bool _showCelebration = false;
  bool get showCelebration => _showCelebration;
  bool _disposed = false;

  void celebrate() {
    _showCelebration = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (_disposed) return;
      _showCelebration = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // --- Store packages (loaded from RevenueCat offerings) ---
  Package? _monthlyPkg;
  Package? _yearlyPkg;

  // --- Purchase flow state ---
  bool _purchasing = false; // store purchase sheet in flight
  bool _activating = false; // verifying entitlement with the backend
  bool _managing = false; // fetching / opening the store's manage-sub page
  bool get isWorking => _purchasing || _activating || _managing;
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
  BillingPeriod _selected =
      BillingPeriod.yearly; // yearly = best value, default
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
      _monthlyPkg?.storeProduct.priceString ?? '$currency 320';
  String get yearlyPrice =>
      _yearlyPkg?.storeProduct.priceString ?? '$currency 3,200';
  // PKR 3,200 / 12 ≈ 266.67, rounded up so we never understate the price.
  String get yearlyPerMonth => '$currency 267 / mo';
  // 12 × 320 = 3,840 vs 3,200 → 16.7% saved.
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
          'Unbounded and Priority listeners',
          'Skip the queue and connect with a trained listener first.',
          AppColors.secondary.withAlpha(36),
        ),
        PremiumHighlight(
          AppConstants.community2,
          'Unlimited community',
          'Post and reply without monthly limits — and mention people directly.',
          AppColors.lightPurple.withAlpha(56),
        ),
        PremiumHighlight(
          AppConstants.journalImg,
          'Unlock voice journaling + Deeper mood insights',
          'Your full history, forever — write it or speak it. Patterns, triggers and gentle weekly reflections',
          AppColors.green.withAlpha(36),
        ),
        // PremiumHighlight(
        //   AppConstants.emoji_2,
        //   'Deeper mood insights',
        //   'Patterns, triggers and gentle weekly reflections.',
        //   AppColors.teal.withAlpha(56),
        // ),
      ];

  /// The full Free-vs-Premium breakdown, shown in the Compare sheet.
  List<PlanRow> get comparison => const [
        PlanRow('Dodo AI companion', free: 'Daily limit', premium: 'Unlimited'),
        PlanRow('Listener chats',
            free: '2–3 welcome', premium: 'Priority & unlimited'),
        PlanRow('Journaling history',
            free: 'Recent only', premium: 'Unlimited'),
        PlanRow('Voice journaling', free: '', premium: 'Included'),
        PlanRow('Mood insights', free: 'Basic', premium: 'Advanced reports'),
        PlanRow('Community threads',
            free: 'Limited / mo', premium: 'Unlimited'),
        PlanRow('Community replies',
            free: 'Limited / mo', premium: 'Unlimited'),
        PlanRow('Mention people in replies', free: '', premium: 'Included'),
        PlanRow('Ads', free: 'None', premium: 'None'),
        PlanRow('Crisis support', free: 'Always free', premium: 'Always free'),
      ];

  /// THE subscription entry point — launches the real Google Play purchase via
  /// RevenueCat. On success it asks the backend to verify + write entitlement;
  /// the app unlocks only from that Firestore state (never from the client).
  Future<void> subscribe() async {
    if (isWorking) return;
    // Hard gate: an email/password user must verify before we take money — a
    // paying account needs a recoverable, verified identity. Google/verified
    // users pass straight through; on success the purchase continues below.
    if (!await EmailVerificationGate.ensure(context: 'premium_purchase')) {
      return;
    }
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

    // Celebrate the moment — the member block appears reactively once the
    // backend entitlement lands.
    celebrate();
    _activating = true;
    notifyListeners();
    await _syncEntitlement();
    _activating = false;
    notifyListeners();
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
    if (isPremium) celebrate();
  }

  /// Google Play's generic subscriptions page, used when the store doesn't hand
  /// us a specific management URL.
  static const String _playSubscriptionsUrl =
      'https://play.google.com/store/account/subscriptions';

  /// A friendly "you keep YOU+ until …" phrase for the confirmation copy.
  String get _keepUntilPhrase {
    final expiry = _authService.currentUser?.subscriptionExpiry;
    if (expiry == null) return 'until the end of your current billing period';
    return 'until ${DateFormat('d MMMM yyyy').format(expiry)}';
  }

  /// "Cancel subscription" — shown on the member block.
  ///
  /// IMPORTANT: an app can never cancel a Google Play subscription itself
  /// (Play policy), and this client never writes entitlement. So we confirm,
  /// then send the user to the store's manage-subscription page. Cancelling
  /// there only turns OFF auto-renew: RevenueCat sends CANCELLATION (which our
  /// webhook treats as a no-op) and the user stays premium until the period
  /// ends, when EXPIRATION fires and the backend revokes.
  Future<void> unsubscribe() async {
    if (isWorking) return;

    // A grant from our team (admin/promo) has no store subscription to cancel.
    final source = _authService.currentUser?.subscriptionSource;
    if (source != null && source != 'google_play') {
      await _dialogService.showDialog(
        title: 'YOU+ is a gift from us',
        description:
            'Your YOU+ access was granted by our team, so there’s no Google Play '
            'subscription to cancel. If you’d like it removed, just reach out '
            'and we’ll take care of it.',
        buttonTitle: 'OK',
      );
      return;
    }

    // 1. Warm confirmation — nothing is lost today.
    final response = await _dialogService.showConfirmationDialog(
      title: 'Cancel YOU+?',
      description:
          'You’ll keep YOU+ $_keepUntilPhrase — nothing changes today, and your '
          'journal, mood history, and messages always stay yours.\n\n'
          'Google Play handles cancellations, so we’ll open your subscription '
          'settings there.',
      confirmationTitle: 'Continue to Play Store',
      cancelTitle: 'Stay subscribed',
    );
    if (response?.confirmed != true) return;

    _analytics.logManageSubscriptionOpened();

    // 2. Open the store's manage-subscriptions page.
    _managing = true;
    notifyListeners();
    final url = await _billing.managementUrl() ?? _playSubscriptionsUrl;
    _managing = false;
    notifyListeners();

    var opened = false;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        AppLog.error('PremiumViewModel.unsubscribe.launch', e);
      }
    }

    if (!opened) {
      await _dialogService.showDialog(
        title: 'Couldn’t open the Play Store',
        description:
            'Please open the Play Store app → Menu → Subscriptions → YOU+ to '
            'cancel. Your access stays active until then.',
        buttonTitle: 'OK',
      );
      return;
    }

    // 3. Reassure: cancelling only stops the next renewal.
    await _dialogService.showDialog(
      title: 'You’re still YOU+ 💛',
      description:
          'If you cancelled, YOU+ stays active $_keepUntilPhrase. We’ll update '
          'your account automatically when it ends — and you’re welcome back '
          'any time.',
      buttonTitle: 'Got it',
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
      await FirebaseFunctions.instance
          .httpsCallable('refreshEntitlement')
          .call();
    } catch (e) {
      // Non-fatal: the webhook path will still unlock shortly.
      AppLog.error('PremiumViewModel.refreshEntitlement', e);
    }
  }

  /// The footer links under the plans. [which] is the label the view renders —
  /// keep these strings in sync with `_LegalRow` in premium_view.dart, or the
  /// tap silently falls through to the "unknown link" dialog.
  Future<void> onLegalTap(String which) async {
    switch (which) {
      case 'Restore purchase':
        await _restore();
        return;
      case 'Terms':
        await _openLegalUrl(AppConstants.termsUrl, which);
        return;
      case 'Privacy':
        await _openLegalUrl(AppConstants.privacyUrl, which);
        return;
    }
    await _dialogService.showDialog(
      title: which,
      description: 'This link isn’t available right now.',
      buttonTitle: 'OK',
    );
  }

  /// Opens a policy page in the browser. Play requires these to be reachable
  /// from the purchase screen, so a failure is surfaced rather than swallowed.
  Future<void> _openLegalUrl(String url, String label) async {
    var opened = false;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        AppLog.error('PremiumViewModel.onLegalTap($label)', e);
      }
    }
    if (opened) return;

    await _dialogService.showDialog(
      title: 'Couldn’t open $label',
      description: 'Please visit $url in your browser.',
      buttonTitle: 'OK',
    );
  }

  void close() => _navigationService.back();
}
