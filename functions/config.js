/**
 * Parsing for the admin-tunable documents in `app_settings`.
 *
 * Pure: takes the document's data and returns the effective config, applying
 * defaults. The Firestore reads and caching stay in index.js, so this logic
 * ports unchanged to another backend.
 */

const DODO_DAILY_CAP_DEFAULT = 10;
const WELCOME_CHATS_DEFAULT = 3;
const COMMUNITY_THREADS_MONTHLY_DEFAULT = 5;
const COMMUNITY_REPLIES_MONTHLY_DEFAULT = 30;
const DODO_MODEL_DEFAULT = "gemini-2.5-flash";

/**
 * @param {*} v A raw config value.
 * @param {number} fallback Used when `v` isn't a positive number.
 * @return {number} `v` as a positive integer, or `fallback`.
 */
function asPositiveInt(v, fallback) {
    const n = typeof v === "number" ? Math.trunc(v) : parseInt(v, 10);
    return Number.isFinite(n) && n > 0 ? n : fallback;
}

/** @return {Object} The limits used when global_config can't be read. */
function defaultFreemiumLimits() {
    return {
        dodoModel: DODO_MODEL_DEFAULT,
        dodoDailyCap: DODO_DAILY_CAP_DEFAULT,
        welcomeChats: WELCOME_CHATS_DEFAULT,
        communityThreadsMonthly: COMMUNITY_THREADS_MONTHLY_DEFAULT,
        communityRepliesMonthly: COMMUNITY_REPLIES_MONTHLY_DEFAULT,
    };
}

/**
 * Effective free-tier limits from `app_settings/global_config`.
 * @param {Object} data The document data ({} when missing).
 * @return {Object} dodoModel, dodoDailyCap, welcomeChats,
 *   communityThreadsMonthly, communityRepliesMonthly.
 */
function parseFreemiumLimits(data) {
    const d = data || {};
    return {
        // Model id is tunable from the admin panel so it can be changed
        // without a redeploy, matching how the caps below work.
        dodoModel: typeof d.dodo_model === "string" && d.dodo_model.trim() ?
            d.dodo_model.trim() :
            DODO_MODEL_DEFAULT,
        dodoDailyCap: asPositiveInt(d.dodo_daily_cap, DODO_DAILY_CAP_DEFAULT),
        welcomeChats: asPositiveInt(d.welcome_chats, WELCOME_CHATS_DEFAULT),
        communityThreadsMonthly: asPositiveInt(
            d.community_threads_monthly, COMMUNITY_THREADS_MONTHLY_DEFAULT),
        communityRepliesMonthly: asPositiveInt(
            d.community_replies_monthly, COMMUNITY_REPLIES_MONTHLY_DEFAULT),
    };
}

/**
 * Effective moderation config from `app_settings/moderation_config`.
 * Supports the admin panel's per-category lists and the legacy
 * `enabled` / `bannedKeywords` shape.
 * @param {Object} data The document data ({} when missing).
 * @return {{enabled: boolean, lists: Object}} The config.
 */
function parseModerationConfig(data) {
    const d = data || {};
    const clean = (v) => Array.isArray(v) ?
        v.map((t) => String(t).toLowerCase().trim()).filter(Boolean) :
        undefined;

    const lists = {};
    // New per-category shape written by the admin panel.
    for (const key of ["hate", "violence", "sexual", "romance",
        "offTopic", "contactIntent"]) {
        const list = clean(d[key]);
        if (list) lists[key] = list;
    }
    // Legacy explicit hard-block list → the `banned` (severe) category.
    const banned = clean(d.bannedKeywords);
    if (banned) lists.banned = banned;

    return {
        // Legacy kill-switch; absent ⇒ moderation stays ON.
        enabled: d.enabled !== false,
        lists,
    };
}

module.exports = {
    DODO_DAILY_CAP_DEFAULT,
    WELCOME_CHATS_DEFAULT,
    COMMUNITY_THREADS_MONTHLY_DEFAULT,
    COMMUNITY_REPLIES_MONTHLY_DEFAULT,
    DODO_MODEL_DEFAULT,
    asPositiveInt,
    defaultFreemiumLimits,
    parseFreemiumLimits,
    parseModerationConfig,
};
