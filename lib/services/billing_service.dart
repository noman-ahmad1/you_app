import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:you_app/env.dart';
import 'package:you_app/services/base/app_log.dart';

/// Outcome of a purchase/restore attempt, so the UI can react without knowing
/// about the RevenueCat SDK.
enum PurchaseOutcome { success, cancelled, error }

class BillingResult {
  final PurchaseOutcome outcome;
  final String? message; // calm, user-facing message for [error]
  const BillingResult(this.outcome, {this.message});
}

/// Thin wrapper around RevenueCat (`purchases_flutter`).
///
/// SECURITY: this service NEVER grants entitlement. A completed purchase only
/// tells the backend (via webhook / `refreshEntitlement`) to write premium to
/// Firestore; the app unlocks solely from that Firestore state. Do not read
/// CustomerInfo here to flip `isPremium`.
class BillingService {
  bool _configured = false;
  bool get isConfigured => _configured;

  /// Configure the SDK once at startup. Fail-soft: with no key the app still
  /// runs (billing UI will just show unavailable).
  Future<void> configure() async {
    final key = Secrets.revenueCatAndroidKey;
    if (key.isEmpty) {
      AppLog.error(
          'BillingService.configure', 'REVENUECAT_ANDROID_KEY missing');
      return;
    }
    try {
      await Purchases.configure(PurchasesConfiguration(key));
      _configured = true;
    } catch (e) {
      AppLog.error('BillingService.configure', e);
    }
  }

  /// Alias RevenueCat's app_user_id to our Firebase UID so webhook events and
  /// the REST lookup carry the UID we key entitlement on.
  Future<void> logIn(String uid) async {
    if (!_configured) return;
    try {
      await Purchases.logIn(uid);
    } catch (e) {
      AppLog.error('BillingService.logIn', e);
    }
  }

  Future<void> logOut() async {
    if (!_configured) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      // logOut throws if already anonymous — harmless.
      AppLog.error('BillingService.logOut', e);
    }
  }

  /// The current offering's monthly / yearly packages (either may be null).
  Future<({Package? monthly, Package? yearly})> loadPlans() async {
    if (!_configured) return (monthly: null, yearly: null);
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      return (monthly: current?.monthly, yearly: current?.annual);
    } catch (e) {
      AppLog.error('BillingService.loadPlans', e);
      return (monthly: null, yearly: null);
    }
  }

  /// Launch the store purchase flow for [package]. Distinguishes a user cancel
  /// (not an error) from a real failure.
  Future<BillingResult> purchase(Package package) async {
    if (!_configured) {
      return const BillingResult(PurchaseOutcome.error,
          message: 'Purchases aren’t available right now.');
    }
    try {
      await Purchases.purchase(PurchaseParams.package(package));
      return const BillingResult(PurchaseOutcome.success);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const BillingResult(PurchaseOutcome.cancelled);
      }
      AppLog.error('BillingService.purchase', e);
      return BillingResult(PurchaseOutcome.error, message: _friendly(code));
    } catch (e) {
      AppLog.error('BillingService.purchase', e);
      return const BillingResult(PurchaseOutcome.error,
          message: 'Something went wrong. Please try again.');
    }
  }

  /// Restore an existing subscription (e.g. after reinstall).
  Future<BillingResult> restore() async {
    if (!_configured) {
      return const BillingResult(PurchaseOutcome.error,
          message: 'Purchases aren’t available right now.');
    }
    try {
      await Purchases.restorePurchases();
      return const BillingResult(PurchaseOutcome.success);
    } catch (e) {
      AppLog.error('BillingService.restore', e);
      return const BillingResult(PurchaseOutcome.error,
          message: 'We couldn’t restore right now. Please try again.');
    }
  }

  String _friendly(PurchasesErrorCode code) {
    switch (code) {
      case PurchasesErrorCode.networkError:
        return 'A network hiccup interrupted the purchase. Please try again.';
      case PurchasesErrorCode.paymentPendingError:
        return 'Your payment is pending — YOU+ will unlock once it clears.';
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return 'You already have this plan. Try “Restore purchase”.';
      case PurchasesErrorCode.storeProblemError:
        return 'Google Play had a problem. Please try again in a moment.';
      default:
        return 'Something went wrong with the purchase. Please try again.';
    }
  }
}
