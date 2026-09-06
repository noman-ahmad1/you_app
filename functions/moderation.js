// Server-side content moderation (keyword + regex), mirroring the Flutter
// ModerationService so flags are authoritative and can't be bypassed by a
// tampered client. Keep the lists in sync with
// lib/ui/common/moderation_keywords.dart (or, later, source both from the
// Firestore doc app_settings/moderation_config).
//
// SAFETY NOTE: self-harm / suicidal expressions are NOT violations — the
// `violence` list targets threats toward OTHERS only.

const DEFAULT_LISTS = {
    hate: [
        "go back to your country",
        "you people are",
        "subhuman",
        "i hate your kind",
        "filthy animal",
    ],
    violence: [
        "i will kill you",
        "i will hurt you",
        "i will beat you",
        "kill yourself",
        "kys",
        "i will find you",
        "i will stab",
        "i will shoot you",
        "you deserve to die",
    ],
    sexual: [
        "send nudes",
        "send pics",
        "send your pics",
        "sexy pics",
        "nude photo",
        "hook up",
        "horny",
        "want to have sex",
    ],
    romance: [
        "be my girlfriend",
        "be my boyfriend",
        "go on a date",
        "date me",
        "are you single",
        "marry me",
        "meet me in person",
        "i have a crush on you",
    ],
    offTopic: [
        "buy now",
        "investment opportunity",
        "make money fast",
        "free money",
        "crypto giveaway",
        "for sale",
        "drugs for sale",
        "weed for sale",
    ],
    contactIntent: [
        "whatsapp",
        "snapchat",
        "snap me",
        "instagram",
        "insta",
        "telegram",
        "my number is",
        "call me at",
        "text me at",
        "add me on",
        "dm me",
    ],
    // Admin-authored hard-block list from app_settings/moderation_config
    // (`bannedKeywords`). Empty by default; treated as `severe`, mirroring the
    // Flutter ModerationService's `banned` category.
    banned: [],
};

const PII_PATTERNS = [
    /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g, // email
    /((https?:\/\/)?[A-Za-z0-9-]+\.(com|net|org|io|app|me|co|info|xyz)(\/[^\s]*)?)/gi, // url
    /(?<![A-Za-z0-9._])@[A-Za-z0-9._]{3,}/g, // @handle
    /(\+?\d[\d\s().-]{5,}\d)/g, // phone
];

function escapeRegExp(s) {
    return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function maskPii(text) {
    let out = text;
    for (const pattern of PII_PATTERNS) {
        out = out.replace(pattern, "••• hidden •••");
    }
    return out;
}

function containsAny(normalized, terms) {
    for (const term of terms) {
        if (!term) continue;
        const re = new RegExp(`\\b${escapeRegExp(term.toLowerCase())}\\b`);
        if (re.test(normalized)) return true;
    }
    return false;
}

function severityOf(categories) {
    if (categories.includes("banned") ||
        categories.includes("hate") ||
        categories.includes("violence") ||
        categories.includes("sexual")) {
        return "severe";
    }
    if (categories.includes("pii")) return "pii";
    return "moderate";
}

/**
 * Inspects text and returns { categories[], severity, masked, didMask, flagged }.
 * @param {string} text the message/post content.
 * @param {object} [lists] optional override lists (merged over defaults).
 * @return {object} moderation result.
 */
function inspect(text, lists) {
    const L = Object.assign({}, DEFAULT_LISTS, lists || {});
    const normalized = (text || "").toLowerCase().replace(/\s+/g, " ").trim();
    const categories = [];

    if (containsAny(normalized, L.banned)) categories.push("banned");
    if (containsAny(normalized, L.hate)) categories.push("hate");
    if (containsAny(normalized, L.violence)) categories.push("violence");
    if (containsAny(normalized, L.sexual)) categories.push("sexual");
    if (containsAny(normalized, L.romance)) categories.push("romance");
    if (containsAny(normalized, L.offTopic)) categories.push("offTopic");

    const masked = maskPii(text || "");
    const didMask = masked !== (text || "");
    if (didMask || containsAny(normalized, L.contactIntent)) {
        categories.push("pii");
    }

    return {
        categories,
        severity: severityOf(categories),
        masked,
        didMask,
        flagged: categories.length > 0,
    };
}

module.exports = {inspect, maskPii, DEFAULT_LISTS};
