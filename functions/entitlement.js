/**
 * Premium entitlement rules. Pure — the reads and writes stay in index.js.
 */

// The RevenueCat entitlement that unlocks YOU+ (matches the app + dashboard).
const YOU_PLUS_ENTITLEMENT = "you_plus";

const GRANT_EVENTS = ["INITIAL_PURCHASE", "RENEWAL", "PRODUCT_CHANGE",
    "UNCANCELLATION", "NON_RENEWING_PURCHASE"];
const REVOKE_EVENTS = ["EXPIRATION", "REFUND"];

/**
 * Whether a user document represents an active premium entitlement.
 *
 * @param {Object} userData A user doc's data.
 * @param {number} [nowMs] The current time; defaults to now.
 * @return {boolean} True when the tier is premium and not past its expiry.
 */
function isUserPremium(userData, nowMs = Date.now()) {
    if (!userData || userData.subscriptionTier !== "premium") return false;
    const exp = userData.subscription_expiry;
    if (!exp) return true; // indefinite grant
    try {
        return exp.toMillis() > nowMs;
    } catch (e) {
        return true;
    }
}

/**
 * What a RevenueCat webhook event means for the user's entitlement.
 *
 * CANCELLATION (auto-renew off — still entitled until expiry), BILLING_ISSUE
 * (grace), TRANSFER and the rest are "noop": no entitlement change.
 *
 * @param {Object} event The webhook's `event` object.
 * @return {{action: string, uid: (string|undefined), expiryMs: ?number}}
 *   action is "skip" (anonymous id), "grant", "revoke" or "noop".
 */
function classifyRevenueCatEvent(event) {
    const uid = event.app_user_id;
    // Skip anonymous ids (user not yet aliased to a Firebase UID via logIn).
    if (!uid || uid.indexOf("$RCAnonymousID") === 0) {
        return {action: "skip", uid, expiryMs: null};
    }
    if (GRANT_EVENTS.indexOf(event.type) !== -1) {
        return {action: "grant", uid, expiryMs: event.expiration_at_ms || null};
    }
    if (REVOKE_EVENTS.indexOf(event.type) !== -1) {
        return {action: "revoke", uid, expiryMs: null};
    }
    return {action: "noop", uid, expiryMs: null};
}

/**
 * Reads the YOU+ entitlement from a RevenueCat REST `GET /subscribers` body.
 *
 * @param {Object} body The parsed response body.
 * @param {number} [nowMs] The current time; defaults to now.
 * @return {{entitled: boolean, expiryMs: ?number}} The entitlement.
 */
function entitlementFromSubscriber(body, nowMs = Date.now()) {
    const subscriber = body && body.subscriber;
    const entitlements = subscriber && subscriber.entitlements;
    const ent = entitlements && entitlements[YOU_PLUS_ENTITLEMENT];
    if (!ent) return {entitled: false, expiryMs: null};
    if (!ent.expires_date) return {entitled: true, expiryMs: null}; // non-expiring
    const ms = Date.parse(ent.expires_date);
    if (!Number.isNaN(ms) && ms > nowMs) return {entitled: true, expiryMs: ms};
    return {entitled: false, expiryMs: null};
}

module.exports = {
    YOU_PLUS_ENTITLEMENT,
    isUserPremium,
    classifyRevenueCatEvent,
    entitlementFromSubscriber,
};
