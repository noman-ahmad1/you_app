import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/models/mood_model.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/base/app_log.dart';
import 'package:you_app/services/base/firestore_base.dart';

class MoodService with FirestoreServiceMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  AnalyticsService get _analytics => locator<AnalyticsService>();

  // Method to add a new mood entry
  Future<void> saveMoodEntry(MoodEntry entry) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      AppLog.info('MoodService.saveMoodEntry', 'No authenticated user.');
      return;
    }

    try {
      final data = {
        'userId': userId,
        'moodLabel': entry.moodLabel,
        'timestamp': FieldValue.serverTimestamp(),
        'extraField': entry.extraField,
      };

      await db.collection('mood').add(data);
      _analytics.logMoodLogged(moodLabel: entry.moodLabel);
      AppLog.info('MoodService.saveMoodEntry', 'saved for $userId - ${entry.moodLabel}');
    } on FirebaseException catch (e) {
      AppLog.firebase('MoodService.saveMoodEntry', '${e.code} - ${e.message}');
    } catch (e) {
      AppLog.error('MoodService.saveMoodEntry', e);
    }
  }

  // Stream entries for the current user (filtered by userId)
  Stream<List<MoodEntry>> getUserMoodStream(String userId) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    return db
        .collection('mood')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: thirtyDaysAgo)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MoodEntry.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Admin View: Fetch all mood entries (no user filter)
  Future<List<MoodEntry>> getAllMoodEntriesForAdmin() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      AppLog.info('MoodService.getAllMoodEntriesForAdmin', 'No authenticated user.');
      return [];
    }

    // Optional: verify if user is admin
    final userDoc = await db.collection('users').doc(userId).get();
    final isAdmin = userDoc.data()?['role'] == 'admin';
    if (!isAdmin) {
      AppLog.info('MoodService.getAllMoodEntriesForAdmin', 'Access denied. Not an admin.');
      return [];
    }

    try {
      final querySnapshot = await db
          .collection('mood')
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MoodEntry.fromFirestore(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      AppLog.firebase('MoodService.getAllMoodEntriesForAdmin', '${e.code} - ${e.message}');
      return [];
    } catch (e) {
      AppLog.error('MoodService.getAllMoodEntriesForAdmin', e);
      return [];
    }
  }

  /// Cursor-paginated admin view of mood entries. Pass the previous page's
  /// [lastDoc] as [startAfter] to fetch the next page. Admin-gated.
  Future<({List<MoodEntry> items, DocumentSnapshot? lastDoc})>
      getMoodEntriesPageForAdmin(
          {DocumentSnapshot? startAfter, int limit = 30}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return (items: <MoodEntry>[], lastDoc: null);

    final userDoc = await db.collection('users').doc(userId).get();
    if (userDoc.data()?['role'] != 'admin') {
      AppLog.info('MoodService.getMoodEntriesPageForAdmin', 'Access denied. Not an admin.');
      return (items: <MoodEntry>[], lastDoc: null);
    }

    Query<Map<String, dynamic>> query =
        db.collection('mood').orderBy('timestamp', descending: true).limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final snap = await query.get();
    return (
      items: snap.docs
          .map((doc) => MoodEntry.fromFirestore(doc.data(), doc.id))
          .toList(),
      lastDoc: snap.docs.isEmpty ? null : snap.docs.last,
    );
  }
}
