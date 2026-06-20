import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/services/base/app_log.dart';
import 'package:you_app/services/base/firestore_base.dart';
import 'package:you_app/services/moderation_service.dart';

/// Writes `moderation_flags` records for content the client BLOCKED before it
/// was ever delivered (so no Cloud Function trigger sees it). Delivered content
/// is flagged authoritatively by the Cloud Functions instead. Best-effort —
/// never throws into a user flow.
class ModerationFlagService with FirestoreServiceMixin {
  Future<void> recordBlocked({
    required ModerationContext context,
    required String senderId,
    required String text,
    required ModerationResult result,
    String? recipientId,
    String? chatId,
    String? communityId,
  }) async {
    try {
      await db.collection('moderation_flags').add({
        'source': context == ModerationContext.chat ? 'chat' : 'post',
        'senderId': senderId,
        if (recipientId != null) 'recipientId': recipientId,
        if (chatId != null) 'chatId': chatId,
        if (communityId != null) 'communityId': communityId,
        'text': text,
        'categories': result.categoryNames,
        'severity': result.severity,
        'action': 'blocked',
        'delivered': false,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLog.error('ModerationFlagService.recordBlocked', e);
    }
  }
}
