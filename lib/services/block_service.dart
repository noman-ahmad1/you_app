import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/services/base/app_log.dart';
import 'package:you_app/services/base/firestore_base.dart';

/// Reads admin-created `volunteer_blocks` so the app can hide a volunteer from a
/// specific user for a limited period. Blocks are CREATED by the admin panel;
/// the app only enforces them. Fail-soft (never blocks the UI on error).
///
/// Doc id convention: `{userId}_{volunteerId}`. Fields: userId, volunteerId,
/// createdAt, expiresAt (Timestamp), reason?, createdBy.
class BlockService with FirestoreServiceMixin {
  /// Volunteer uids the [userId] is currently (non-expired) blocked from.
  Future<Set<String>> activeBlockedVolunteerIds(String userId) async {
    try {
      final snap = await db
          .collection('volunteer_blocks')
          .where('userId', isEqualTo: userId)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .get();
      return snap.docs
          .map((d) => d.data()['volunteerId'] as String?)
          .whereType<String>()
          .toSet();
    } catch (e) {
      AppLog.error('BlockService.activeBlockedVolunteerIds', e);
      return <String>{};
    }
  }

  /// Whether [userId] is currently blocked from [volunteerId].
  Future<bool> isBlocked(String userId, String volunteerId) async {
    try {
      final doc = await db
          .collection('volunteer_blocks')
          .doc('${userId}_$volunteerId')
          .get();
      final expiresAt = doc.data()?['expiresAt'];
      return expiresAt is Timestamp && expiresAt.toDate().isAfter(DateTime.now());
    } catch (e) {
      AppLog.error('BlockService.isBlocked', e);
      return false;
    }
  }
}
