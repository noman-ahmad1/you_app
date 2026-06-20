import 'package:you_app/ui/common/moderation_keywords.dart';

/// Where the text is being checked. Both contexts share the same detection
/// policy; the context is recorded on flags and lets callers diverge later.
enum ModerationContext { chat, community }

/// Content categories a message can match.
enum ModerationCategory { hate, violence, sexual, romance, offTopic, pii }

/// What the caller should do with the message.
enum ModerationAction {
  /// Clean — send normally.
  allow,

  /// Send, but warn the sender (romance / off-topic).
  warnSend,

  /// Send, but blur PII when rendering (contact info shared).
  maskSend,

  /// Do not send; warn the sender (hate / violence / sexual).
  block,
}

/// Result of inspecting a piece of text.
class ModerationResult {
  ModerationResult({
    required this.action,
    required this.categories,
    required this.maskedText,
    required this.didMask,
  });

  final ModerationAction action;
  final Set<ModerationCategory> categories;

  /// [maskedText] has any PII blurred; equals the input when nothing matched.
  final String maskedText;
  final bool didMask;

  bool get isClean => action == ModerationAction.allow;
  bool get isBlocked => action == ModerationAction.block;

  /// Category names as plain strings (for Firestore flags / analytics).
  List<String> get categoryNames => categories.map((c) => c.name).toList();

  /// The dominant severity label for a flag record.
  String get severity {
    if (categories.contains(ModerationCategory.hate) ||
        categories.contains(ModerationCategory.violence) ||
        categories.contains(ModerationCategory.sexual)) {
      return 'severe';
    }
    if (categories.contains(ModerationCategory.pii)) return 'pii';
    return 'moderate';
  }
}

/// Keyword + regex content moderation. Pure and deterministic so the same
/// result can be recomputed on any device (e.g. recipients re-mask PII at
/// render time). Cloud Functions run an equivalent JS port for authoritative,
/// unbypassable flagging.
///
/// Registered as a LazySingleton; holds no Firebase dependency itself. (Runtime
/// keyword overrides from `app_settings/moderation_config` can be layered in
/// later via [updateLists] without touching call sites.)
class ModerationService {
  // Mutable copies so a future Firestore override can replace them; seeded with
  // the bundled defaults.
  List<String> _hate = ModerationKeywords.hate;
  List<String> _violence = ModerationKeywords.violence;
  List<String> _sexual = ModerationKeywords.sexual;
  List<String> _romance = ModerationKeywords.romance;
  List<String> _offTopic = ModerationKeywords.offTopic;
  List<String> _contactIntent = ModerationKeywords.contactIntent;

  /// Replace the keyword lists from a remote config (any null arg is kept).
  void updateLists({
    List<String>? hate,
    List<String>? violence,
    List<String>? sexual,
    List<String>? romance,
    List<String>? offTopic,
    List<String>? contactIntent,
  }) {
    if (hate != null) _hate = hate;
    if (violence != null) _violence = violence;
    if (sexual != null) _sexual = sexual;
    if (romance != null) _romance = romance;
    if (offTopic != null) _offTopic = offTopic;
    if (contactIntent != null) _contactIntent = contactIntent;
  }

  ModerationResult inspect(String text, {required ModerationContext context}) {
    final normalized = _normalize(text);
    final categories = <ModerationCategory>{};

    if (_containsAny(normalized, _hate)) {
      categories.add(ModerationCategory.hate);
    }
    if (_containsAny(normalized, _violence)) {
      categories.add(ModerationCategory.violence);
    }
    if (_containsAny(normalized, _sexual)) {
      categories.add(ModerationCategory.sexual);
    }
    if (_containsAny(normalized, _romance)) {
      categories.add(ModerationCategory.romance);
    }
    if (_containsAny(normalized, _offTopic)) {
      categories.add(ModerationCategory.offTopic);
    }

    final masked = maskPii(text);
    final didMask = masked != text;
    if (didMask || _containsAny(normalized, _contactIntent)) {
      categories.add(ModerationCategory.pii);
    }

    final action = _actionFor(categories);
    return ModerationResult(
      action: action,
      categories: categories,
      maskedText: masked,
      didMask: didMask,
    );
  }

  /// Blurs phone numbers, emails, @handles and URLs in [text]. Deterministic.
  String maskPii(String text) {
    var out = text;
    for (final pattern in ModerationKeywords.piiPatterns) {
      out = out.replaceAllMapped(pattern, (m) => _blur(m.group(0) ?? ''));
    }
    return out;
  }

  // --- internals ---

  ModerationAction _actionFor(Set<ModerationCategory> categories) {
    if (categories.contains(ModerationCategory.hate) ||
        categories.contains(ModerationCategory.violence) ||
        categories.contains(ModerationCategory.sexual)) {
      return ModerationAction.block;
    }
    if (categories.contains(ModerationCategory.pii)) {
      return ModerationAction.maskSend;
    }
    if (categories.contains(ModerationCategory.romance) ||
        categories.contains(ModerationCategory.offTopic)) {
      return ModerationAction.warnSend;
    }
    return ModerationAction.allow;
  }

  String _normalize(String text) =>
      text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  bool _containsAny(String normalized, List<String> terms) {
    for (final term in terms) {
      if (term.isEmpty) continue;
      final pattern =
          RegExp('\\b${RegExp.escape(term.toLowerCase())}\\b');
      if (pattern.hasMatch(normalized)) return true;
    }
    return false;
  }

  String _blur(String original) {
    // Keep it short and obviously redacted, regardless of original length.
    return '••• hidden •••';
  }
}
