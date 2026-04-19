import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/models/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
