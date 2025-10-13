import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  FirestoreService() {
    // Initialize managers when the main service is constructed
    user = _UserDbManager(_firestore);
    volunteer_info = _VolunteerDbManager(_firestore);
    mood = _MoodDbManager(_firestore, _auth);
    journal = _JournalDbManager(_firestore, _auth);
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
