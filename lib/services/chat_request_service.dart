import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/models/chat_request_model.dart';
import 'package:flutter/material.dart';

class ChatRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a new chat request document in Firestore and creates an In-App Notification document for the Volunteer.
  Future<void> sendChatRequest(ChatRequest request) async {
    final docRef = await _firestore.collection('chat_requests').add(request.toJson());
    
    // Create the In-App Notification document inside the Volunteer's notifications subcollection
    await _firestore
        .collection('users')
        .doc(request.volunteerId)
        .collection('notifications')
        .add({
      'title': 'New Chat Request 💬',
      'body': '${request.requesterName} wants to connect with you.',
      'type': 'request_received',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'data': {
        'requestId': docRef.id,
        'route': 'volunteer_dashboard',
      },
    });
  }

  /// Fetches chat requests for a specific volunteer.
  Stream<List<ChatRequest>> getChatRequestsForVolunteer(String volunteerId) {
    return _firestore
        .collection('chat_requests')
        .where('volunteerId', isEqualTo: volunteerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRequest.fromFirestore(doc))
            .toList());
  }

  Future<void> acceptRequest(ChatRequest request, String volunteerName, String? volunteerAvatarUrl) async {
    // Use a transaction for atomicity
    await _firestore.runTransaction((transaction) async {
      final requestRef = _firestore.collection('chat_requests').doc(request.id);

      // Create the chat ID
      final ids = [request.requesterId, request.volunteerId];
      ids.sort();
      final chatId = ids.join('_');
      final chatRef = _firestore.collection('chats').doc(chatId);

      // Volunteer details are now passed as arguments

      // 1. Update the request status
      transaction.update(requestRef, {'status': 'accepted'});

      // 2. Create the chat room document (or merge if it somehow exists)
      transaction.set(
          chatRef,
          {
            'participants': [request.requesterId, request.volunteerId],
            'participantInfo': {
              request.requesterId: {
                'name': request.requesterName,
                'avatarUrl': request.requesterAvatarUrl
              },
              request.volunteerId: {
                'name': volunteerName,
                'avatarUrl': volunteerAvatarUrl
              },
            },
            'createdAt':
                FieldValue.serverTimestamp(), // Timestamp for chat creation
            'lastMessage': null, // Initialize last message
          },
          SetOptions(merge: true));
    });

    // Create the In-App Notification document inside the User's notifications subcollection
    await _firestore
        .collection('users')
        .doc(request.requesterId)
        .collection('notifications')
        .add({
      'title': 'Chat Request Accepted! 🎉',
      'body': 'A volunteer has accepted your chat request. Let\'s talk!',
      'type': 'request_accepted',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'data': {
        'requestId': request.id,
        'route': 'chat_view',
      },
    });
  }

  Future<void> declineRequest(String requestId) async {
    await _firestore
        .collection('chat_requests')
        .doc(requestId)
        .update({'status': 'declined'});
    // Alternatively, you could delete the request:
    // await _firestore.collection('chat_requests').doc(requestId).delete();
  }

  /// Gets a real-time stream of ACCEPTED requests (active chats) FOR a volunteer.
  Stream<List<ChatRequest>> getVolunteerActiveChatsStream(String volunteerId) {
    return _firestore
        .collection('chat_requests')
        .where('volunteerId', isEqualTo: volunteerId)
        .where('status', isEqualTo: 'accepted') // Only accepted requests
        .orderBy('createdAt',
            descending: true) // Or order by last message time later
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRequest.fromFirestore(doc))
            .toList());
  }

  Stream<List<ChatRequest>> getVolunteerPendingChatsStream(String volunteerId) {
    return _firestore
        .collection('chat_requests')
        .where('volunteerId', isEqualTo: volunteerId)
        .where('status', isEqualTo: 'pending') // Only pending requests
        .orderBy('createdAt',
            descending: true) // Or order by last message time later
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRequest.fromFirestore(doc))
            .toList());
  }

  /// Checks if a pending or accepted request exists between a user and a volunteer.
  Future<bool> checkExistingRequest(String userId, String volunteerId) async {
    final query = await _firestore
        .collection('chat_requests')
        .where('requesterId', isEqualTo: userId)
        .where('volunteerId', isEqualTo: volunteerId)
        // Check for requests that are NOT declined or cancelled (i.e., pending or accepted)
        .where('status', whereIn: ['pending', 'accepted'])
        .limit(1)
        .get();

    return query.docs.isNotEmpty; // Returns true if a request exists
  }

  Stream<List<ChatRequest>> getUserSentRequestsStream(String userId) {
    return _firestore
        .collection('chat_requests')
        .where('requesterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRequest.fromFirestore(doc))
            .toList());
  }

  Future<void> cancelRequest(String requestId) async {
    // You might want stricter rules to ensure only pending requests can be cancelled.
    await _firestore.collection('chat_requests').doc(requestId).delete();
  }

  /// Updates the status of a chat request (e.g., from 'pending' to 'accepted').
  Future<void> updateChatRequestStatus(
      String requestId, String newStatus) async {
    await _firestore
        .collection('chat_requests')
        .doc(requestId)
        .update({'status': newStatus});
  }
}
