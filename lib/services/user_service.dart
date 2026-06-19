import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/models/app_user.dart';
import 'package:you_app/services/base/firestore_base.dart';

class UserService with FirestoreServiceMixin {

  // GET: Fetch a single user document data
  Future<Map<String, dynamic>?> get(String uid) async {
    final doc = await db.collection('users').doc(uid).get();
    return doc.data();
  }

  // STREAM: Listen to a single user document in real-time
  Stream<AppUser?> streamUser(String uid) {
    return db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return AppUser.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  // SET: Create a new user document (used during signup)
  Future<void> set(String uid, Map<String, dynamic> data) async {
    await db.collection('users').doc(uid).set(data);
  }

  // UPDATE: Generic user update
  Future<void> update(String uid, Map<String, dynamic> data) async {
    await db.collection('users').doc(uid).update(data);
  }

  // UPDATE: Specific update for last login (used during sign-in)
  Future<void> updateLastLogin(String uid) async {
    await db.collection('users').doc(uid).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserAvailability(String uid, String status) async {
    // Consider adding validation to ensure status is 'online' or 'offline'
    await db.collection('users').doc(uid).update({
      'availabilityStatus': status,
      'lastStatusChange':
          FieldValue.serverTimestamp(), // Optional: track when it changed
    });
  }

  // QUERY: Fetch all users (used by admin)
  Future<List<Map<String, dynamic>>> getAll() async {
    final querySnapshot = await db.collection('users').get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Cursor-paginated users for admin lists. Pass the previous page's [lastDoc]
  /// as [startAfter] to fetch the next page. Ordered by document id for a
  /// stable page set (user docs don't all have a `createdAt`).
  Future<({List<Map<String, dynamic>> items, DocumentSnapshot? lastDoc})>
      getUsersPage({DocumentSnapshot? startAfter, int limit = 30}) async {
    Query<Map<String, dynamic>> query =
        db.collection('users').orderBy(FieldPath.documentId).limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final snap = await query.get();
    return (
      items: snap.docs.map((doc) => doc.data()).toList(),
      lastDoc: snap.docs.isEmpty ? null : snap.docs.last,
    );
  }

  // QUERY: Check if username is available
  Future<bool> checkUsernameAvailability(String username) async {
    final query = await db
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  Future<List<AppUser>> getAvailableVolunteers() async {
    // Fetches users with the 'volunteer' role who are 'active'
    final snapshot = await db
        .collection('users')
        .where('role', isEqualTo: 'volunteer')
        .where('status', isEqualTo: 'active')
        .where('availabilityStatus', isEqualTo: 'online')
        .get();

    // You'll need an AppUser.fromJson method in your model
    return snapshot.docs.map((doc) => AppUser.fromJson(doc.data())).toList();
  }

  Stream<List<AppUser>> streamAvailableVolunteers() {
    return db
        .collection('users')
        .where('role', isEqualTo: 'volunteer')
        .where('status', isEqualTo: 'active')
        .where('availabilityStatus', isEqualTo: 'online')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AppUser.fromJson(doc.data())).toList());
  }
}
