import 'package:you_app/ui/common/moderation_keywords.dart';

/// Where the text is being checked. Both contexts share the same detection
/// policy; the context is recorded on flags and lets callers diverge later.
enum ModerationContext { chat, community }

/// Content categories a message can match.
enum ModerationCategory {
  hate,
  violence,
  sexual,
  romance,
  offTopic,
  pii,
  banned
}

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
    this.matchedTerms = const {},
  });

  final ModerationAction action;
  final Set<ModerationCategory> categories;

  /// The offending keyword(s) that matched (lowercased). Used to build a
  /// human-readable escalation reason; empty for PII/regex-only matches.
  final Set<String> matchedTerms;

  /// [maskedText] has any PII blurred; equals the input when nothing matched.
  final String maskedText;
  final bool didMask;

  bool get isClean => action == ModerationAction.allow;
  bool get isBlocked => action == ModerationAction.block;

  /// Category names as plain strings (for Firestore flags / analytics).
  List<String> get categoryNames => categories.map((c) => c.name).toList();

  /// The dominant severity label for a flag record.
  String get severity {
    if (categories.contains(ModerationCategory.banned) ||
        categories.contains(ModerationCategory.hate) ||
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

  // Runtime config from `app_settings/moderation_config` (live-listened in
  // main.dart). When [_enabled] is false the engine is fully off: nothing is
  // blocked and PII is not masked. [_banned] is the admin's explicit hard-block
  // list, layered on top of the bundled category keywords.
  bool _enabled = true;
  List<String> _banned = const [];

  /// Applies the remote moderation config. Null args are ignored so a partial
  /// document never clobbers a field. Keywords are lowercased.
  void applyRemoteConfig({bool? enabled, List<String>? bannedKeywords}) {
    if (enabled != null) _enabled = enabled;
    if (bannedKeywords != null) {
      _banned = bannedKeywords
          .map((k) => k.toLowerCase().trim())
          .where((k) => k.isNotEmpty)
          .toList();
    }
  }

  /// `version` from the remote config; bumped by the admin panel on every save so
  /// client and server can detect a change. 0 = never received a versioned config.
  int _configVersion = 0;
  int get configVersion => _configVersion;

  /// Replace the per-category keyword lists from the admin panel's
  /// `app_settings/moderation_config` (any null arg keeps the bundled default).
  /// Terms are lowercased/trimmed/de-duped defensively — matching is
  /// case-insensitive and word-boundary based, so casing must not leak in.
  ///
  /// SAFETY INVARIANT: self-harm / suicidal phrasing must NEVER appear in these
  /// lists — those are crisis disclosures to escalate, not violations to block.
  /// See lib/ui/common/moderation_keywords.dart.
  void updateLists({
    List<String>? hate,
    List<String>? violence,
    List<String>? sexual,
    List<String>? romance,
    List<String>? offTopic,
    List<String>? contactIntent,
    int? version,
  }) {
    List<String> clean(List<String> raw) => raw
        .map((k) => k.toLowerCase().trim())
        .where((k) => k.isNotEmpty)
        .toSet()
        .toList();

    if (hate != null) _hate = clean(hate);
    if (violence != null) _violence = clean(violence);
    if (sexual != null) _sexual = clean(sexual);
    if (romance != null) _romance = clean(romance);
    if (offTopic != null) _offTopic = clean(offTopic);
    if (contactIntent != null) _contactIntent = clean(contactIntent);
    if (version != null) _configVersion = version;
  }

  ModerationResult inspect(String text, {required ModerationContext context}) {
    // Engine fully disabled by remote config: allow everything, mask nothing.
    if (!_enabled) {
      return ModerationResult(
        action: ModerationAction.allow,
        categories: const {},
        maskedText: text,
        didMask: false,
      );
    }

    final normalized = _normalize(text);
    final categories = <ModerationCategory>{};
    final matchedTerms = <String>{};

    void check(List<String> terms, ModerationCategory category) {
      final term = _firstMatch(normalized, terms);
      if (term != null) {
        categories.add(category);
        matchedTerms.add(term);
      }
    }

    check(_banned, ModerationCategory.banned);
    check(_hate, ModerationCategory.hate);
    check(_violence, ModerationCategory.violence);
    check(_sexual, ModerationCategory.sexual);
    check(_romance, ModerationCategory.romance);
    check(_offTopic, ModerationCategory.offTopic);

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
      matchedTerms: matchedTerms,
    );
  }

  /// Blurs phone numbers, emails, @handles and URLs in [text]. Deterministic.
  String maskPii(String text) {
    if (!_enabled) return text; // engine off → no masking
    var out = text;
    for (final pattern in ModerationKeywords.piiPatterns) {
      out = out.replaceAllMapped(pattern, (m) => _blur(m.group(0) ?? ''));
    }
    return out;
  }

  // --- internals ---

  ModerationAction _actionFor(Set<ModerationCategory> categories) {
    if (categories.contains(ModerationCategory.banned) ||
        categories.contains(ModerationCategory.hate) ||
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

  bool _containsAny(String normalized, List<String> terms) =>
      _firstMatch(normalized, terms) != null;

  /// Returns the first term (lowercased) that matches on a word boundary, or
  /// null if none match.
  String? _firstMatch(String normalized, List<String> terms) {
    for (final term in terms) {
      if (term.isEmpty) continue;
      final lower = term.toLowerCase();
      final pattern = RegExp('\\b${RegExp.escape(lower)}\\b');
      if (pattern.hasMatch(normalized)) return lower;
    }
    return null;
  }

  String _blur(String original) {
    // Keep it short and obviously redacted, regardless of original length.
    return '••• hidden •••';
  }
}
