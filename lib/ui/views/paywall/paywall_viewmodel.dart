import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';

/// A single premium selling point shown on the paywall. [imageAsset] is an
/// asset path (icon/illustration) rendered in the benefit card.
class PremiumBenefit {
  final String imageAsset;
  final String title;
  final String subtitle;
  const PremiumBenefit(this.imageAsset, this.title, this.subtitle);
}

class PaywallViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _analytics = locator<AnalyticsService>();

  /// The gate that triggered this paywall (see PaywallFeature.*). Drives the
  /// headline and is attached to analytics so we can see which gates convert.
  final String feature;

  PaywallViewModel({required this.feature});

  /// Context-specific headline for the gate that brought the user here.
  String get headline {
    switch (feature) {
      case 'dodo':
        return "You've reached today's free Dodo messages";
      case 'welcome_chat':
        return "You've used all your free welcome chats";
      case 'journal_history':
        return 'See your full journaling history';
      case 'mood_window':
        return 'Unlock your deeper mood insights';
      case 'community_threads':
        return "You've used your free threads this month";
      case 'community_replies':
        return "You've used your free replies this month";
      case 'mention':
        return 'Mentioning people is a Premium feature';
      default:
        return 'Unlock YOU Premium';
    }
  }

  String get subheadline =>
      'Upgrade to Premium for unlimited support — whenever you need it.';

  /// The Premium value proposition (Phase-1 subset of the product plan).
  List<PremiumBenefit> get benefits => const [
        PremiumBenefit(AppConstants.dodoCut, 'Unlimited Dodo',
            'Chat with your AI companion with no daily cap'),
        PremiumBenefit(AppConstants.brain, 'Priority listener chats',
            'Skip the queue with unlimited volunteer sessions'),
        PremiumBenefit(AppConstants.journalImg, 'Full journaling history',
            'Unlimited entries, forever — nothing hidden'),
        PremiumBenefit(AppConstants.emoji_2, 'Advanced mood insights',
            'Deep patterns, triggers and personal reports'),
      ];

  Color get accent => AppColors.secondary;

  /// MVP upgrade action. Real billing is a later phase, so for now we log intent
  /// and let the user know Premium is on the way.
  Future<void> onUpgrade() async {
    _analytics.logUpgradeCtaTapped(feature: feature);
    await _dialogService.showDialog(
      title: 'Premium is coming soon',
      description:
          'Thanks for your interest in YOU Premium! We\'re putting the '
          'finishing touches on it. Reach out to our team and we\'ll help you '
          'get early access.',
      buttonTitle: 'Got it',
    );
  }

  void close() => _navigationService.back();
}
