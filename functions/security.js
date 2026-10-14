/**
 * Request-security helpers. Pure.
 */

/**
 * The authoritative client IP for a callable/HTTPS request. Never trust a
 * client-sent IP — this reads it from the edge request metadata.
 * @param {Object} rawRequest The Express request (request.rawRequest).
 * @return {string} The source IP, or "unknown".
 */
function extractClientIp(rawRequest) {
    if (!rawRequest) return "unknown";
    const fwd = rawRequest.headers && rawRequest.headers["x-forwarded-for"];
    if (fwd && typeof fwd === "string") {
        const first = fwd.split(",")[0].trim();
        if (first) return first;
    }
    return rawRequest.ip || "unknown";
}

module.exports = {extractClientIp};
