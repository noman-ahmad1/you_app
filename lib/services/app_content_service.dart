import 'package:you_app/services/base/firestore_base.dart';

/// Reads admin-authored content the app only ever displays (never writes):
///   • `journal_prompts/{YYYY-MM-DD}` — the daily journaling prompt
///   • `app_settings/home_announcement` — an optional home-screen notice
///
/// Both streams emit null when the content is missing, inactive, or empty so
/// callers can fall back to a default (prompt) or render nothing (announcement).
class AppContentService with FirestoreServiceMixin {
  /// Device-local calendar date as `YYYY-MM-DD` — the journal_prompts doc id.
  /// Admin schedules by calendar date; device-local keeps the day boundary
  /// aligned for users in the same timezone as the admin.
  String _todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  /// Today's journaling prompt, or null when none is active (→ use a default).
  Stream<String?> promptOfTheDay() {
    return db
        .collection('journal_prompts')
        .doc(_todayKey())
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      final data = snap.data()!;
      final active = data['active'] == true;
      final text = (data['text'] as String?)?.trim() ?? '';
      return (active && text.isNotEmpty) ? text : null;
    });
  }

  /// The home-screen announcement, or null when none should show.
  Stream<String?> homeAnnouncement() {
    return db
        .collection('app_settings')
        .doc('home_announcement')
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      final data = snap.data()!;
      final active = data['active'] == true;
      final message = (data['message'] as String?)?.trim() ?? '';
      return (active && message.isNotEmpty) ? message : null;
    });
  }
}
