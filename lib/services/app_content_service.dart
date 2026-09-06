import 'package:you_app/services/base/app_log.dart';
import 'package:you_app/services/base/firestore_base.dart';

/// Reads admin-authored content the app only ever displays (never writes):
///   • `journal_prompts/{YYYY-MM-DD}` — the daily journaling prompt
///   • `whispers/{YYYY-MM-DD}` — the daily home-screen "whisper"
///   • `app_settings/home_announcement` — an optional home-screen notice
///
/// Both streams emit null when the content is missing, inactive, or empty so
/// callers can fall back to a default (prompt) or render nothing (announcement).
class AppContentService with FirestoreServiceMixin {
  /// Today's `YYYY-MM-DD` in **Asia/Karachi (UTC+5, no DST)** — the
  /// journal_prompts doc id.
  ///
  /// The admin schedules a prompt against a calendar date, and every server-side
  /// period key (analytics, freemium caps) already uses PKT. Using the DEVICE's
  /// local date instead meant a user in another timezone (or with a skewed clock)
  /// silently requested a doc the admin never wrote and fell back to the default.
  String _todayKey() {
    final pkt = DateTime.now().toUtc().add(const Duration(hours: 5));
    final m = pkt.month.toString().padLeft(2, '0');
    final d = pkt.day.toString().padLeft(2, '0');
    return '${pkt.year}-$m-$d';
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

  /// Today's home-screen "whisper", or null when none is set (→ use the
  /// bundled default).
  ///
  /// This replaces a live fetch from zenquotes.io. Uncurated third-party text
  /// must never be shown to users in a mental-health context: there was no
  /// review step, no SLA and no key on that endpoint, and whatever it returned
  /// went straight onto the home screen. Whispers are now admin-authored, on
  /// the same PKT calendar-date key as journal_prompts.
  ///
  /// A one-shot read rather than a stream — it changes at most once a day, so
  /// a live listener would be a permanent subscription for nothing.
  Future<String?> whisperOfTheDay() async {
    try {
      final snap = await db.collection('whispers').doc(_todayKey()).get();
      if (!snap.exists) return null;
      final data = snap.data()!;
      final active = data['active'] == true;
      final text = (data['text'] as String?)?.trim() ?? '';
      return (active && text.isNotEmpty) ? text : null;
    } catch (e) {
      AppLog.error('AppContentService.whisperOfTheDay', e);
      return null; // fall back to the bundled default
    }
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
