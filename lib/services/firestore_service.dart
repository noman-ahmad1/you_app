import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/models/mood_model.dart';
import 'package:you_app/models/volunteer_info_model.dart';

// --- Private / Internal Data Manager Classes ---

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize the specific managers
  late final _UserDbManager user;
  late final _VolunteerDbManager volunteer_info;
  late final _MoodDbManager mood;

  FirestoreService() {
    // Initialize managers when the main service is constructed
    user = _UserDbManager(_firestore);
    volunteer_info = _VolunteerDbManager(_firestore);
    mood = _MoodDbManager(_firestore);
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

class _MoodDbManager {
  final FirebaseFirestore _firestore;

  _MoodDbManager(this._firestore);

  // Base path for mood entries: /artifacts/{appId}/users/{userId}/mood
  String _collectionPath({required String appId, required String userId}) {
    return 'artifacts/$appId/users/$userId/mood';
  }

  // CREATE: Save a new mood entry
  Future<void> addMoodEntry({
    required String appId,
    required String userId,
    required MoodEntry entry,
  }) async {
    final path = _collectionPath(appId: appId, userId: userId);
    // Use .add() for a new, auto-generated document ID
    await _firestore.collection(path).add(entry.toJson());
  }

  // READ: Get all mood entries for chart generation
  // Returns a list of raw documents (Map<String, dynamic>) for ViewModel to aggregate
  Future<List<Map<String, dynamic>>> getMoodEntries({
    required String appId,
    required String userId,
  }) async {
    final path = _collectionPath(appId: appId, userId: userId);
    final snapshot = await _firestore.collection(path).get();

    // Map the documents to a simple list of data maps
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
