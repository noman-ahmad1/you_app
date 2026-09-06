import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/base/app_log.dart';
import 'package:you_app/services/base/firestore_base.dart';
import 'package:you_app/services/security_log_service.dart';

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
      await _markChatEscalated(chatId);
      // Safety trail (fire-and-forget; server captures the IP).
      locator<SecurityLogService>().log(SecurityAction.reportFiled);
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
      if (chatId != null) await _markChatEscalated(chatId);
      // Safety trail (fire-and-forget; server captures the IP).
      locator<SecurityLogService>().log(SecurityAction.reportFiled);
    } catch (e) {
      AppLog.error('EscalationService.escalateModeration', e);
    }
  }

  /// Mirrors "this chat was escalated" onto the chat doc itself.
  ///
  /// `escalations` is **admin-read-only**, so a participant cannot query it —
  /// but they CAN read their own chat. This flag is what [hasUnresolvedEscalation]
  /// checks. The admin panel clears it (`escalated: false`) when it resolves the
  /// escalation. Best-effort: a failure here must never break the crisis flow.
  Future<void> _markChatEscalated(String chatId) async {
    try {
      await db.collection('chats').doc(chatId).set({
        'escalated': true,
        'escalatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      AppLog.error('EscalationService._markChatEscalated', e);
    }
  }

  /// True if [chatId] has an escalation a supervisor hasn't resolved yet, so the
  /// chat (and its transcript) must be preserved as evidence.
  ///
  /// Reads the `escalated` flag on the chat doc rather than querying
  /// `escalations` — that collection is admin-read-only, so the query was always
  /// permission-denied and this guard silently never fired.
  ///
  /// Advisory only: it stops the in-app "delete chat" button, not a determined
  /// client. Server-side retention is the real guarantee.
  Future<bool> hasUnresolvedEscalation(String chatId) async {
    try {
      final snap = await db.collection('chats').doc(chatId).get();
      return snap.data()?['escalated'] == true;
    } catch (e) {
      AppLog.error('EscalationService.hasUnresolvedEscalation', e);
      return false; // fail-open: don't block deletion on a transient read error
    }
  }
}
