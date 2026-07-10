import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Non-secret, compile-time configuration values.
class Environments {
  static const String appName = 'You';
  // static const String apiBaseURL = 'https://api.youtaicosmetic.net/';
  // static const String websiteURL = 'https://multi-salon.initappz.com/';
}

/// Runtime secrets loaded from the gitignored `.env` file (see `.env.example`).
/// Returns an empty string if a key is missing so callers fail gracefully.
class Secrets {
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// RevenueCat public SDK key (Android / Google Play). Safe to ship in the
  /// app, but kept with the other keys for consistency.
  static String get revenueCatAndroidKey =>
      dotenv.env['REVENUECAT_ANDROID_KEY'] ?? '';
}
