import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/models/app_user.dart';
import 'package:you_app/models/chat_messaage_model.dart';
import 'package:flutter/material.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/base/app_log.dart';
import 'package:you_app/services/base/firestore_base.dart';

class ChatService with FirestoreServiceMixin {
  AnalyticsService get _analytics => locator<AnalyticsService>();


  Future<void> deleteChatAndRequest({
    required String chatId,
    required String requestId, // The ID of the document in 'chat_requests'
  }) async {
    // Use a batch write for atomicity (both deletions succeed or fail together)
    final batch = db.batch();

    // 1. Get reference to the chat room document
    final chatRef = db.collection('chats').doc(chatId);

    // 2. Get reference to the chat request document
    var requestRef = db.collection('chat_requests').doc(requestId);

    // Defensive check: If the requestId is a placeholder or doesn't exist,
    // look up the real request document using the participants' IDs.
    try {
      final docSnapshot = await requestRef.get();
      if (!docSnapshot.exists) {
        final parts = chatId.split('_');
        if (parts.length == 2) {
          final query = await db
              .collection('chat_requests')
              .where('requesterId', whereIn: parts)
              .where('volunteerId', whereIn: parts)
              .limit(1)
              .get();
          if (query.docs.isNotEmpty) {
            requestRef = query.docs.first.reference;
            debugPrint("Defensively resolved real request ID: ${requestRef.id}");
          }
        }
      }
    } catch (e) {
      debugPrint("Could not fetch document directly (possibly permission denied due to wrong ID). Performing defensive fallback query: $e");
      final parts = chatId.split('_');
      if (parts.length == 2) {
        try {
          final query = await db
              .collection('chat_requests')
              .where('requesterId', whereIn: parts)
              .where('volunteerId', whereIn: parts)
              .limit(1)
              .get();
          if (query.docs.isNotEmpty) {
            requestRef = query.docs.first.reference;
            debugPrint("Defensively resolved real request ID on error: ${requestRef.id}");
          }
        } catch (queryErr) {
          debugPrint("Failed to perform defensive fallback query: $queryErr");
        }
      }
    }

    // 3. Fetch all messages in the subcollection to delete them
    final messagesSnapshot = await chatRef.collection('messages').get();
    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 4. Add delete operations for the main documents to the batch
    batch.delete(chatRef);
    batch.delete(requestRef);

    // 5. Commit the batch
    try {
      await batch.commit();
      debugPrint(
          "Chat ($chatId) and Request (${requestRef.id}) deleted successfully.");
    } catch (e) {
      debugPrint("Error deleting chat and request: $e");
      // Rethrow to allow the ViewModel to handle the error
      rethrow;
    }
  }

  /// Ends a chat instead of deleting it. Marks both the chat and the request as 'completed'.
  Future<void> endChatAndRequest({
    required String chatId,
    required String requestId,
  }) async {
    final batch = db.batch();
    final chatRef = db.collection('chats').doc(chatId);
    var requestRef = db.collection('chat_requests').doc(requestId);

    // Defensive check to ensure we have the correct request document
    try {
      final docSnapshot = await requestRef.get();
      if (!docSnapshot.exists) {
        final parts = chatId.split('_');
        if (parts.length == 2) {
          final query = await db
              .collection('chat_requests')
              .where('requesterId', whereIn: parts)
              .where('volunteerId', whereIn: parts)
              .limit(1)
              .get();
          if (query.docs.isNotEmpty) {
            requestRef = query.docs.first.reference;
          }
        }
      }
    } catch (e) {
      final parts = chatId.split('_');
      if (parts.length == 2) {
        try {
          final query = await db
              .collection('chat_requests')
              .where('requesterId', whereIn: parts)
              .where('volunteerId', whereIn: parts)
              .limit(1)
              .get();
          if (query.docs.isNotEmpty) {
            requestRef = query.docs.first.reference;
          }
        } catch (_) {}
      }
    }

    // Mark as completed
    batch.update(chatRef, {'status': 'completed'});
    batch.update(requestRef, {'status': 'completed'});

    await batch.commit();
    _analytics.logChatEnded();
  }

  Future<void> createChatRoomIfNotExists({
    required String chatId,
    required AppUser user,
    required AppUser volunteer,
  }) async {
    final docRef = db.collection('chats').doc(chatId);

    final chatRoomData = {
      'status': 'active',
      'participants': [user.uid, volunteer.uid],
      'participantInfo': {
        user.uid: {'name': user.fullName, 'avatarUrl': user.profilePictureUrl},
        volunteer.uid: {
          'name': volunteer.fullName,
          'avatarUrl': volunteer.profilePictureUrl
        },
      },
      'createdAt': FieldValue.serverTimestamp(),
    };

    // .set with merge:true will create the doc or merge data if it exists.
    await docRef.set(chatRoomData, SetOptions(merge: true));
  }

  // Gets a real-time stream of messages for a specific chat room
  Stream<List<ChatMessage>> getChatMessagesStream(String chatId) {
    return db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromJson(doc.data()))
            .toList());
  }

  /// Sets whether a user is currently active in a chat room.
  Future<void> setChatPresence(String chatId, String userId, bool isActive) async {
    await db.collection('chats').doc(chatId).set({
      'participantsActivity': {
        userId: isActive,
      }
    }, SetOptions(merge: true));
  }

  // Sends a new message
  Future<void> sendMessage(String chatId, ChatMessage message) async {
    final chatRef = db.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    // Atomically add the message and update the parent's lastMessage in a
    // single commit (was two sequential round-trips).
    final batch = db.batch();
    batch.set(messageRef, message.toJson());
    batch.update(chatRef, {
      'lastMessage': {
        'text': message.text,
        'senderId': message.senderId,
        'timestamp': message.timestamp,
      }
    });
    await batch.commit();
    _analytics.logChatMessageSent();

    // Notify the recipient off the critical path so a notification failure
    // (or the presence-check read) never blocks or fails the message send.
    unawaited(_notifyRecipientOfMessage(chatId, message));
  }

  /// Creates an in-app notification for the message recipient, unless they are
  /// currently active in the chat. Best-effort: errors are logged, not thrown.
  Future<void> _notifyRecipientOfMessage(String chatId, ChatMessage message) async {
    try {
      final parts = chatId.split('_');
      final recipientId =
          parts.firstWhere((id) => id != message.senderId, orElse: () => '');
      if (recipientId.isEmpty) return;

      // Check if recipient is currently active in the chat
      final chatDoc = await db.collection('chats').doc(chatId).get();
      final data = chatDoc.data();
      final participantsActivity =
          data?['participantsActivity'] as Map<String, dynamic>? ?? {};
      final isRecipientActive = participantsActivity[recipientId] == true;

      // Skip sending notification if recipient is active in the chat
      if (isRecipientActive) return;

      await db
          .collection('users')
          .doc(recipientId)
          .collection('notifications')
          .add({
        'title': 'New Message 💬',
        'body': message.text,
        'type': 'new_message',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'chatId': chatId,
          'route': 'chat_view',
        },
      });
    } catch (e) {
      AppLog.error('ChatService._notifyRecipientOfMessage', e);
    }
  }

  /// Deletes all chats and chat requests where the given user is a participant.
  Future<void> deleteAllUserChats(String userId) async {
    final batch = db.batch();

    // 1. Delete all chat requests where the user is either the requester or volunteer
    try {
      final requesterQuery = await db
          .collection('chat_requests')
          .where('requesterId', isEqualTo: userId)
          .get();
      for (var doc in requesterQuery.docs) {
        batch.delete(doc.reference);
      }

      final volunteerQuery = await db
          .collection('chat_requests')
          .where('volunteerId', isEqualTo: userId)
          .get();
      for (var doc in volunteerQuery.docs) {
        batch.delete(doc.reference);
      }
    } catch (e) {
      debugPrint("Error querying chat requests for deletion: $e");
    }

    // 2. Delete all chats where the user is in the participants array
    try {
      final chatsQuery = await db
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      for (var doc in chatsQuery.docs) {
        // Also need to delete messages subcollection for each chat
        final messagesQuery = await doc.reference.collection('messages').get();
        for (var msgDoc in messagesQuery.docs) {
          batch.delete(msgDoc.reference);
        }
        batch.delete(doc.reference);
      }
    } catch (e) {
      debugPrint("Error querying chats for deletion: $e");
    }

    try {
      await batch.commit();
      debugPrint("Successfully deleted all chats and requests for user $userId");
    } catch (e) {
      debugPrint("Error committing batch delete for user chats: $e");
      rethrow;
    }
  }
}
