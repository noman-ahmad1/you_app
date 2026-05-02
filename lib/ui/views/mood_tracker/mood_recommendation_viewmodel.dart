import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/models/mood_model.dart';
import 'package:you_app/ui/views/home/home_view.dart';
import 'package:you_app/ui/views/volunteer_signup/volunteer_signup_view.dart';

class RecommendationItem {
  final String title;
  final String subtitle;
  final String iconAsset;
  final Function() onTap;

  RecommendationItem({
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.onTap,
  });
}

class MoodRecommendationViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final String emojiAssetPath;
  List<RecommendationItem> recommendations = [];

  MoodRecommendationViewModel({required this.emojiAssetPath});

  void initialize() {
    final moodLabel = assetToLabelMap[emojiAssetPath] ?? 'Neutral';

    // Negative/Low Energy
    if (['Sad', 'Restless', 'Anxious', 'Angry'].contains(moodLabel)) {
      recommendations = [
        RecommendationItem(
          title: 'Journal Your Thoughts',
          subtitle: 'Write down what\'s on your mind',
          iconAsset: AppConstants.journalIcon,
          onTap: () => _navigationService.navigateTo(Routes.journalDetailsView),
        ),
        RecommendationItem(
          title: 'Talk to Someone',
          subtitle: 'Connect with a volunteer',
          iconAsset: AppConstants.chat,
          onTap: () => _navigationService.replaceWithTransition(
              const HomeView(initialIndex: 2),
              transition: 'fade'),
        )
      ];
    }
    // High Energy / Positive
    else if (['Energized', 'Joyful', 'Blessed', 'Happy'].contains(moodLabel)) {
      recommendations = [
        RecommendationItem(
          title: 'Share Your Vibe',
          subtitle: 'Spread the positivity',
          iconAsset: AppConstants.community,
          onTap: () => _navigationService.replaceWithTransition(
              const HomeView(initialIndex: 0),
              transition: 'fade'),
        ),
        RecommendationItem(
          title: 'Volunteer',
          subtitle: 'Help others in the community',
          iconAsset: AppConstants.person,
          onTap: () => _navigationService.replaceWithTransition(
              const HomeView(initialIndex: 2),
              transition: 'fade'),
        )
      ];
    }
    // Neutral
    else {
      recommendations = [
        RecommendationItem(
          title: 'Community Check-in',
          subtitle: 'See what others are up to',
          iconAsset: AppConstants.community,
          onTap: () => _navigationService.replaceWithTransition(
              const HomeView(initialIndex: 0),
              transition: 'fade'),
        ),
      ];
    }
    notifyListeners();
  }

  void back() {
    _navigationService.back();
  }

  void skip() {
    _navigationService.clearStackAndShow(Routes.homeView);
  }
}
