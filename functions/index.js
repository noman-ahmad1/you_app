// Import the v2 trigger for Firestore
const { onDocumentDeleted, onDocumentCreated } = require("firebase-functions/v2/firestore");

// Import the Firebase Admin SDK
const admin = require("firebase-admin");

// Import the logger
const logger = require("firebase-functions/logger");

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