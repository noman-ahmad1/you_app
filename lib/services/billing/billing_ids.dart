/// Single source of truth for RevenueCat / Google Play billing identifiers.
///
/// Keep every store/RevenueCat id here so adding a plan or store later is a
/// one-file change. These must match the RevenueCat dashboard + Play Console.
class BillingIds {
  /// RevenueCat entitlement that unlocks YOU+ (granted by every plan).
  static const String entitlement = 'you_plus';

  /// The RevenueCat "current" offering that holds the packages below.
  static const String defaultOffering = 'default';

  // --- Google Play subscription product ids (base plans) ---
  static const String monthlyProductId = 'you_plus_monthly';
  static const String yearlyProductId = 'you_plus_yearly';
  // Future plans (e.g. lifetime) drop in here + a package below.
}
