/**
 * Pure helpers for the Dodo AI gateway (Gemini).
 *
 * Split out of index.js so the request/response shaping can be unit tested
 * without a network call or the Firebase runtime — the same way moderation.js
 * is separated. index.js keeps the fetch and the secret.
 */

const DODO_SYSTEM_PROMPT = "You are Dodo, a comforting, empathetic, and " +
    "exceptionally supportive mental health assistant. Do not break character. " +
    "Provide short, practical, warm, and highly compassionate assistance to the " +
    "user. Do not give medical diagnoses.";

/**
 * Safety thresholds for Gemini.
 *
 * DANGEROUS_CONTENT is deliberately not blocked. That category covers self-harm,
 * and this is a mental-health app: a user disclosing suicidal thoughts is the
 * single most important message Dodo can receive. Blocking it would refuse the
 * people the product exists for, and it would contradict the invariant the
 * keyword moderation already documents (see lib/ui/common/moderation_keywords.dart
 * and moderation.js) — self-harm phrasing is a crisis disclosure to escalate,
 * never a violation to suppress.
 *
 * The other categories stay on a high-only threshold: this is a support chat,
 * so ordinary distressing language must get through, but abuse should not.
 */
const DODO_SAFETY_SETTINGS = [
    {category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_NONE"},
    {category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_ONLY_HIGH"},
    {category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_ONLY_HIGH"},
    {category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_ONLY_HIGH"},
];

/** Raised when Gemini declines to answer rather than failing outright. */
class DodoBlockedError extends Error {
    /** @param {string} reason The blockReason or finishReason Gemini returned. */
    constructor(reason) {
        super(`Gemini declined to answer: ${reason}`);
        this.name = "DodoBlockedError";
        this.reason = reason;
    }
}

/**
 * Converts the client's chat history into Gemini `contents`.
 *
 * Three shape rules the Groq/OpenAI format did not have:
 *  - roles are "user" and "model", not "user" and "assistant";
 *  - parts must be non-empty — a blank text errors the whole request;
 *  - the array must START with a user turn. The app seeds every conversation
 *    with Dodo's greeting, so the leading model turn(s) are dropped. Sending
 *    them makes the API reject the request, which would have surfaced to the
 *    user as "Dodo is having trouble" on the very first message.
 *
 * @param {Array<Object>} history Client turns, each {isMe: "true"|"false", text}.
 * @return {Array<Object>} Gemini-shaped contents, possibly empty.
 */
function toGeminiContents(history) {
    const turns = [];
    for (const msg of Array.isArray(history) ? history : []) {
        const text = (msg && msg.text ? msg.text : "").toString().trim();
        if (!text) continue;
        turns.push({
            role: msg.isMe === "true" ? "user" : "model",
            parts: [{text}],
        });
    }
    while (turns.length && turns[0].role !== "user") turns.shift();
    return turns;
}

/**
 * Extracts the reply text from a Gemini generateContent response.
 *
 * @param {Object} data Parsed JSON body.
 * @return {string} The reply text.
 * @throws {DodoBlockedError} When Gemini refused, produced nothing usable, or
 *   stopped for any reason other than a normal completion.
 */
function parseGeminiReply(data) {
    const blockReason = data && data.promptFeedback && data.promptFeedback.blockReason;
    if (blockReason) throw new DodoBlockedError(blockReason);

    const candidate = ((data && data.candidates) || [])[0];
    if (!candidate) throw new DodoBlockedError("NO_CANDIDATE");

    if (candidate.finishReason &&
        !["STOP", "MAX_TOKENS"].includes(candidate.finishReason)) {
        throw new DodoBlockedError(candidate.finishReason);
    }

    const parts = (candidate.content && candidate.content.parts) || [];
    const reply = parts.map((p) => (p && p.text) || "").join("").trim();
    if (!reply) throw new DodoBlockedError("EMPTY_REPLY");
    return reply;
}

/**
 * Builds the generateContent request body.
 *
 * @param {Array<Object>} contents Output of toGeminiContents.
 * @return {Object} Request body.
 */
function buildGeminiBody(contents) {
    return {
        systemInstruction: {parts: [{text: DODO_SYSTEM_PROMPT}]},
        contents,
        generationConfig: {temperature: 0.7, maxOutputTokens: 800},
        safetySettings: DODO_SAFETY_SETTINGS,
    };
}

module.exports = {
    DODO_SYSTEM_PROMPT,
    DODO_SAFETY_SETTINGS,
    DodoBlockedError,
    toGeminiContents,
    parseGeminiReply,
    buildGeminiBody,
};
