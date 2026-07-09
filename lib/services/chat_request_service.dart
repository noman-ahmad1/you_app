import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/models/chat_request_model.dart';
import 'package:you_app/services/analytics_service.dart';

/// Outcome of requesting a volunteer chat. When [capReached] is true the free
/// user has exhausted their welcome chats and should be shown the paywall.
class ChatRequestResult {
  final bool capReached;
  const ChatRequestResult({required this.capReached});
}

class ChatRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  AnalyticsService get _analytics => locator<AnalyticsService>();

  /// Requests a chat with a volunteer via the `requestVolunteerChat` callable.
  /// The function atomically enforces the free-tier welcome-chat cap and creates
  /// the request + volunteer notification server-side (direct client writes to
  /// chat_requests are denied by security rules), which closes the concurrent-
  /// request bypass a client-side counter would leave open.
  Future<ChatRequestResult> sendChatRequest(ChatRequest request) async {
    final result = await _functions.httpsCallable('requestVolunteerChat').call({
      'volunteerId': request.volunteerId,
      'requesterName': request.requesterName,
      'requesterAvatarUrl': request.requesterAvatarUrl,
      'topic': request.topic,
    });

    final data = Map<String, dynamic>.from(result.data as Map);
    if (data['capReached'] == true) {
      return const ChatRequestResult(capReached: true);
    }

    _analytics.logChatRequestSent();
    return const ChatRequestResult(capReached: false);
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

      // 1. Update the request status. `acceptedAt` anchors the 24-hour
      // auto-expiry window; `volunteerName` lets the requester's review dialog
      // name the volunteer without an extra lookup. `userReviewed` starts false.
      transaction.update(requestRef, {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'volunteerName': volunteerName,
        'userReviewed': false,
      });

      // 2. Create the chat room document (or merge if it somehow exists).
      // `createdAt` doubles as the acceptance time (chat is created on accept),
      // which the server-side expiry function uses to find stale chats.
      // `requestId` lets that function complete the matching request directly.
      transaction.set(
          chatRef,
          {
            'status': 'active',
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
            'requestId': request.id,
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

    _analytics.logChatRequestAccepted();
  }

  Future<void> declineRequest(String requestId) async {
    await _firestore
        .collection('chat_requests')
        .doc(requestId)
        .update({'status': 'declined'});
    _analytics.logChatRequestDeclined();
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

  /// Marks that the requester has resolved (submitted or skipped) the post-chat
  /// review for this request, so it is no longer surfaced as a review prompt.
  Future<void> markRequestReviewed(String requestId) async {
    await _firestore
        .collection('chat_requests')
        .doc(requestId)
        .set({'userReviewed': true}, SetOptions(merge: true));
  }
}
