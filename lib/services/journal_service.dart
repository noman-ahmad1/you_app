import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/models/journal_model.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/base/app_log.dart';
import 'package:you_app/services/base/firestore_base.dart';

class JournalService with FirestoreServiceMixin {
  AnalyticsService get _analytics => locator<AnalyticsService>();


  /// Adds a new journal entry to a subcollection for the current user.
  Future<void> addJournalEntry(JournalEntry entry) async {
    try {
      // Storing entries in a subcollection is a secure and scalable pattern.
      final journalCollection = db
          .collection('users')
          .doc(entry.userId)
          .collection('journal')
          .withConverter<JournalEntry>(
            fromFirestore: JournalEntry.fromFirestore,
            toFirestore: (journalEntry, _) => journalEntry.toFirestore(),
          );

      await journalCollection.add(entry);
      _analytics.logJournalCreated(label: entry.label.name);
    } catch (e) {
      AppLog.error('JournalService.addJournalEntry', e);
      // Rethrow the exception so the ViewModel can catch it and show a dialog
      rethrow;
    }
  }

  /// Streams the user's journal entries, newest first. Free-tier callers pass
  /// [sinceDays] to limit history to a recent window; premium passes null for
  /// the full, unlimited history. (These are the user's OWN private entries, so
  /// the window is a product gate, not a security boundary.)
  Stream<List<JournalEntry>> getJournalEntriesStream({
    required String userId,
    int? sinceDays,
  }) {
    Query<Map<String, dynamic>> query = db
        .collection('users')
        .doc(userId)
        .collection('journal'); // The name you chose in your rules

    if (sinceDays != null) {
      final cutoff = DateTime.now().subtract(Duration(days: sinceDays));
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff));
    }

    final journalCollection = query
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
      await db
          .collection('users')
          .doc(userId)
          .collection('journal')
          .doc(entryId)
          .update(data);
      _analytics.logJournalUpdated(
          label: data['label'] is String ? data['label'] as String : null);
    } catch (e) {
      AppLog.error('JournalService.updateJournalEntry', e);
      rethrow;
    }
  }

  Future<void> deleteJournalEntry({
    required String userId,
    required String entryId,
  }) async {
    try {
      // Construct the exact path to the document to be deleted.
      await db
          .collection('users')
          .doc(userId)
          .collection('journal') // Ensure this matches your collection name
          .doc(entryId)
          .delete();
      _analytics.logJournalDeleted();
    } catch (e) {
      AppLog.error('JournalService.deleteJournalEntry', e);
      rethrow;
    }
  }
}
