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

  /// The volunteer's availability toggle — the ONE thing that decides whether
  /// they appear in discovery. Once on, it stays on until they switch it off.
  ///
  /// Going online also stamps `lastSeen` so the liveness trail starts right away
  /// (see PresenceService); nothing reads it for discovery today, but it's what
  /// staleness expiry will use when it's eventually switched on.
  ///
  /// NOTE: this is presence — NOT the account status. It must NOT write
  /// `lastStatusChange`: the admin panel uses that key as the audit trail for
  /// suspensions/bans, and a volunteer toggling availability would clobber it
  /// (it's also owner-denied by security rules).
  Future<void> updateUserAvailability(String uid, String status) async {
    await db.collection('users').doc(uid).update({
      'availabilityStatus': status,
      if (status == 'online') 'lastSeen': FieldValue.serverTimestamp(),
      'lastAvailabilityChange': FieldValue.serverTimestamp(),
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
    final snapshot = await db
        .collection('users')
        .where('role', isEqualTo: 'volunteer')
        .where('status', isEqualTo: 'active')
        .where('availabilityStatus', isEqualTo: 'online')
        .get();

    return snapshot.docs.map((doc) => AppUser.fromJson(doc.data())).toList();
  }

  /// The volunteers a user can reach.
  ///
  /// Queries the volunteer's own toggle and NOTHING else: a volunteer stays
  /// listed until they explicitly switch themselves off. This is deliberate.
  /// With a small volunteer pool, auto-expiring anyone who hasn't opened the app
  /// recently would empty this list — and a user who opens the app to find NO
  /// listeners at all has no path to help, which is far worse than reaching a
  /// listener who takes a while to reply.
  ///
  /// The liveness machinery still runs quietly underneath (`lastSeen` is beaten
  /// by PresenceService), so when the pool is big enough to afford being strict,
  /// staleness expiry can be switched on from the admin panel —
  /// `app_settings/global_config.presence_expiry_enabled` — with no app release.
  /// See `sweepStalePresence` in functions/index.js.
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
