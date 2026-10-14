const assert = require("node:assert/strict");
const {test, describe} = require("node:test");
const {pktDateKey, pktMonthKey, pad2} = require("../time");
const {parseFreemiumLimits, defaultFreemiumLimits, parseModerationConfig} = require("../config");
const {isUserPremium, classifyRevenueCatEvent, entitlementFromSubscriber} = require("../entitlement");
const {extractClientIp} = require("../security");

describe("time (PKT, UTC+5)", () => {
    test("rolls the day over at PKT midnight, not UTC midnight", () => {
        assert.equal(pktDateKey(new Date("2026-03-14T18:59:59Z")), "2026-03-14");
        assert.equal(pktDateKey(new Date("2026-03-14T19:00:00Z")), "2026-03-15");
    });
    test("month keys roll at PKT month start", () => {
        assert.equal(pktMonthKey(new Date("2026-01-31T18:59:59Z")), "2026-01");
        assert.equal(pktMonthKey(new Date("2026-01-31T19:00:00Z")), "2026-02");
    });
    test("pads single digits", () => {
        assert.equal(pad2(3), "03");
        assert.equal(pad2(12), "12");
    });
});

describe("parseFreemiumLimits", () => {
    test("missing document → defaults", () => {
        assert.deepEqual(parseFreemiumLimits({}), defaultFreemiumLimits());
        assert.deepEqual(parseFreemiumLimits(undefined), defaultFreemiumLimits());
    });
    test("reads valid values, truncating decimals and parsing strings", () => {
        const l = parseFreemiumLimits({dodo_daily_cap: 25.9, welcome_chats: "4", dodo_model: " gemini-x "});
        assert.equal(l.dodoDailyCap, 25);
        assert.equal(l.welcomeChats, 4);
        assert.equal(l.dodoModel, "gemini-x");
    });
    test("zero, negative and junk fall back rather than locking users out", () => {
        const l = parseFreemiumLimits({dodo_daily_cap: 0, welcome_chats: -1, community_threads_monthly: "x"});
        const d = defaultFreemiumLimits();
        assert.equal(l.dodoDailyCap, d.dodoDailyCap);
        assert.equal(l.welcomeChats, d.welcomeChats);
        assert.equal(l.communityThreadsMonthly, d.communityThreadsMonthly);
    });
});

describe("parseModerationConfig", () => {
    test("absent enabled keeps moderation on", () => {
        assert.equal(parseModerationConfig({}).enabled, true);
        assert.equal(parseModerationConfig({enabled: false}).enabled, false);
    });
    test("cleans lists and maps bannedKeywords to banned", () => {
        const c = parseModerationConfig({hate: [" Foo ", "", 3], bannedKeywords: ["X"], nope: ["a"]});
        assert.deepEqual(c.lists, {hate: ["foo", "3"], banned: ["x"]});
    });
});

describe("isUserPremium", () => {
    const ts = (ms) => ({toMillis: () => ms});
    test("free or missing user is not premium", () => {
        assert.equal(isUserPremium(null), false);
        assert.equal(isUserPremium({subscriptionTier: "free"}), false);
    });
    test("premium with no expiry is an indefinite grant", () => {
        assert.equal(isUserPremium({subscriptionTier: "premium"}), true);
    });
    test("respects expiry", () => {
        assert.equal(isUserPremium({subscriptionTier: "premium", subscription_expiry: ts(2000)}, 1000), true);
        assert.equal(isUserPremium({subscriptionTier: "premium", subscription_expiry: ts(1000)}, 2000), false);
    });
    test("an unreadable expiry fails open", () => {
        assert.equal(isUserPremium({subscriptionTier: "premium", subscription_expiry: "2020"}), true);
    });
});

describe("classifyRevenueCatEvent", () => {
    test("purchases and renewals grant, with expiry", () => {
        assert.deepEqual(
            classifyRevenueCatEvent({type: "RENEWAL", app_user_id: "u1", expiration_at_ms: 5}),
            {action: "grant", uid: "u1", expiryMs: 5});
    });
    test("expiration and refund revoke", () => {
        assert.equal(classifyRevenueCatEvent({type: "REFUND", app_user_id: "u1"}).action, "revoke");
        assert.equal(classifyRevenueCatEvent({type: "EXPIRATION", app_user_id: "u1"}).action, "revoke");
    });
    test("cancellation does NOT revoke — the user paid until expiry", () => {
        assert.equal(classifyRevenueCatEvent({type: "CANCELLATION", app_user_id: "u1"}).action, "noop");
        assert.equal(classifyRevenueCatEvent({type: "BILLING_ISSUE", app_user_id: "u1"}).action, "noop");
    });
    test("anonymous RevenueCat ids are skipped", () => {
        assert.equal(classifyRevenueCatEvent({type: "RENEWAL", app_user_id: "$RCAnonymousID:x"}).action, "skip");
        assert.equal(classifyRevenueCatEvent({type: "RENEWAL"}).action, "skip");
    });
});

describe("entitlementFromSubscriber", () => {
    const body = (ent) => ({subscriber: {entitlements: {you_plus: ent}}});
    test("future expiry → entitled", () => {
        assert.deepEqual(entitlementFromSubscriber(body({expires_date: "2030-01-01T00:00:00Z"}), 0),
            {entitled: true, expiryMs: Date.parse("2030-01-01T00:00:00Z")});
    });
    test("past or garbage expiry → not entitled", () => {
        assert.equal(entitlementFromSubscriber(body({expires_date: "2000-01-01T00:00:00Z"})).entitled, false);
        assert.equal(entitlementFromSubscriber(body({expires_date: "garbage"})).entitled, false);
    });
    test("no expiry → lifetime entitlement", () => {
        assert.deepEqual(entitlementFromSubscriber(body({})), {entitled: true, expiryMs: null});
    });
    test("missing entitlement → not entitled", () => {
        assert.equal(entitlementFromSubscriber({}).entitled, false);
        assert.equal(entitlementFromSubscriber(null).entitled, false);
    });
});

describe("extractClientIp", () => {
    test("prefers the first X-Forwarded-For hop", () => {
        assert.equal(extractClientIp({headers: {"x-forwarded-for": " 9.9.9.9 , 1.1.1.1"}, ip: "2.2.2.2"}), "9.9.9.9");
    });
    test("falls back to req.ip, then unknown", () => {
        assert.equal(extractClientIp({headers: {}, ip: "2.2.2.2"}), "2.2.2.2");
        assert.equal(extractClientIp(null), "unknown");
    });
});
