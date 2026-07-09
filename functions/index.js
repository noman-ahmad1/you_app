// Import the v2 trigger for Firestore
const { onDocumentDeleted, onDocumentCreated } = require("firebase-functions/v2/firestore");

// Import the v2 scheduler + https triggers (for daily analytics aggregation)
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");

// Groq API key — server-side secret (was previously shipped in the client .env).
// Set with: firebase functions:secrets:set GROQ_API_KEY
const { defineSecret } = require("firebase-functions/params");
const GROQ_API_KEY = defineSecret("GROQ_API_KEY");

// RevenueCat billing secrets.
// - WEBHOOK_SECRET: the exact Authorization header value configured on the
//   RevenueCat dashboard webhook; verified on every incoming event.
// - REST_API_KEY: a RevenueCat secret (v1) API key used to server-verify a
//   subscriber's entitlement after a purchase/restore.
// Set with: firebase functions:secrets:set REVENUECAT_WEBHOOK_SECRET
//           firebase functions:secrets:set REVENUECAT_REST_API_KEY
const REVENUECAT_WEBHOOK_SECRET = defineSecret("REVENUECAT_WEBHOOK_SECRET");
const REVENUECAT_REST_API_KEY = defineSecret("REVENUECAT_REST_API_KEY");

// Import the Firebase Admin SDK
const admin = require("firebase-admin");

// Import the logger
const logger = require("firebase-functions/logger");

// Keyword/regex moderation engine (mirrors the Flutter ModerationService)
const moderation = require("./moderation");

// Initialize the Admin SDK
admin.initializeApp();
const db = admin.firestore();

/**
 * This function triggers when any document in the 'chats' collection is deleted.
 * It then automatically deletes all messages in its 'messages' subcollection.
 * This is the v2 (latest) syntax.
 */
exports.cleanupChatroom = onDocumentDeleted("chats/{chatId}", async (event) => {
    // Get the 'chatId' from the event parameters
    const { chatId } = event.params;

    logger.log(`Cleaning up messages for chatroom: ${chatId}`);

    // This line targets ONLY the 'messages' subcollection
    // INSIDE the single document that was deleted.
    const collectionRef = db.collection("chats")
        .doc(chatId)
        .collection("messages");

    try {
        await db.recursiveDelete(collectionRef);
        logger.log(`Successfully cleaned up chatroom: ${chatId}`);
    } catch (error) {
        logger.error(`Error cleaning up chats ${chatId}:`, error);
    }
});

/**
 * Auto-expiry: a volunteer chat ends automatically 24 hours after it is
 * accepted. On accept, the chat doc is created with `createdAt` = accept time
 * (and a `requestId` pointer). This scheduled job runs hourly, finds active
 * chats older than 24h, and marks both the chat and its request `completed`
 * (with `endedBy: 'system'` / `endedAt`). The requester's open chat view reacts
 * to the status flip, and the volunteers screen then offers a review prompt.
 * Idempotent: only `status == 'active'` chats are touched, so re-runs no-op.
 */
exports.expireStaleChats = onSchedule(
    { schedule: "every 1 hours", timeZone: "Asia/Karachi" },
    async () => {
        const cutoff = admin.firestore.Timestamp.fromMillis(
            Date.now() - 24 * 60 * 60 * 1000);

        const snap = await db.collection("chats")
            .where("status", "==", "active")
            .where("createdAt", "<=", cutoff)
            .limit(300)
            .get();

        if (snap.empty) {
            logger.log("expireStaleChats: no chats to expire.");
            return;
        }

        const now = admin.firestore.FieldValue.serverTimestamp();
        // Use a BulkWriter, not a WriteBatch: a batch is hard-capped at 500
        // writes, and this loop emits up to 2 writes per chat (the chat + its
        // matching request), so a backlog >250 chats would blow the cap and
        // fail the whole commit. BulkWriter auto-chunks and rate-limits with no
        // such cap (same approach as cleanupSecurityLogs).
        const writer = db.bulkWriter();
        let count = 0;

        for (const doc of snap.docs) {
            const data = doc.data() || {};
            writer.set(doc.ref, {
                status: "completed",
                endedBy: "system",
                endedAt: now,
            }, { merge: true });

            // Complete the matching request too. New chats carry `requestId`;
            // older ones are resolved from the sorted participant ids in the id.
            let requestRef = null;
            if (data.requestId) {
                requestRef = db.collection("chat_requests").doc(data.requestId);
            } else {
                const parts = doc.id.split("_");
                if (parts.length === 2) {
                    try {
                        const q = await db.collection("chat_requests")
                            .where("requesterId", "in", parts)
                            .where("volunteerId", "in", parts)
                            .where("status", "==", "accepted")
                            .limit(1)
                            .get();
                        if (!q.empty) requestRef = q.docs[0].ref;
                    } catch (e) {
                        logger.error(`expireStaleChats: request lookup failed for ${doc.id}:`, e);
                    }
                }
            }
            if (requestRef) {
                writer.set(requestRef, {
                    status: "completed",
                    endedAt: now,
                }, { merge: true });
            }
            count++;
        }

        // Surface failures instead of swallowing them: if close() throws, the
        // scheduled run is marked failed and retries next hour, rather than
        // silently reporting success while expiring nothing.
        await writer.close();
        logger.log(`expireStaleChats: expired ${count} chat(s).`);
    },
);

/**
 * Two-Layer Trigger: Fires when a notification is written to a user's subcollection.
 * Path: users/{userId}/notifications/{notificationId}
 */
exports.onNotificationCreated = onDocumentCreated("users/{userId}/notifications/{notificationId}", async (event) => {
    const snap = event.data;
    if (!snap) {
        logger.log("No data associated with the event");
        return;
    }
    
    // Extract the recipient ID directly from the document path
    const userId = event.params.userId;
    const notificationData = snap.data();
    const { title, body, data } = notificationData;

    logger.log(`Centralized Notification triggered for user: ${userId}`);

    try {
        // Retrieve recipient's FCM token
        const userDoc = await db.collection("users").doc(userId).get();
        if (!userDoc.exists) {
            logger.error(`User document for ${userId} not found.`);
            return;
        }

        const fcmToken = userDoc.data().fcmToken;

        if (!fcmToken) {
            logger.log(`FCM token for user ${userId} is not available. Skipping push.`);
            return;
        }

        // Standardize data payload to String values for FCM compliance
        const standardizedData = {
            click_action: "FLUTTER_NOTIFICATION_CLICK"
        };
        if (data && typeof data === "object") {
            Object.keys(data).forEach((key) => {
                standardizedData[key] = String(data[key]);
            });
        }

        // Construct unified messaging payload
        const payload = {
            token: fcmToken,
            notification: {
                title: title || "New Update",
                body: body || ""
            },
            data: standardizedData,
            android: {
                priority: "high",
                notification: {
                    sound: "default"
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                        badge: 1
                    }
                }
            }
        };

        const response = await admin.messaging().send(payload);
        logger.log(`FCM push dispatched successfully: ${response}`);
    } catch (error) {
        logger.error(`FCM dispatch failed for user ${userId}:`, error);
    }
});

/**
 * Triggers when a new reply is created.
 * Notifies the original post author if someone else replies.
 */
exports.onReplyCreated = onDocumentCreated("posts/{postId}/replies/{replyId}", async (event) => {
    const snap = event.data;
    if (!snap) return;

    const replyData = snap.data();
    const postId = event.params.postId;

    try {
        const postDoc = await db.collection("posts").doc(postId).get();
        if (!postDoc.exists) return;

        const postData = postDoc.data();
        if (replyData.authorId && postData.authorId && replyData.authorId !== postData.authorId) {
            await db.collection("users").doc(postData.authorId).collection("notifications").add({
                title: "New Reply",
                body: `${replyData.authorUsername || "Someone"} replied to your thread.`,
                type: "new_reply",
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                data: {
                    postId: postId,
                    route: "thread_detail"
                }
            });
            logger.log(`Created new_reply notification for user ${postData.authorId}`);
        }
    } catch (error) {
        logger.error(`Error in onReplyCreated:`, error);
    }
});

/**
 * Helper function to handle mentions in both posts and replies
 */
async function handleMentions(docData, postId, triggerType) {
    const mentionedUsers = docData.mentionedUsers || [];
    const authorUsername = docData.authorUsername || "Someone";
    const authorId = docData.authorId;

    if (!Array.isArray(mentionedUsers) || mentionedUsers.length === 0) return;

    // Premium-only backstop: mentioning is a Premium feature. Even if a free
    // client forges mentionedUsers on a reply, no mention notifications fire.
    if (authorId) {
        try {
            const authorSnap = await db.collection("users").doc(authorId).get();
            if (!isUserPremium(authorSnap.data())) {
                logger.log(`Skipped mentions from non-premium user ${authorId}`);
                return;
            }
        } catch (e) {
            logger.error("handleMentions premium check failed:", e);
            return; // fail closed — don't notify if we can't verify entitlement
        }
    }

    for (const userId of mentionedUsers) {
        if (userId === authorId) continue; // Skip notifying self

        await db.collection("users").doc(userId).collection("notifications").add({
            title: "New Mention",
            body: `${authorUsername} mentioned you in a ${triggerType}.`,
            type: "new_mention",
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            data: {
                postId: postId,
                route: "thread_detail"
            }
        });
        logger.log(`Created new_mention notification for user ${userId}`);
    }
}

/**
 * Triggers when a new post is created.
 * Notifies all mentioned users.
 */
exports.onPostMention = onDocumentCreated("posts/{postId}", async (event) => {
    const snap = event.data;
    if (!snap) return;
    try {
        await handleMentions(snap.data(), event.params.postId, "post");
    } catch (error) {
        logger.error(`Error in onPostMention:`, error);
    }
});

/**
 * Triggers when a new reply is created.
 * Notifies all mentioned users in the reply.
 */
exports.onReplyMention = onDocumentCreated("posts/{postId}/replies/{replyId}", async (event) => {
    const snap = event.data;
    if (!snap) return;
    try {
        await handleMentions(snap.data(), event.params.postId, "reply");
    } catch (error) {
        logger.error(`Error in onReplyMention:`, error);
    }
});

// ============================================================================
// Daily analytics aggregation (for the Angular admin dashboard)
// Writes pre-aggregated counters to daily_analytics/{YYYY-MM-DD}, one doc per
// calendar day. Uses Firestore aggregation count() queries (no full reads).
// Karachi (PKT) is a fixed UTC+5 with no DST, so a constant offset is safe and
// keeps the doc-id date and day-window boundaries stable.
// ============================================================================

const KARACHI_OFFSET_MS = 5 * 60 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;

function pad2(n) {
    return n < 10 ? `0${n}` : `${n}`;
}

/**
 * Computes the dashboard counters for the Karachi calendar day that contains
 * `referenceInstant` and writes them to daily_analytics/{YYYY-MM-DD}.
 * Idempotent (set with merge). Returns the written payload.
 * @param {Date} referenceInstant Any instant within the target day.
 * @return {Promise<Object>} The dateId and the six computed counts.
 */
async function aggregateForDay(referenceInstant) {
    // Read the Karachi wall-clock date via a UTC-shifted view of the instant.
    const shifted = new Date(referenceInstant.getTime() + KARACHI_OFFSET_MS);
    const y = shifted.getUTCFullYear();
    const m = shifted.getUTCMonth(); // 0-based
    const d = shifted.getUTCDate();
    const dateId = `${y}-${pad2(m + 1)}-${pad2(d)}`;

    // Day window in real UTC: [start of Karachi day, start of next Karachi day).
    const startMs = Date.UTC(y, m, d) - KARACHI_OFFSET_MS;
    const startTs = admin.firestore.Timestamp.fromMillis(startMs);
    const nextTs = admin.firestore.Timestamp.fromMillis(startMs + DAY_MS);

    const usersRef = db.collection("users");
    const postsRef = db.collection("posts");

    // Aggregation count(): returns just the number, not the documents.
    const countOf = async (query) => (await query.count().get()).data().count;

    const [
        totalUsers,
        totalVolunteers,
        activeVolunteers,
        pendingVolunteers,
        newUsers,
        postsToday,
    ] = await Promise.all([
        countOf(usersRef),
        countOf(usersRef.where("role", "==", "volunteer")),
        countOf(usersRef
            .where("role", "==", "volunteer")
            .where("status", "==", "active")),
        countOf(usersRef
            .where("role", "==", "volunteer")
            .where("status", "==", "pending_verification")),
        countOf(usersRef
            .where("createdAt", ">=", startTs)
            .where("createdAt", "<", nextTs)),
        countOf(postsRef
            .where("createdAt", ">=", startTs)
            .where("createdAt", "<", nextTs)),
    ]);

    const counts = {
        totalUsers,
        totalVolunteers,
        activeVolunteers,
        pendingVolunteers,
        newUsers,
        postsToday,
    };

    await db.collection("daily_analytics").doc(dateId).set(
        {
            ...counts,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
    );

    logger.log(`daily_analytics written for ${dateId}: ${JSON.stringify(counts)}`);
    return { dateId, ...counts };
}

/**
 * Scheduled daily at 00:05 Asia/Karachi. Writes the JUST-FINISHED day's doc so
 * newUsers/postsToday reflect a complete calendar day. Combined with the manual
 * seed below, every calendar day ends up with exactly one daily_analytics doc.
 */
exports.aggregateDailyAnalytics = onSchedule(
    { schedule: "5 0 * * *", timeZone: "Asia/Karachi" },
    async () => {
        // 1s before the start of today (Karachi) falls inside yesterday.
        const nowShifted = new Date(Date.now() + KARACHI_OFFSET_MS);
        const startTodayMs = Date.UTC(
            nowShifted.getUTCFullYear(),
            nowShifted.getUTCMonth(),
            nowShifted.getUTCDate(),
        ) - KARACHI_OFFSET_MS;
        const yesterdayRef = new Date(startTodayMs - 1000);
        try {
            await aggregateForDay(yesterdayRef);
        } catch (error) {
            logger.error("aggregateDailyAnalytics failed:", error);
            throw error;
        }
    },
);

/**
 * Manual trigger that recomputes TODAY's (Asia/Karachi) doc immediately. Used
 * once right after deploy to seed the dashboard so its trend isn't empty until
 * the scheduler first runs.
 *
 * Admin-only callable (was a public HTTPS endpoint guarded by a shared token —
 * which deployed publicly and leaked live counts to anyone with the token).
 * Now it requires an authenticated admin and returns only { ok, written }, no
 * raw metrics. Invoke from the admin panel or a signed-in admin context.
 */
exports.runDailyAnalyticsNow = onCall(async (request) => {
    const callerUid = request.auth && request.auth.uid;
    if (!callerUid) throw new HttpsError("unauthenticated", "Sign in first.");
    if ((await roleOf(callerUid)) !== "admin") {
        throw new HttpsError("permission-denied", "Admins only.");
    }
    try {
        const written = await aggregateForDay(new Date());
        return { ok: true, written };
    } catch (error) {
        logger.error("runDailyAnalyticsNow failed:", error);
        throw new HttpsError("internal", "Failed to seed analytics.");
    }
});

// ============================================================================
// Content moderation (authoritative server-side flagging)
// Re-checks DELIVERED chat messages & community content; on a match it records a
// moderation_flags doc for the admin panel and tags the source doc so clients
// can show an "under review" state. Blocked (never-delivered) content is flagged
// by the client instead. Multiple create-triggers per path are allowed, so
// these coexist with the existing onReply*/onPost* functions.
// ============================================================================

async function recordContentFlag(flag, sourceRef, result) {
    await db.collection("moderation_flags").add(flag);
    try {
        await sourceRef.set({
            moderation: {
                flagged: true,
                categories: result.categories,
                masked: result.didMask,
            },
        }, { merge: true });
    } catch (e) {
        logger.error("Failed to tag moderated doc:", e);
    }
}

exports.moderateChatMessage = onDocumentCreated("chats/{chatId}/messages/{messageId}", async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data();
    const text = data.text || "";
    const result = moderation.inspect(text);
    if (!result.flagged) return;

    const { chatId, messageId } = event.params;
    const senderId = data.senderId || "";
    const recipientId = chatId.split("_").find((id) => id !== senderId) || "";

    await recordContentFlag({
        source: "chat",
        chatId,
        messageId,
        senderId,
        recipientId,
        text,
        categories: result.categories,
        severity: result.severity,
        action: "flagged",
        delivered: true,
        status: "open",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, snap.ref, result);
    logger.log(`Flagged chat message ${messageId} (${result.categories.join(",")})`);
});

exports.moderatePost = onDocumentCreated("posts/{postId}", async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data();
    const text = data.content || "";
    const result = moderation.inspect(text);
    if (!result.flagged) return;

    await recordContentFlag({
        source: "post",
        postId: event.params.postId,
        communityId: data.communityId || null,
        senderId: data.authorId || "",
        text,
        categories: result.categories,
        severity: result.severity,
        action: "flagged",
        delivered: true,
        status: "open",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, snap.ref, result);
    logger.log(`Flagged post ${event.params.postId} (${result.categories.join(",")})`);
});

exports.moderateReply = onDocumentCreated("posts/{postId}/replies/{replyId}", async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data();
    const text = data.content || "";
    const result = moderation.inspect(text);
    if (!result.flagged) return;

    await recordContentFlag({
        source: "reply",
        postId: event.params.postId,
        replyId: event.params.replyId,
        senderId: data.authorId || "",
        text,
        categories: result.categories,
        severity: result.severity,
        action: "flagged",
        delivered: true,
        status: "open",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, snap.ref, result);
    logger.log(`Flagged reply ${event.params.replyId} (${result.categories.join(",")})`);
});

// ============================================================================
// Freemium enforcement (authoritative, server-side)
//
// These gates protect features that consume paid resources — Dodo (AI tokens)
// and volunteer welcome chats (volunteer time). The client counterparts are UX
// only; these functions are the source of truth. Journal/mood history windows
// are NOT gated here (they read a user's OWN private data — no security
// boundary — so they are enforced client-side).
// ============================================================================

const DODO_DAILY_CAP_DEFAULT = 10;
const WELCOME_CHATS_DEFAULT = 3;
const COMMUNITY_THREADS_MONTHLY_DEFAULT = 5;
const COMMUNITY_REPLIES_MONTHLY_DEFAULT = 30;

/**
 * Karachi (PKT, fixed UTC+5, no DST) calendar-day key `YYYY-MM-DD` for `instant`.
 * Used so Dodo's daily cap resets at PKT midnight regardless of device timezone.
 * @param {Date} instant The instant to derive the day key for.
 * @return {string} The PKT date key.
 */
function pktDateKey(instant) {
    const shifted = new Date(instant.getTime() + KARACHI_OFFSET_MS);
    return `${shifted.getUTCFullYear()}-${pad2(shifted.getUTCMonth() + 1)}-${pad2(shifted.getUTCDate())}`;
}

/**
 * Karachi (PKT) calendar-MONTH key `YYYY-MM` for `instant`. Used so the free
 * community-thread cap resets at the start of each PKT month.
 * @param {Date} instant The instant to derive the month key for.
 * @return {string} The PKT month key.
 */
function pktMonthKey(instant) {
    const shifted = new Date(instant.getTime() + KARACHI_OFFSET_MS);
    return `${shifted.getUTCFullYear()}-${pad2(shifted.getUTCMonth() + 1)}`;
}

/** @return {Promise<{dodoDailyCap:number, welcomeChats:number, communityThreadsMonthly:number}>} live limits. */
async function getFreemiumLimits() {
    try {
        const snap = await db.collection("app_settings").doc("global_config").get();
        const data = snap.exists ? snap.data() : {};
        const asPositiveInt = (v, fallback) => {
            const n = typeof v === "number" ? Math.trunc(v) : parseInt(v, 10);
            return Number.isFinite(n) && n > 0 ? n : fallback;
        };
        return {
            dodoDailyCap: asPositiveInt(data.dodo_daily_cap, DODO_DAILY_CAP_DEFAULT),
            welcomeChats: asPositiveInt(data.welcome_chats, WELCOME_CHATS_DEFAULT),
            communityThreadsMonthly: asPositiveInt(
                data.community_threads_monthly, COMMUNITY_THREADS_MONTHLY_DEFAULT),
            communityRepliesMonthly: asPositiveInt(
                data.community_replies_monthly, COMMUNITY_REPLIES_MONTHLY_DEFAULT),
        };
    } catch (e) {
        logger.error("getFreemiumLimits failed, using defaults:", e);
        return {
            dodoDailyCap: DODO_DAILY_CAP_DEFAULT,
            welcomeChats: WELCOME_CHATS_DEFAULT,
            communityThreadsMonthly: COMMUNITY_THREADS_MONTHLY_DEFAULT,
            communityRepliesMonthly: COMMUNITY_REPLIES_MONTHLY_DEFAULT,
        };
    }
}

/**
 * Shared monthly-quota reserve used by the community thread + reply callables.
 * Inside a transaction: for a FREE user, reads the `{ month, count }` usage doc
 * and, if this PKT month's count is below `limit`, increments it (reserving one
 * unit); premium is never counted. MUST be called before any transaction writes
 * other than the ones it makes (it reads `usageRef`).
 * @param {FirebaseFirestore.Transaction} tx The active transaction.
 * @param {FirebaseFirestore.DocumentReference} usageRef The usage counter doc.
 * @param {string} monthKey Current PKT month key (`YYYY-MM`).
 * @param {number} limit The free-tier monthly allowance.
 * @param {boolean} premium Whether the caller is premium (skips the counter).
 * @return {Promise<boolean>} true when the cap is already reached (abort).
 */
async function reserveMonthlyQuota(tx, usageRef, monthKey, limit, premium) {
    if (premium) return false;
    const snap = await tx.get(usageRef);
    const data = snap.exists ? snap.data() : {};
    const count = data.month === monthKey ? (data.count || 0) : 0;
    if (count >= limit) return true; // cap reached
    tx.set(usageRef, { month: monthKey, count: count + 1 });
    return false;
}

/** @param {Object} userData A user doc's data. @return {boolean} premium & unexpired. */
function isUserPremium(userData) {
    if (!userData || userData.subscriptionTier !== "premium") return false;
    const exp = userData.subscription_expiry;
    if (!exp) return true; // indefinite grant
    try {
        return exp.toMillis() > Date.now();
    } catch (e) {
        return true;
    }
}

// The RevenueCat entitlement that unlocks YOU+ (matches the app + dashboard).
const YOU_PLUS_ENTITLEMENT = "you_plus";

/**
 * Write an entitlement decision to a user doc via Admin SDK — the ONLY server
 * path that mutates subscription fields. Grants set premium + expiry + source;
 * revokes set free, but NEVER downgrade an admin-granted user (manual / early
 * supporter / partner grants stay intact regardless of store events).
 * @param {string} uid Firebase UID (== RevenueCat app_user_id after logIn).
 * @param {boolean} entitled Whether the store says the user is entitled.
 * @param {number|null} expiryMs Entitlement expiry in epoch ms, or null.
 * @param {string} source Source label to record (e.g. "google_play").
 * @return {Promise<void>}
 */
async function applyEntitlement(uid, entitled, expiryMs, source) {
    const userRef = db.collection("users").doc(uid);
    if (entitled) {
        const update = {
            subscriptionTier: "premium",
            subscription_source: source,
            subscription_expiry: expiryMs ?
                admin.firestore.Timestamp.fromMillis(expiryMs) : null,
        };
        await userRef.set(update, { merge: true });
        return;
    }
    // Revoke path — protect admin grants from being flipped to free.
    const snap = await userRef.get();
    const data = snap.data() || {};
    if (data.subscription_source === "admin") {
        logger.info(`applyEntitlement: skip revoke for admin grant ${uid}`);
        return;
    }
    await userRef.set({ subscriptionTier: "free" }, { merge: true });
}

/**
 * RevenueCat webhook → Firestore entitlement writer (the authoritative path).
 * Verifies the shared Authorization secret, then grants/revokes premium by
 * event type. Returns 2xx for handled events so RevenueCat does not retry.
 */
exports.revenueCatWebhook = onRequest(
    { secrets: [REVENUECAT_WEBHOOK_SECRET] },
    async (req, res) => {
        const expected = REVENUECAT_WEBHOOK_SECRET.value();
        const provided = req.get("Authorization") || "";
        if (!expected || provided !== expected) {
            res.status(401).json({ error: "Unauthorized" });
            return;
        }

        const event = req.body && req.body.event;
        if (!event || !event.type) {
            res.status(400).json({ error: "Bad event" });
            return;
        }

        const uid = event.app_user_id;
        // Skip anonymous ids (user not yet aliased to a Firebase UID via logIn).
        if (!uid || uid.indexOf("$RCAnonymousID") === 0) {
            res.status(200).json({ ok: true, skipped: "anonymous" });
            return;
        }

        const grant = ["INITIAL_PURCHASE", "RENEWAL", "PRODUCT_CHANGE",
            "UNCANCELLATION", "NON_RENEWING_PURCHASE"];
        const revoke = ["EXPIRATION", "REFUND"];

        try {
            if (grant.indexOf(event.type) !== -1) {
                await applyEntitlement(
                    uid, true, event.expiration_at_ms || null, "google_play");
            } else if (revoke.indexOf(event.type) !== -1) {
                await applyEntitlement(uid, false, null, "google_play");
            } else {
                // CANCELLATION (auto-renew off — still entitled until expiry),
                // BILLING_ISSUE (grace), TRANSFER, etc. — no entitlement change.
                logger.info(`revenueCatWebhook: no-op ${event.type} for ${uid}`);
            }
            res.status(200).json({ ok: true });
        } catch (error) {
            logger.error("revenueCatWebhook failed:", error);
            res.status(500).json({ ok: false });
        }
    },
);

/**
 * Server-verified entitlement refresh. The app calls this right after a
 * purchase/restore for an instant, trustworthy unlock (and to self-heal a
 * missed webhook). Queries RevenueCat's REST API for the CALLER's subscriber —
 * the client is never trusted to assert its own entitlement.
 * @return {Promise<{isPremium: boolean}>}
 */
exports.refreshEntitlement = onCall(
    { secrets: [REVENUECAT_REST_API_KEY] },
    async (request) => {
        const uid = request.auth && request.auth.uid;
        if (!uid) {
            throw new HttpsError("unauthenticated", "Sign in first.");
        }
        const key = REVENUECAT_REST_API_KEY.value();
        if (!key) {
            throw new HttpsError("failed-precondition", "Billing not configured.");
        }

        let entitled = false;
        let expiryMs = null;
        try {
            const url = "https://api.revenuecat.com/v1/subscribers/" +
                encodeURIComponent(uid);
            const resp = await fetch(url, {
                headers: { "Authorization": `Bearer ${key}` },
            });
            if (resp.ok) {
                const body = await resp.json();
                const subscriber = body && body.subscriber;
                const entitlements = subscriber && subscriber.entitlements;
                const ent = entitlements && entitlements[YOU_PLUS_ENTITLEMENT];
                if (ent) {
                    if (ent.expires_date) {
                        const ms = Date.parse(ent.expires_date);
                        if (!Number.isNaN(ms) && ms > Date.now()) {
                            entitled = true;
                            expiryMs = ms;
                        }
                    } else {
                        entitled = true; // non-expiring entitlement
                    }
                }
            } else {
                logger.warn(`refreshEntitlement: RC REST ${resp.status} ${uid}`);
            }
        } catch (error) {
            logger.error("refreshEntitlement REST failed:", error);
            throw new HttpsError("unavailable", "Couldn't verify right now.");
        }

        // Grant-only: a client-triggered refresh may confirm entitlement and
        // unlock, but must NEVER revoke — a misconfigured REST key or a
        // transient error would otherwise strip a legitimate user. Revocation
        // is the webhook's authoritative job (EXPIRATION / REFUND).
        if (entitled) {
            await applyEntitlement(uid, true, expiryMs, "google_play");
        }
        return { isPremium: entitled };
    },
);

/**
 * Dodo AI gateway. Free users are capped at `dodo_daily_cap` messages per PKT
 * day; premium is unlimited. Reserves the daily slot in a transaction BEFORE
 * calling Groq (so concurrent sends can't overshoot), then calls Groq with the
 * server-held key. On Groq failure the slot is refunded (best-effort).
 * Request: { history: [{ isMe: 'true'|'false', text: string }, ...] }
 * Response: { reply } on success, or { capReached: true } when the cap is hit.
 */
exports.sendDodoMessage = onCall({ secrets: [GROQ_API_KEY] }, async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in to chat with Dodo.");

    const history = Array.isArray(request.data && request.data.history)
        ? request.data.history
        : [];

    const userRef = db.collection("users").doc(uid);
    const usageRef = userRef.collection("usage").doc("dodo");
    const { dodoDailyCap } = await getFreemiumLimits();
    const today = pktDateKey(new Date());

    // Reserve a slot atomically (free users only). Premium skips the counter.
    const reserved = await db.runTransaction(async (tx) => {
        const userSnap = await tx.get(userRef);
        if (isUserPremium(userSnap.data())) return { premium: true };

        const usageSnap = await tx.get(usageRef);
        const usage = usageSnap.exists ? usageSnap.data() : {};
        const count = usage.date === today ? (usage.count || 0) : 0;
        if (count >= dodoDailyCap) return { capReached: true };

        tx.set(usageRef, { date: today, count: count + 1 }, { merge: true });
        return { count: count + 1 };
    });

    if (reserved.capReached) return { capReached: true };

    // Refunds a reserved free-tier slot when the downstream Groq call fails.
    const refund = async () => {
        if (reserved.premium) return;
        try {
            await db.runTransaction(async (tx) => {
                const s = await tx.get(usageRef);
                const d = s.exists ? s.data() : {};
                if (d.date === today && (d.count || 0) > 0) {
                    tx.set(usageRef, { date: today, count: d.count - 1 }, { merge: true });
                }
            });
        } catch (e) {
            logger.error("Dodo slot refund failed:", e);
        }
    };

    try {
        const reply = await callGroq(history);
        return { capReached: false, reply };
    } catch (e) {
        await refund();
        logger.error("sendDodoMessage Groq call failed:", e);
        throw new HttpsError("unavailable", "Dodo is having trouble right now.");
    }
});

/**
 * Calls Groq's chat completions with Dodo's persona. Mirrors the persona/model
 * the client previously used. Node 22 provides global fetch.
 * @param {Array<{isMe:string, text:string}>} history Conversation so far.
 * @return {Promise<string>} The assistant reply text.
 */
async function callGroq(history) {
    const messages = [{
        role: "system",
        content: "You are Dodo, a comforting, empathetic, and exceptionally supportive mental health assistant. Do not break character. Provide short, practical, warm, and highly compassionate assistance to the user. Do not give medical diagnoses.",
    }];
    for (const msg of history) {
        messages.push({
            role: msg.isMe === "true" ? "user" : "assistant",
            content: (msg.text || "").toString(),
        });
    }

    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
        method: "POST",
        headers: {
            "Authorization": `Bearer ${GROQ_API_KEY.value()}`,
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            model: "llama-3.1-8b-instant",
            messages,
            temperature: 0.7,
        }),
    });
    if (!response.ok) {
        throw new Error(`Groq API ${response.status}: ${await response.text()}`);
    }
    const data = await response.json();
    try {
        return data.choices[0].message.content;
    } catch (e) {
        return "I'm having a little trouble focusing right now. Could you repeat that?";
    }
}

/**
 * Race-safe volunteer chat request. Free users get `welcome_chats` lifetime
 * chats (never renew); premium is unlimited. A transaction checks + increments
 * `welcomeChatsUsed` AND creates the chat_requests doc together, so concurrent
 * requests serialize on the user doc and a free user can never exceed the cap.
 * The charge is refunded (see onChatRequest* triggers) if the request is
 * declined or cancelled, so a used slot always maps to a real/active chat.
 * Request: { volunteerId, requesterName, requesterAvatarUrl?, topic? }
 * Response: { requestId } on success, or { capReached: true } when exhausted.
 */
exports.requestVolunteerChat = onCall(async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in to request a chat.");

    const { volunteerId, requesterName, requesterAvatarUrl, topic } = request.data || {};
    if (!volunteerId || typeof volunteerId !== "string") {
        throw new HttpsError("invalid-argument", "A volunteerId is required.");
    }

    const userRef = db.collection("users").doc(uid);
    const requestRef = db.collection("chat_requests").doc();
    const { welcomeChats } = await getFreemiumLimits();

    const outcome = await db.runTransaction(async (tx) => {
        const userSnap = await tx.get(userRef);
        const userData = userSnap.data() || {};
        const premium = isUserPremium(userData);
        const used = userData.welcomeChatsUsed || 0;

        if (!premium && used >= welcomeChats) return { capReached: true };

        tx.set(requestRef, {
            requesterId: uid,
            requesterName: requesterName || "",
            requesterAvatarUrl: requesterAvatarUrl || null,
            volunteerId,
            status: "pending",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            topic: topic || null,
            isPriority: premium,
            // `charged` marks that this request consumed a free-tier welcome slot,
            // so refund triggers know whether/what to give back. Never for premium.
            charged: !premium,
        });

        if (!premium) {
            tx.set(userRef, { welcomeChatsUsed: used + 1 }, { merge: true });
        }
        return { requestId: requestRef.id };
    });

    if (outcome.capReached) return { capReached: true };

    // Notify the volunteer (best-effort; mirrors the old client-side write).
    try {
        await db.collection("users").doc(volunteerId).collection("notifications").add({
            title: "New Chat Request 💬",
            body: `${requesterName || "Someone"} wants to connect with you.`,
            type: "request_received",
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            data: { requestId: outcome.requestId, route: "volunteer_dashboard" },
        });
    } catch (e) {
        logger.error("requestVolunteerChat notification failed:", e);
    }

    // Safety metadata (best-effort; isolated from analytics). chat_created is
    // logged here since this is the one chat action with a server touchpoint.
    try {
        await writeSecurityLog(
            uid, await roleOf(uid),
            extractClientIp(request.rawRequest), "chat_created");
    } catch (e) {
        logger.error("requestVolunteerChat security log failed:", e);
    }

    return { capReached: false, requestId: outcome.requestId };
});

/**
 * Race-safe community thread creation. Free users may start up to
 * `community_threads_monthly` new threads per PKT calendar month; premium is
 * unlimited. A transaction checks + increments the monthly counter AND writes
 * the post together, so concurrent posts can't overshoot the cap. Direct client
 * writes to `posts` are denied by rules — all threads come through here.
 * Viewing and replying are NOT gated. Free users' mentions are stripped.
 * Request: { communityId, content, authorUsername, mentionedUsers? }
 * Response: { postId } on success, or { capReached: true } when exhausted.
 */
exports.createCommunityPost = onCall(async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in to post.");

    const { communityId, content, authorUsername, mentionedUsers } =
        request.data || {};
    if (!communityId || typeof communityId !== "string") {
        throw new HttpsError("invalid-argument", "A communityId is required.");
    }
    if (!content || typeof content !== "string" || !content.trim()) {
        throw new HttpsError("invalid-argument", "Post content is required.");
    }

    const userRef = db.collection("users").doc(uid);
    const usageRef = userRef.collection("usage").doc("community_threads");
    const postRef = db.collection("posts").doc();
    const { communityThreadsMonthly } = await getFreemiumLimits();
    const thisMonth = pktMonthKey(new Date());

    const outcome = await db.runTransaction(async (tx) => {
        const userSnap = await tx.get(userRef);
        const premium = isUserPremium(userSnap.data());

        const capReached = await reserveMonthlyQuota(
            tx, usageRef, thisMonth, communityThreadsMonthly, premium);
        if (capReached) return { capReached: true };

        // Free users can't mention (backstop against a forged client).
        const mentions =
            premium && Array.isArray(mentionedUsers) ? mentionedUsers : [];

        tx.set(postRef, {
            communityId,
            authorId: uid,
            authorUsername: authorUsername || "",
            content: content.trim(),
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            likeCount: 0,
            replyCount: 0,
            likedBy: [],
            mentionedUsers: mentions,
        });
        return { postId: postRef.id };
    });

    if (outcome.capReached) return { capReached: true };
    return { capReached: false, postId: outcome.postId };
});

/**
 * Race-safe community reply creation — the reply counterpart of
 * createCommunityPost, sharing the same monthly-quota mechanism with its own
 * (separate) limit + counter. Free users may post up to
 * `community_replies_monthly` replies per PKT month; premium is unlimited.
 * Increments the parent post's replyCount in the same transaction. Direct
 * client writes to the replies subcollection are denied by rules. Free users'
 * mentions are stripped.
 * Request: { postId, content, authorUsername, mentionedUsers? }
 * Response: { replyId } on success, or { capReached: true } when exhausted.
 */
exports.createCommunityReply = onCall(async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in to reply.");

    const { postId, content, authorUsername, mentionedUsers } =
        request.data || {};
    if (!postId || typeof postId !== "string") {
        throw new HttpsError("invalid-argument", "A postId is required.");
    }
    if (!content || typeof content !== "string" || !content.trim()) {
        throw new HttpsError("invalid-argument", "Reply content is required.");
    }

    const userRef = db.collection("users").doc(uid);
    const usageRef = userRef.collection("usage").doc("community_replies");
    const postRef = db.collection("posts").doc(postId);
    const replyRef = postRef.collection("replies").doc();
    const { communityRepliesMonthly } = await getFreemiumLimits();
    const thisMonth = pktMonthKey(new Date());

    const outcome = await db.runTransaction(async (tx) => {
        const userSnap = await tx.get(userRef);
        const premium = isUserPremium(userSnap.data());

        const capReached = await reserveMonthlyQuota(
            tx, usageRef, thisMonth, communityRepliesMonthly, premium);
        if (capReached) return { capReached: true };

        const mentions =
            premium && Array.isArray(mentionedUsers) ? mentionedUsers : [];

        tx.set(replyRef, {
            postId,
            authorId: uid,
            authorUsername: authorUsername || "",
            content: content.trim(),
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            likeCount: 0,
            likedBy: [],
            mentionedUsers: mentions,
        });
        tx.update(postRef, {
            replyCount: admin.firestore.FieldValue.increment(1),
        });
        return { replyId: replyRef.id };
    });

    if (outcome.capReached) return { capReached: true };
    return { capReached: false, replyId: outcome.replyId };
});

/**
 * Refunds a free-tier welcome slot when a still-charged request is declined,
 * so a decline never costs the user a welcome chat. Idempotent: it clears
 * `charged` in the same transaction, so re-fires and the later delete no-op.
 */
exports.onChatRequestDeclined = onDocumentUpdated("chat_requests/{requestId}", async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after) return;
    if (!(before.status === "pending" && after.status === "declined")) return;
    if (after.charged !== true) return; // premium or already refunded

    const requesterId = after.requesterId;
    if (!requesterId) return;
    try {
        await db.runTransaction(async (tx) => {
            const userRef = db.collection("users").doc(requesterId);
            const snap = await tx.get(userRef);
            // Don't resurrect a deleted user's doc (e.g. account deletion racing
            // this refund) — a set(merge) on a missing doc would recreate it.
            if (!snap.exists) return;
            const used = (snap.data() || {}).welcomeChatsUsed || 0;
            tx.set(userRef, { welcomeChatsUsed: Math.max(0, used - 1) }, { merge: true });
            tx.update(event.data.after.ref, { charged: false });
        });
        logger.log(`Refunded welcome chat for ${requesterId} (declined).`);
    } catch (e) {
        logger.error("onChatRequestDeclined refund failed:", e);
    }
});

/**
 * Refunds a free-tier welcome slot when a still-charged PENDING request is
 * cancelled (doc deleted). An accepted chat (status 'accepted') stays charged —
 * it became a real conversation. A declined one was already refunded/cleared.
 */
exports.onChatRequestDeleted = onDocumentDeleted("chat_requests/{requestId}", async (event) => {
    const data = event.data && event.data.data();
    if (!data) return;
    if (data.status !== "pending" || data.charged !== true) return;

    const requesterId = data.requesterId;
    if (!requesterId) return;
    try {
        await db.runTransaction(async (tx) => {
            const userRef = db.collection("users").doc(requesterId);
            const snap = await tx.get(userRef);
            // Don't resurrect a deleted user's doc (e.g. account deletion racing
            // this refund) — a set(merge) on a missing doc would recreate it.
            if (!snap.exists) return;
            const used = (snap.data() || {}).welcomeChatsUsed || 0;
            tx.set(userRef, { welcomeChatsUsed: Math.max(0, used - 1) }, { merge: true });
        });
        logger.log(`Refunded welcome chat for ${requesterId} (cancelled).`);
    } catch (e) {
        logger.error("onChatRequestDeleted refund failed:", e);
    }
});

/**
 * User-initiated account deletion (GDPR / app-store compliance). Runs with the
 * Admin SDK so it can remove data that security rules deny to clients
 * (users/{uid} is `delete: if false`). For the authenticated caller it deletes:
 *   • their user doc + all subcollections (journal, notifications, usage)
 *   • their volunteer_info doc + reviews subcollection (if any)
 *   • community posts they authored (+ replies, via recursiveDelete)
 *   • mood entries, chats they participate in (+ messages), and chat_requests
 *   • uploaded Storage files (profile pics, journal audio, verification docs)
 *   • the Firebase Auth user (last)
 * Each Firestore/Storage section is best-effort: a failure is logged and does
 * not abort the rest, so a partial failure still removes as much as possible.
 * The Auth user is deleted last and its failure IS surfaced to the client, so
 * the app never tells the user their account is gone while the login still works.
 */
exports.deleteMyAccount = onCall(async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");

    // Capture the role before the user doc is deleted (best-effort, for the log).
    let role = "user";
    try {
        role = await roleOf(uid);
    } catch (e) {
        // Non-fatal — proceed with the default.
    }

    // --- Firestore: docs with subcollections via recursiveDelete ---
    try {
        await db.recursiveDelete(db.collection("users").doc(uid));
    } catch (e) {
        logger.error(`deleteMyAccount: user doc delete failed for ${uid}:`, e);
    }
    try {
        await db.recursiveDelete(db.collection("volunteer_info").doc(uid));
    } catch (e) {
        logger.error(`deleteMyAccount: volunteer_info delete failed for ${uid}:`, e);
    }
    try {
        const posts = await db.collection("posts")
            .where("authorId", "==", uid).get();
        for (const doc of posts.docs) {
            await db.recursiveDelete(doc.ref); // post + its replies subcollection
        }
    } catch (e) {
        logger.error(`deleteMyAccount: posts delete failed for ${uid}:`, e);
    }

    // --- Firestore: flat/bulk deletes via one BulkWriter (no 500 cap) ---
    const writer = db.bulkWriter();
    try {
        const moods = await db.collection("mood")
            .where("userId", "==", uid).get();
        moods.forEach((d) => writer.delete(d.ref));
    } catch (e) {
        logger.error(`deleteMyAccount: mood query failed for ${uid}:`, e);
    }
    try {
        const chats = await db.collection("chats")
            .where("participants", "array-contains", uid).get();
        for (const doc of chats.docs) {
            const msgs = await doc.ref.collection("messages").get();
            msgs.forEach((m) => writer.delete(m.ref));
            writer.delete(doc.ref);
        }
    } catch (e) {
        logger.error(`deleteMyAccount: chats query failed for ${uid}:`, e);
    }
    try {
        const asRequester = await db.collection("chat_requests")
            .where("requesterId", "==", uid).get();
        asRequester.forEach((d) => writer.delete(d.ref));
        const asVolunteer = await db.collection("chat_requests")
            .where("volunteerId", "==", uid).get();
        asVolunteer.forEach((d) => writer.delete(d.ref));
    } catch (e) {
        logger.error(`deleteMyAccount: chat_requests query failed for ${uid}:`, e);
    }
    try {
        await writer.close();
    } catch (e) {
        logger.error(`deleteMyAccount: bulk delete failed for ${uid}:`, e);
    }

    // --- Storage (best-effort): all uploads live under `<folder>/<uid>/…` ---
    const storageFolders = [
        "user_profiles", "journal_audio",
        "volunteer_profiles", "volunteer_id_cards", "volunteer_id_cards_back",
        "volunteer_student_ids", "volunteer_student_ids_back",
    ];
    try {
        // Name the bucket explicitly so it works regardless of how the Admin SDK
        // resolved the default bucket at init.
        const bucket = admin.storage().bucket("you-app-c6b1f.firebasestorage.app");
        await Promise.all(storageFolders.map((folder) =>
            bucket.deleteFiles({ prefix: `${folder}/${uid}/` })
                .catch((e) => logger.error(
                    `deleteMyAccount: storage purge ${folder} failed:`, e)),
        ));
    } catch (e) {
        logger.error(`deleteMyAccount: storage cleanup failed for ${uid}:`, e);
    }

    // --- Auth (last): Admin SDK deletion needs no recent client login ---
    try {
        await admin.auth().deleteUser(uid);
    } catch (e) {
        logger.error(`deleteMyAccount: auth deletion failed for ${uid}:`, e);
        throw new HttpsError("internal",
            "Your data was removed but the login could not be fully deleted. Please contact support.");
    }

    logger.log(`deleteMyAccount: deleted account ${uid} (role ${role}).`);
    return { ok: true };
});

/**
 * When an admin deletes a community thread (posts/{postId}), cascade-delete its
 * replies subcollection so no orphans remain (mirrors cleanupChatroom).
 */
exports.onPostDeleted = onDocumentDeleted("posts/{postId}", async (event) => {
    const { postId } = event.params;
    try {
        await db.recursiveDelete(
            db.collection("posts").doc(postId).collection("replies"),
        );
        logger.log(`Cleaned up replies for deleted post: ${postId}`);
    } catch (error) {
        logger.error(`Error cleaning up replies for post ${postId}:`, error);
    }
});

// ============================================================================
// Safety metadata: minimal, disclosed IP + timestamp trail for misconduct
// accountability. This is NOT analytics and NOT location tracking — IP + coarse
// action + timestamp only, in the isolated `security_logs` collection, written
// solely by the Admin SDK and readable by admins only (via console / Admin SDK).
// See docs/SECURITY_LOGS.md. NO GPS. NO message content.
// ============================================================================

const SECURITY_LOG_RETENTION_DAYS_DEFAULT = 90;
// Actions the client may self-report via logSecurityEvent. `chat_created` is
// logged server-side inside requestVolunteerChat, so it is intentionally absent.
const CLIENT_SECURITY_ACTIONS = [
    "signup", "signin", "message_sent", "report_filed",
];

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

/**
 * The role recorded on a user's doc, defaulting to "user".
 * @param {string} uid The user id.
 * @return {Promise<string>} 'user' | 'volunteer' | 'admin'.
 */
async function roleOf(uid) {
    try {
        const snap = await db.collection("users").doc(uid).get();
        const role = snap.exists ? snap.data().role : null;
        return role || "user";
    } catch (e) {
        return "user";
    }
}

/**
 * Append one safety-log document (Admin SDK; bypasses the deny-all rules).
 * @param {string} uid Acting user.
 * @param {string} role Their role at the time.
 * @param {string} ip Server-captured IP.
 * @param {string} action Coarse action label.
 * @return {Promise<void>}
 */
async function writeSecurityLog(uid, role, ip, action) {
    await db.collection("security_logs").add({
        uid,
        role: role || "user",
        ip: ip || "unknown",
        action,
        retainForCase: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
}

/**
 * Client-invoked safety logger. Captures the IP server-side (un-spoofable) for
 * the direct-write actions that have no other server touchpoint. Soft-fails so
 * it can never break a user flow.
 */
exports.logSecurityEvent = onCall(async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");
    const action = request.data && request.data.action;
    if (CLIENT_SECURITY_ACTIONS.indexOf(action) === -1) {
        throw new HttpsError("invalid-argument", "Unknown action.");
    }
    try {
        const ip = extractClientIp(request.rawRequest);
        const role = await roleOf(uid);
        await writeSecurityLog(uid, role, ip, action);
    } catch (e) {
        logger.error("logSecurityEvent failed:", e);
    }
    return { ok: true };
});

/**
 * Retention cleanup: delete security logs older than the configured window
 * (app_settings/global_config.security_log_retention_days, default 90) EXCEPT
 * docs pinned to an open case (retainForCase === true).
 */
exports.cleanupSecurityLogs = onSchedule(
    { schedule: "30 0 * * *", timeZone: "Asia/Karachi" },
    async () => {
        let days = SECURITY_LOG_RETENTION_DAYS_DEFAULT;
        try {
            const snap = await db.collection("app_settings")
                .doc("global_config").get();
            const data = snap.exists ? snap.data() : {};
            const raw = data.security_log_retention_days;
            const n = typeof raw === "number" ? Math.trunc(raw) : parseInt(raw, 10);
            if (Number.isFinite(n) && n > 0) days = n;
        } catch (e) {
            logger.error("cleanupSecurityLogs config read failed:", e);
        }

        const cutoff = admin.firestore.Timestamp.fromMillis(
            Date.now() - days * 24 * 60 * 60 * 1000);
        const writer = db.bulkWriter();
        let deleted = 0;
        let last = null;
        // Page forward past retained docs (which we never delete) so the loop
        // can't stall on them.
        for (let i = 0; i < 100; i++) {
            let q = db.collection("security_logs")
                .where("timestamp", "<", cutoff)
                .orderBy("timestamp")
                .limit(400);
            if (last) q = q.startAfter(last);
            const page = await q.get();
            if (page.empty) break;
            page.docs.forEach((doc) => {
                if (doc.get("retainForCase") === true) return;
                writer.delete(doc.ref);
                deleted++;
            });
            last = page.docs[page.docs.length - 1];
            if (page.size < 400) break;
        }
        await writer.close();
        logger.log(
            `cleanupSecurityLogs: deleted ${deleted} logs older than ${days}d`);
    },
);

/**
 * Admin-only: pin (or release) every security log for a user so retention keeps
 * them while a misconduct case is open. Callers must have role 'admin'.
 * Request: { uid, retain }  (retain defaults to true unless explicitly false).
 */
exports.flagUserLogsForCase = onCall(async (request) => {
    const callerUid = request.auth && request.auth.uid;
    if (!callerUid) throw new HttpsError("unauthenticated", "Sign in first.");
    if ((await roleOf(callerUid)) !== "admin") {
        throw new HttpsError("permission-denied", "Admins only.");
    }
    const { uid, retain } = request.data || {};
    if (!uid || typeof uid !== "string") {
        throw new HttpsError("invalid-argument", "A target uid is required.");
    }
    const retainForCase = retain !== false;

    const writer = db.bulkWriter();
    let updated = 0;
    let last = null;
    for (let i = 0; i < 100; i++) {
        // Order by document id to avoid needing a composite index.
        let q = db.collection("security_logs")
            .where("uid", "==", uid)
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(400);
        if (last) q = q.startAfter(last);
        const page = await q.get();
        if (page.empty) break;
        page.docs.forEach((doc) => {
            writer.update(doc.ref, { retainForCase });
            updated++;
        });
        last = page.docs[page.docs.length - 1];
        if (page.size < 400) break;
    }
    await writer.close();
    return { ok: true, uid, retainForCase, updated };
});

