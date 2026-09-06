const assert = require("node:assert/strict");
const {test, describe} = require("node:test");
const {
    DodoBlockedError, toGeminiContents, parseGeminiReply, buildGeminiBody,
} = require("../dodo");

describe("toGeminiContents", () => {
    test("maps isMe to Gemini roles, not OpenAI roles", () => {
        const out = toGeminiContents([
            {isMe: "true", text: "hi"},
            {isMe: "false", text: "hello"},
        ]);
        assert.deepEqual(out.map((t) => t.role), ["user", "model"]);
        assert.equal(out[0].parts[0].text, "hi");
    });

    test("drops the leading greeting so contents start with a user turn", () => {
        // Every conversation is seeded with Dodo's greeting. Sending a leading
        // model turn makes Gemini reject the whole request.
        const out = toGeminiContents([
            {isMe: "false", text: "Hi there! I am Dodo..."},
            {isMe: "true", text: "I feel low"},
        ]);
        assert.equal(out.length, 1);
        assert.equal(out[0].role, "user");
        assert.equal(out[0].parts[0].text, "I feel low");
    });

    test("drops several leading model turns", () => {
        const out = toGeminiContents([
            {isMe: "false", text: "greeting"},
            {isMe: "false", text: "still me"},
            {isMe: "true", text: "ok"},
            {isMe: "false", text: "reply"},
        ]);
        assert.deepEqual(out.map((t) => t.role), ["user", "model"]);
    });

    test("skips empty and whitespace-only turns", () => {
        const out = toGeminiContents([
            {isMe: "true", text: "  "},
            {isMe: "true", text: ""},
            {isMe: "true", text: "real"},
        ]);
        assert.equal(out.length, 1);
        assert.equal(out[0].parts[0].text, "real");
    });

    test("returns empty when there is no user turn at all", () => {
        assert.deepEqual(toGeminiContents([{isMe: "false", text: "only me"}]), []);
        assert.deepEqual(toGeminiContents([]), []);
        assert.deepEqual(toGeminiContents(null), []);
    });

    test("tolerates malformed entries", () => {
        const out = toGeminiContents([{}, {isMe: "true"}, {isMe: "true", text: 42}]);
        assert.equal(out.length, 1);
        assert.equal(out[0].parts[0].text, "42");
    });
});

describe("parseGeminiReply", () => {
    const ok = (text, finishReason = "STOP") => ({
        candidates: [{content: {parts: [{text}]}, finishReason}],
    });

    test("extracts the reply", () => {
        assert.equal(parseGeminiReply(ok("You're not alone.")), "You're not alone.");
    });

    test("joins multiple parts", () => {
        assert.equal(parseGeminiReply({
            candidates: [{content: {parts: [{text: "a"}, {text: "b"}]}, finishReason: "STOP"}],
        }), "ab");
    });

    test("accepts a truncated reply", () => {
        assert.equal(parseGeminiReply(ok("cut off", "MAX_TOKENS")), "cut off");
    });

    test("throws DodoBlockedError on a prompt-level block", () => {
        assert.throws(
            () => parseGeminiReply({promptFeedback: {blockReason: "SAFETY"}}),
            (e) => e instanceof DodoBlockedError && e.reason === "SAFETY",
        );
    });

    test("throws DodoBlockedError when generation stops on SAFETY", () => {
        assert.throws(
            () => parseGeminiReply(ok("partial", "SAFETY")),
            (e) => e instanceof DodoBlockedError && e.reason === "SAFETY",
        );
    });

    test("throws on no candidate and on an empty reply", () => {
        assert.throws(() => parseGeminiReply({candidates: []}), DodoBlockedError);
        assert.throws(() => parseGeminiReply(ok("   ")), DodoBlockedError);
        assert.throws(() => parseGeminiReply({}), DodoBlockedError);
    });
});

describe("buildGeminiBody", () => {
    const body = buildGeminiBody([{role: "user", parts: [{text: "hi"}]}]);

    test("hoists the persona into systemInstruction, not the turn list", () => {
        assert.match(body.systemInstruction.parts[0].text, /You are Dodo/);
        assert.equal(body.contents.length, 1);
        assert.equal(body.contents[0].role, "user");
    });

    test("does NOT block self-harm content", () => {
        // This app's whole safety design treats a self-harm disclosure as a
        // crisis to escalate, never something to suppress. If this assertion
        // ever fails, Dodo has started refusing the users it exists for.
        const dangerous = body.safetySettings.find(
            (s) => s.category === "HARM_CATEGORY_DANGEROUS_CONTENT");
        assert.ok(dangerous, "DANGEROUS_CONTENT must be configured explicitly");
        assert.equal(dangerous.threshold, "BLOCK_NONE");
    });

    test("still guards the abuse categories", () => {
        for (const cat of ["HARM_CATEGORY_HARASSMENT", "HARM_CATEGORY_HATE_SPEECH",
            "HARM_CATEGORY_SEXUALLY_EXPLICIT"]) {
            const s = body.safetySettings.find((x) => x.category === cat);
            assert.equal(s.threshold, "BLOCK_ONLY_HIGH", cat);
        }
    });
});
