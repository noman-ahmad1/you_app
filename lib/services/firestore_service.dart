import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:you_app/models/app_user.dart';
import 'package:you_app/models/chat_messaage_model.dart';
import 'package:you_app/models/chat_request_model.dart';
import 'package:you_app/models/journal_model.dart';
import 'package:you_app/models/mood_model.dart';
import 'package:you_app/models/volunteer_info_model.dart';

// --- Private / Internal Data Manager Classes ---

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // NOTE: In a real Flutter/Canvas app, the 'appId' (aka __app_id) must be
  // securely provided through configuration or environment variables.
  // This is a placeholder for demonstration.
  final String _appId = 'canvas_app_id_placeholder';
  String get userId => _auth.currentUser?.uid ?? 'anonymous_user';

  // Initialize the specific managers
  late final _UserDbManager user;
  late final _VolunteerDbManager volunteer_info;
  late final _MoodDbManager mood;
  late final _JournalDbManager journal;
  late final _ChatDbManager chat;
  late final _ChatRequestDbManager chatRequest;

  FirestoreService() {
    // Initialize managers when the main service is constructed
    user = _UserDbManager(_firestore);
    volunteer_info = _VolunteerDbManager(_firestore);
    mood = _MoodDbManager(_firestore, _auth);
    journal = _JournalDbManager(_firestore, _auth);
    chat = _ChatDbManager(_firestore);
    chatRequest = _ChatRequestDbManager(_firestore);
  }
}

// 1. Manages the core AppUser document in the 'users' collection
class _UserDbManager {
  final FirebaseFirestore _firestore;

  _UserDbManager(this._firestore);

  // GET: Fetch a single user document data
  Future<Map<String, dynamic>?> get(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  // SET: Create a new user document (used during signup)
  Future<void> set(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set(data);
  }

  // UPDATE: Generic user update
  Future<void> update(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // UPDATE: Specific update for last login (used during sign-in)
  Future<void> updateLastLogin(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserAvailability(String uid, String status) async {
    // Consider adding validation to ensure status is 'online' or 'offline'
    await _firestore.collection('users').doc(uid).update({
      'availabilityStatus': status,
      'lastStatusChange':
          FieldValue.serverTimestamp(), // Optional: track when it changed
    });
  }

  // QUERY: Fetch all users (used by admin)
  Future<List<Map<String, dynamic>>> getAll() async {
    final querySnapshot = await _firestore.collection('users').get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  // QUERY: Check if username is available
  Future<bool> checkUsernameAvailability(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  Future<List<AppUser>> getAvailableVolunteers() async {
    // Fetches users with the 'volunteer' role who are 'active'
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'volunteer')
        .where('status', isEqualTo: 'active')
        .where('availabilityStatus', isEqualTo: 'online')
        .get();

    // You'll need an AppUser.fromJson method in your model
    return snapshot.docs.map((doc) => AppUser.fromJson(doc.data())).toList();
  }
}

// 2. Manages the volunteer-specific document in the 'volunteer_info' collection
class _VolunteerDbManager {
  final FirebaseFirestore _firestore;

  _VolunteerDbManager(this._firestore);

  Future<VolunteerInfo?> get(String uid) async {
    final doc = await _firestore.collection('volunteer_info').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;

    // Convert the Firestore Map to the VolunteerInfo model
    // Assuming VolunteerInfo.fromJson is correctly implemented
    return VolunteerInfo.fromJson(doc.data()!);
  }

  // SET/CREATE: Save or overwrite the volunteer info document
  Future<void> saveInfo(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('volunteer_info').doc(uid).set(data);
  }

  // UPDATE: Generic update for the volunteer info document
  Future<void> update(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('volunteer_info').doc(uid).update(data);
  }
}

// 3. Manages mood entries in the public/global collection
class _MoodDbManager {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Uses the public path structure with the provided appId
  _MoodDbManager(this._firestore, this._auth);

  // Method to add a new mood entry
  Future<void> saveMoodEntry(MoodEntry entry) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint('Save Error: No authenticated user.');
      return;
    }

    try {
      final data = {
        'userId': userId,
        'moodLabel': entry.moodLabel,
        'timestamp': FieldValue.serverTimestamp(),
        'extraField': entry.extraField,
      };

      await _firestore.collection('mood').add(data);
      debugPrint('✅ Mood entry saved for $userId - ${entry.moodLabel}');
    } on FirebaseException catch (e) {
      debugPrint('🔥 Firebase Save Error: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('💥 General Save Error: $e');
    }
  }

  // Stream entries for the current user (filtered by userId)
  // We use Map<String, dynamic> as a generic return type since we don't have MoodModel definition.
  Stream<List<MoodEntry>> getUserMoodStream(String userId) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    return _firestore
        .collection('mood')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: thirtyDaysAgo)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MoodEntry.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Admin View: Fetch all mood entries (no user filter)
  Future<List<MoodEntry>> getAllMoodEntriesForAdmin() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint('⚠️ No authenticated user.');
      return [];
    }

    // Optional: verify if user is admin
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final isAdmin = userDoc.data()?['role'] == 'admin';
    if (!isAdmin) {
      debugPrint('🚫 Access denied. User is not an admin.');
      return [];
    }

    try {
      final querySnapshot = await _firestore
          .collection('mood')
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MoodEntry.fromFirestore(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      debugPrint('🔥 Firebase Fetch Error: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      debugPrint('💥 General Fetch Error: $e');
      return [];
    }
  }

  // FirebaseAuth getFirebaseAuthInstance() {
  //   return FirebaseAuth.instance;
  // }
}

// --- Journal Methods ---
class _JournalDbManager {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Uses the public path structure with the provided appId
  _JournalDbManager(this._firestore, this._auth);

  /// Adds a new journal entry to a subcollection for the current user.
  Future<void> addJournalEntry(JournalEntry entry) async {
    try {
      // Storing entries in a subcollection is a secure and scalable pattern.
      final journalCollection = _firestore
          .collection('users')
          .doc(entry.userId)
          .collection('journal')
          .withConverter<JournalEntry>(
            fromFirestore: JournalEntry.fromFirestore,
            toFirestore: (journalEntry, _) => journalEntry.toFirestore(),
          );

      await journalCollection.add(entry);
    } catch (e) {
      // In a real app, log this error to a service like Sentry or Firebase Crashlytics
      print('Error adding journal entry: $e');
      // Rethrow the exception so the ViewModel can catch it and show a dialog
      rethrow;
    }
  }

  Stream<List<JournalEntry>> getJournalEntriesStream({required String userId}) {
    final journalCollection = _firestore
        .collection('users')
        .doc(userId)
        .collection('journal') // The name you chose in your rules
        .orderBy('timestamp', descending: true) // Sorts with latest on top
        .withConverter<JournalEntry>(
          fromFirestore: JournalEntry.fromFirestore,
          toFirestore: (entry, _) => entry.toFirestore(),
        );

    // .snapshots() returns a Stream. The .map() converts the raw snapshot
    // into a clean List<JournalEntry>.
    return journalCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> updateJournalEntry({
    required String userId,
    required String entryId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('journal')
          .doc(entryId)
          .update(data);
    } catch (e) {
      debugPrint("Error updating journal entry: $e");
      rethrow;
    }
  }

  Future<void> deleteJournalEntry({
    required String userId,
    required String entryId,
  }) async {
    try {
      // Construct the exact path to the document to be deleted.
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('journal') // Ensure this matches your collection name
          .doc(entryId)
          .delete();
    } catch (e) {
      // Log the error for debugging purposes.
      debugPrint("Error deleting journal entry: $e");
      // Rethrow the exception so the ViewModel can catch it and show an error dialog to the user.
      rethrow;
    }
  }
}

// --- Chat Methods  ---
class _ChatDbManager {
  final FirebaseFirestore _firestore;
  _ChatDbManager(this._firestore);

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
      print("Chat ($chatId) and Request ($requestId) deleted successfully.");
    } catch (e) {
      print("Error deleting chat and request: $e");
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

// --- Chat Request Methods ---
class _ChatRequestDbManager {
  final FirebaseFirestore _firestore;
  _ChatRequestDbManager(this._firestore);

  /// Creates a new chat request document in Firestore.
  Future<void> sendChatRequest(ChatRequest request) async {
    await _firestore.collection('chat_requests').add(request.toJson());
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

  Future<void> acceptRequest(ChatRequest request) async {
    // Use a transaction for atomicity
    await _firestore.runTransaction((transaction) async {
      final requestRef = _firestore.collection('chat_requests').doc(request.id);

      // Create the chat ID
      final ids = [request.requesterId, request.volunteerId];
      ids.sort();
      final chatId = ids.join('_');
      final chatRef = _firestore.collection('chats').doc(chatId);

      // Fetch volunteer details (replace with actual fetch if needed)
      final volunteerName = "Volunteer"; // TODO: Get volunteer name
      final volunteerAvatar = null; // TODO: Get volunteer avatar

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
                'avatarUrl': volunteerAvatar
              },
            },
            'createdAt':
                FieldValue.serverTimestamp(), // Timestamp for chat creation
            'lastMessage': null, // Initialize last message
          },
          SetOptions(merge: true));
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

  /// Fetches chat requests for a specific volunteer.