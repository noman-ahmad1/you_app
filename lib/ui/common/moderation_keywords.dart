/// Default keyword / phrase lists for content moderation, grouped by category.
///
/// All entries are lowercase and matched on word boundaries against a
/// normalized (lowercased, whitespace-collapsed) message. This is a deliberately
/// conservative STARTER set — tune it, or override at runtime via the Firestore
/// doc `app_settings/moderation_config` (read by both the app and the Cloud
/// Functions). Keyword matching is blunt by design; an AI scorer can be layered
/// in later behind the same ModerationService interface.
///
/// ⚠️ SAFETY NOTE (mental-health app): self-harm / suicidal expressions
/// ("I want to die", "I might kill myself") are NOT moderation violations — they
/// are crisis disclosures that must reach a volunteer, never be blocked. The
/// `violence` list below therefore targets threats toward OTHERS only and must
/// not include self-referential distress phrases.
class ModerationKeywords {
  const ModerationKeywords._();

  /// Hateful / discriminatory language. Extend with project-specific terms.
  static const List<String> hate = [
    'go back to your country',
    'you people are',
    'subhuman',
    'i hate your kind',
    'filthy animal',
  ];

  /// Threats / incitement toward OTHERS (not self-harm — see safety note).
  static const List<String> violence = [
    'i will kill you',
    'i will hurt you',
    'i will beat you',
    'kill yourself',
    'kys',
    'i will find you',
    'i will stab',
    'i will shoot you',
    'you deserve to die',
  ];

  /// Sexual / explicit solicitation.
  static const List<String> sexual = [
    'send nudes',
    'send pics',
    'send your pics',
    'sexy pics',
    'nude photo',
    'hook up',
    'horny',
    'want to have sex',
  ];

  /// Romance / dating solicitation. Kept intentionally narrow — supportive
  /// language ("you matter", "i care about you") must NOT be flagged.
  static const List<String> romance = [
    'be my girlfriend',
    'be my boyfriend',
    'go on a date',
    'date me',
    'are you single',
    'marry me',
    'meet me in person',
    'i have a crush on you',
  ];

  /// Off-topic / spam / illicit-trade noise that doesn't belong in the app.
  static const List<String> offTopic = [
    'buy now',
    'investment opportunity',
    'make money fast',
    'free money',
    'crypto giveaway',
    'for sale',
    'drugs for sale',
    'weed for sale',
  ];

  /// Words signalling intent to move the conversation to an external contact
  /// channel (PII category) even when no literal handle/number is present.
  static const List<String> contactIntent = [
    'whatsapp',
    'snapchat',
    'snap me',
    'instagram',
    'insta',
    'telegram',
    'my number is',
    'call me at',
    'text me at',
    'add me on',
    'dm me',
  ];

  // --- PII regexes (used for both detection and masking) ---

  /// Phone-like digit runs (7+ digits, optional +, spaces, dashes, parens).
  static final RegExp phone =
      RegExp(r'(\+?\d[\d\s().-]{5,}\d)');

  /// Email addresses.
  static final RegExp email =
      RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}');

  /// Social @handles (e.g. @john_doe). 3+ chars to avoid trivial false hits.
  static final RegExp handle = RegExp(r'(?<![A-Za-z0-9._])@[A-Za-z0-9._]{3,}');

  /// URLs / domains.
  static final RegExp url = RegExp(
      r'((https?:\/\/)?[A-Za-z0-9-]+\.(com|net|org|io|app|me|co|info|xyz)(\/[^\s]*)?)',
      caseSensitive: false);

  /// All PII patterns, applied for masking (order matters: email/url before phone
  /// so digits inside them aren't partially masked first).
  static List<RegExp> get piiPatterns => [email, url, handle, phone];
}
