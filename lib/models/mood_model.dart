import 'dart:math';

class MoodEntry {
  final String moodId; // E.g., 'mood_9' (the asset name)
  final int moodScore; // E.g., 9 (the numerical value)
  final String timestamp; // ISO 8601 string of when it was recorded
  final String dateOnly; // YYYY-MM-DD string for easy grouping/aggregation

  MoodEntry({
    required this.moodId,
    required this.moodScore,
    required this.timestamp,
    required this.dateOnly,
  });

  Map<String, dynamic> toJson() {
    return {
      'moodId': moodId,
      'moodScore': moodScore,
      'timestamp': timestamp,
      'dateOnly': dateOnly,
    };
  }
}

class AppConstants {
  // Mock asset paths
  static const String back = 'assets/icons/back.png';
  static const String background = 'assets/images/background.png';
  static const String drop = 'assets/sounds/drop.mp3';

  // Emoji constant names (linked to mood scores)
  static const String emoji_1 = 'mood_9'; // Energized (Score 9)
  static const String emoji_2 = 'mood_8'; // Main character vibe (Score 8)
  static const String emoji_3 = 'mood_7'; // Over the moon (Score 7)
  static const String emoji_4 = 'mood_6'; // chill mode (Score 6)
  static const String emoji_5 = 'mood_5'; // Holding steady? (Score 5)
  static const String emoji_6 = 'mood_4'; // Restless? (Score 4)
  static const String emoji_7 = 'mood_3'; // Running on 1%' (Score 3)
  static const String emoji_8 = 'mood_2'; // Overstimulated? (Score 2)
  static const String emoji_9 = 'mood_1'; // About to crash out?? (Score 1)
}

// Data model for displaying mood statistics in the chart
class MoodStat {
  final String dayLabel; // E.g., 'Mon'
  final double averageMoodScore; // 1.0 (lowest) to 9.0 (highest)

  MoodStat(this.dayLabel, this.averageMoodScore);
}

// Particle class definition for the animated visual effect
class Particle {
  double x, y;
  double size;
  double speed;
  double angle;
  double life;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
    required this.life,
  });

  void update() {
    x += cos(angle) * speed;
    y += sin(angle) * speed;
    life--;
  }
}

// Map emoji constant names to a numeric score (9 is best, 1 is worst)
const Map<String, int> MoodScores = {
  AppConstants.emoji_1: 9,
  AppConstants.emoji_2: 8,
  AppConstants.emoji_3: 7,
  AppConstants.emoji_4: 6,
  AppConstants.emoji_5: 5,
  AppConstants.emoji_6: 4,
  AppConstants.emoji_7: 3,
  AppConstants.emoji_8: 2,
  AppConstants.emoji_9: 1,
};

// Map mood scores to their corresponding emoji asset
const Map<int, String> ScoreToEmojiAsset = {
  9: AppConstants.emoji_1,
  8: AppConstants.emoji_2,
  7: AppConstants.emoji_3,
  6: AppConstants.emoji_4,
  5: AppConstants.emoji_5,
  4: AppConstants.emoji_6,
  3: AppConstants.emoji_7,
  2: AppConstants.emoji_8,
  1: AppConstants.emoji_9,
};
