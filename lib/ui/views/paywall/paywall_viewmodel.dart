import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';

/// The single premium perk this paywall elaborates — tied to the gate the user
/// hit. [tint] colours the icon box.
class FeatureUpsell {
  final String imageAsset;
  final String title;
  final String description;
  final Color tint;
  const FeatureUpsell(this.imageAsset, this.title, this.description, this.tint);
}

class PaywallViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _analytics = locator<AnalyticsService>();

  /// The gate that triggered this paywall (see PaywallFeature.*).
  final String feature;

  PaywallViewModel({required this.feature});

  Color get accent => AppColors.secondary;

  /// Why the user landed here — the gate they hit.
  String get headline {
    switch (feature) {
      case 'dodo':
        return 'You and Dodo have covered a lot today.';
      case 'welcome_chat':
        return "We're glad you reached out.";
      case 'journal_history':
        return "Look how much you've written.";
      case 'voice_journal':
        return 'Journaling out loud is a YOU+ thing.';
      case 'mood_window':
        return "There's a bigger picture here.";
      case 'community_threads':
        return "You've got things worth sharing.";
      case 'community_replies':
        return "You've been showing up for people today.";
      case 'mention':
        return 'Mentioning people is a Premium feature';
      case 'soothing_sounds':
        return 'This one is part of YOU+.';
      default:
        return 'Unlock YOU+';
    }
  }

  /// The specific perk the user unlocks for the feature they were gated on —
  /// this is the ONE card + elaboration the paywall focuses on.
  FeatureUpsell get upsell {
    switch (feature) {
      case 'dodo':
        return FeatureUpsell(
          AppConstants.dodoCut,
          'Unlimited Dodo',
          "Dodo's here for your daily check-ins for free. With YOU+, there's no "
              "limit — talk it through anytime, day or night, for as long as "
              "you need.",
          AppColors.pink,
        );
      case 'welcome_chat':
        return FeatureUpsell(
          AppConstants.brain,
          'Unlimited listener chats',
          "Your welcome chats helped you connect with a real person. YOU+ keeps "
              "that door open — reach a trained listener whenever you need one, "
              "with less waiting.",
          AppColors.secondary,
        );
      // Voice journaling shares the "advanced journaling" card (its copy already
      // covers capturing thoughts by voice); only the headline above differs.
      case 'journal_history':
      case 'voice_journal':
        return FeatureUpsell(
          AppConstants.journalImg,
          'Access to advanced journaling',
          "Not every feeling belongs on a keyboard. Capture your thoughts by voice and keep them in your journal. Recent entries are always free, and YOU+ unlocks your full journal history so you can revisit every step of your journey.",
          AppColors.green,
        );
      case 'mood_window':
        return FeatureUpsell(
          AppConstants.emoji_2,
          'Advanced mood insights',
          "Your last week is always free to explore. YOU+ reveals your "
              "longer-term patterns and gentle monthly reflections — a deeper "
              "look at what shapes how you feel.",
          AppColors.teal,
        );
      // Threads, replies and mentions are all the same community feature, so
      // they share one card (the headline above still differs per gate).
      case 'community_threads':
      case 'community_replies':
      case 'mention':
        return FeatureUpsell(
          AppConstants.community2,
          'Do more in the community',
          "Reading and following along is always free. With YOU+, the monthly "
              "limits are gone — post as many threads and replies as you like, "
              "and mention people directly to bring them into the conversation.",
          AppColors.secondary,
        );
      case 'soothing_sounds':
        return FeatureUpsell(
          AppConstants.soothing,
          'The full sound library',
          "A handful of sounds are always free to listen to. YOU+ opens the "
              "rest of the library — longer soundscapes to fall asleep to, focus "
              "with, or simply breathe alongside.",
          AppColors.teal,
        );
      default:
        return FeatureUpsell(
          AppConstants.premiumBadgeFill,
          'YOU+',
          'Unlock everything You offers — unlimited, and a little more personal.',
          AppColors.secondary,
        );
    }
  }

  /// Gentle reminder that You+ is far more than this one feature.
  String get moreNote =>
      'Plus everything else in You+ — unlimited journaling, priority listeners, '
      'deeper mood insights and more.';

  /// Sends the user from the contextual gate to the full YOU+ screen, which
  /// holds the plans and (later) the subscription flow.
  Future<void> onUpgrade() async {
    _analytics.logUpgradeCtaTapped(feature: feature);
    await _navigationService.navigateToPremiumView();
  }

  void close() => _navigationService.back();
}
