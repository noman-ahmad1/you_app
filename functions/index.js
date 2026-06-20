// Import the v2 trigger for Firestore
const { onDocumentDeleted, onDocumentCreated } = require("firebase-functions/v2/firestore");

// Import the v2 scheduler + https triggers (for daily analytics aggregation)
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest } = require("firebase-functions/v2/https");

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

// Shared secret guarding the manual trigger. Override in production via the
// ANALYTICS_SEED_SECRET environment variable / functions config.
const SEED_SECRET = process.env.ANALYTICS_SEED_SECRET || "CHANGE_ME_SEED_SECRET";

/**
 * Manual trigger that recomputes TODAY's (Asia/Karachi) doc immediately. Used
 * once right after deploy to seed the dashboard so its trend isn't empty until
 * the scheduler first runs. Guarded by a shared-secret token.
 * Usage: GET /runDailyAnalyticsNow?token=<secret>
 */
exports.runDailyAnalyticsNow = onRequest(async (req, res) => {
    if (!SEED_SECRET || req.query.token !== SEED_SECRET) {
        res.status(403).json({ error: "Forbidden" });
        return;
    }
    try {
        const written = await aggregateForDay(new Date());
        res.status(200).json({ ok: true, written });
    } catch (error) {
        logger.error("runDailyAnalyticsNow failed:", error);
        res.status(500).json({ ok: false, error: String(error) });
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

