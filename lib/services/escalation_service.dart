import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/services/base/app_log.dart';
import 'package:you_app/services/base/firestore_base.dart';

/// Writes `escalations` documents that the supervisor web dashboard listens to
/// in real time (status == "open"). Two triggers:
///   • a volunteer taps "Emergency Escalate" in a chat → [escalateChat]
///   • a severe (violence) moderation block fires        → [escalateModeration]
///
/// Best-effort by design — escalation must never throw into a crisis flow.
/// The web side owns the lifecycle (open → acknowledged → resolved) and the
/// linked incident report, so the app only ever creates `status:'open'` docs.
class EscalationService with FirestoreServiceMixin {
  /// Raised when a volunteer escalates a live chat to a supervisor.
  Future<void> escalateChat({
    required String chatId,
    required String userId,
    required String userName,
    required String volunteerId,
    required String volunteerName,
    String? reason,
    String severity = 'critical',
  }) async {
    try {
      await db.collection('escalations').add({
        'type': 'volunteer',
        'chatId': chatId,
        'userId': userId,
        'userName': userName,
        'volunteerId': volunteerId,
        'volunteerName': volunteerName,
        'reason': reason,
        'severity': severity,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLog.error('EscalationService.escalateChat', e);
      rethrow; // the volunteer flow shows a failure dialog and can retry
    }
  }

  /// Raised automatically when a severe moderation block fires. [chatId] is
  /// included only when the blocked content was in a chat.
  Future<void> escalateModeration({
    required String userId,
    required String userName,
    String? chatId,
    required String reason,
    String severity = 'high',
  }) async {
    try {
      await db.collection('escalations').add({
        'type': 'moderation',
        if (chatId != null) 'chatId': chatId,
        'userId': userId,
        'userName': userName,
        'reason': reason,
        'severity': severity,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLog.error('EscalationService.escalateModeration', e);
    }
  }

  /// True if [chatId] has an escalation a supervisor hasn't resolved yet, so the
  /// chat (and its transcript) must be preserved as evidence.
  Future<bool> hasUnresolvedEscalation(String chatId) async {
    try {
      final snap = await db
          .collection('escalations')
          .where('chatId', isEqualTo: chatId)
          .get();
      return snap.docs.any((d) => (d.data()['status'] as String?) != 'resolved');
    } catch (e) {
      AppLog.error('EscalationService.hasUnresolvedEscalation', e);
      return false; // fail-open: don't block deletion on a transient read error
    }
  }
}
