// Import the v2 trigger for Firestore
const { onDocumentDeleted } = require("firebase-functions/v2/firestore");

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

    //
    // ▼▼▼ THIS IS THE MOST IMPORTANT LINE ▼▼▼
    //
    // This line targets ONLY the 'messages' subcollection
    // INSIDE the single document that was deleted.
    const collectionRef = db.collection("chats")
        .doc(chatId)
        .collection("messages");
    //
    // ▲▲▲ THIS IS THE MOST IMPORTANT LINE ▲▲▲
    //

    // This command will now ONLY delete the messages, not the whole collection.
    try {
        await db.recursiveDelete(collectionRef);
        logger.log(`Successfully cleaned up chatroom: ${chatId}`);
    } catch (error) {
        logger.error(`Error cleaning up chats ${chatId}:`, error);
    }
});