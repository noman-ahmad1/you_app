import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/models/app_notification.dart';
import 'package:you_app/services/base/firestore_base.dart';

/// Reads and updates a user's in-app notifications (`users/{uid}/notifications`).
///
/// Push delivery is PushNotificationService's job; this owns the inbox. It
/// replaces four copies of the same Firestore code that used to live in both
/// home view models and both notification drawers.
class InAppNotificationService with FirestoreServiceMixin {
  CollectionReference<Map<String, dynamic>> _inbox(String uid) =>
      db.collection('users').doc(uid).collection('notifications');

  static AppNotification _fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final map = d.data() ?? const <String, dynamic>{};
    final ts = map['createdAt'];
    return AppNotification.fromMap(
        d.id, map, ts is Timestamp ? ts.toDate() : null);
  }

  /// The whole inbox, newest first.
  Stream<List<AppNotification>> streamAll(String uid) {
    return _inbox(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  /// The unread count, plus whatever arrived since the last emission (for the
  /// sliding banner). Each listener gets its own "first emission" state.
  Stream<UnreadNotifications> streamUnread(String uid) async* {
    var first = true;
    await for (final snap
        in _inbox(uid).where('isRead', isEqualTo: false).snapshots()) {
      final added = first
          ? const <AppNotification>[]
          : snap.docChanges
              .where((c) => c.type == DocumentChangeType.added)
              .map((c) => _fromDoc(c.doc))
              .toList();
      first = false;
      yield UnreadNotifications(count: snap.docs.length, added: added);
    }
  }

  /// Marks every unread notification as read.
  Future<void> markAllRead(String uid) async {
    final query = await _inbox(uid).where('isRead', isEqualTo: false).get();
    if (query.docs.isEmpty) return;
    for (final group in FirestoreServiceMixin.chunk(query.docs, 500)) {
      final batch = db.batch();
      for (final doc in group) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    }
  }
}
