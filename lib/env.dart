import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Non-secret, compile-time configuration values.
class Environments {
  static const String appName = 'You';
  static const String privacyUrl = 'https://you-pakistan.web.app/privacy';
  static const String termsUrl = 'https://you-pakistan.web.app/terms';
  // static const String apiBaseURL = 'https://api.youtaicosmetic.net/';
  // static const String websiteURL = 'https://multi-salon.initappz.com/';
}

/// Values loaded from the gitignored `.env` file (see `.env.example`).
///
/// NOTE: `.env` is declared as a Flutter asset, so everything here ships inside
/// the APK/IPA in plain text and is recoverable with `unzip`. Only PUBLIC keys
/// belong in this file. Server-side secrets (Groq, Gemini) live in Cloud
/// Functions Secret Manager and are reached through callables — see
/// `sendDodoMessage` in functions/index.js.
class Secrets {
  /// RevenueCat public SDK key (Android / Google Play). Safe to ship in the
  /// app, but kept with the other keys for consistency.
  static String get revenueCatAndroidKey =>
      dotenv.env['REVENUECAT_ANDROID_KEY'] ?? '';
}
