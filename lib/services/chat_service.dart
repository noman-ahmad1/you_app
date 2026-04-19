import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/models/app_user.dart';
import 'package:you_app/models/chat_messaage_model.dart';
import 'package:flutter/material.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> deleteChatAndRequest({
    required String chatId,
    required String requestId, // The ID of the document in 'chat_requests'
  }) async {
    // Use a batch write for atomicity (both deletions succeed or fail together)
    final batch = _firestore.batch();

    // 1. Get reference to the chat room document
    final chatRef = _firestore.collection('chats').doc(chatId);

    // 2. Get reference to the chat request document
    final requestRef = _firestore.collection('chat_requests').doc(requestId);

    // 3. Add delete operations to the batch
    batch.delete(chatRef);
    batch.delete(requestRef);

    // 4. Commit the batch
    try {
      await batch.commit();
      debugPrint("Chat ($chatId) and Request ($requestId) deleted successfully.");
    } catch (e) {
      debugPrint("Error deleting chat and request: $e");
      // Rethrow to allow the ViewModel to handle the error
      rethrow;
    }
  }

  Future<void> createChatRoomIfNotExists({
    required String chatId,
    required AppUser user,
    required AppUser volunteer,
  }) async {
    final docRef = _firestore.collection('chats').doc(chatId);

    final chatRoomData = {
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
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromJson(doc.data()))
            .toList());
  }

  // Sends a new message
  Future<void> sendMessage(String chatId, ChatMessage message) async {
    // Add message to subcollection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toJson());

    // Also update the 'lastMessage' on the parent chat document
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': {
        'text': message.text,
        'senderId': message.senderId,
        'timestamp': message.timestamp,
      }
    });
  }
}
