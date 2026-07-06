import 'dart:async';

import 'package:stacked/stacked.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/models/journal_model.dart';
import 'package:you_app/models/mood_model.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/journal_service.dart';
import 'package:you_app/services/monetization_service.dart';
import 'package:you_app/services/mood_service.dart';

/// A single parsed mood check-in used for aggregation.
class _MoodPoint {
  final DateTime dt;
  final double score; // 0.1 (low) .. 1.0 (bright)
  final String label;
  _MoodPoint(this.dt, this.score, this.label);
}

/// Computes gentle, agency-oriented mood insights for the YOU+ insights screen
/// from the user's mood check-ins cross-referenced with their journaling days.
///
/// Framing rules (deliberate): never surface a low pattern without a path
/// forward, never blame the user, and only show the journaling correlation as
/// encouragement — never as "you didn't journal, that's why you're low".
class MoodInsightsViewModel extends BaseViewModel {
  final _authService = locator<AuthenticationService>();
  final _monetizationService = locator<MonetizationService>();
  final _moodService = locator<MoodService>();
  final _journalService = locator<JournalService>();

  /// Insights look back further than the tracker's window so patterns have
  /// enough data to be meaningful.
  static const int windowDays = 90;

  StreamSubscription<List<MoodEntry>>? _moodSub;
  StreamSubscription<List<JournalEntry>>? _journalSub;

  List<MoodEntry> _moods = [];
  Set<String> _journaledDates = {};

  bool get isPremium => _monetizationService.isPremium;

  // ---- Computed, view-facing state ----
  bool hasEnoughData = false;
  int totalCheckIns = 0;

  final List<double?> weekdayAverages = List<double?>.filled(7, null);
  bool showWeekday = false;
  int brightestWeekday = 0;
  int toughestWeekday = 0;

  final List<double?> timeAverages = List<double?>.filled(4, null);
  bool showTimeOfDay = false;
  int brightestBucket = 0;
  int toughestBucket = 0;

  bool showCorrelation = false;
  double journaledAvg = 0;
  double otherAvg = 0;

  int checkedInDays = 0; // of the last 14
  final List<bool> last14Checked = List<bool>.filled(14, false);

  double positiveFraction = 0;
  double neutralFraction = 0;
  double negativeFraction = 0;

  String heroTitle = '';
  String heroBody = '';
  String weekdayInsight = '';
  String weekdaySuggestion = '';
  String timeInsight = '';
  String correlationInsight = '';
  String consistencyInsight = '';
  String balanceInsight = '';
  String reflection = '';

  static const List<String> weekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  static const List<String> weekdayShort = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const List<String> bucketNames = [
    'Morning', 'Afternoon', 'Evening', 'Night'
  ];
  static const List<String> bucketPlural = [
    'mornings', 'afternoons', 'evenings', 'nights'
  ];

  static const Set<String> _positive = {
    'Energized', 'Joyful', 'Blessed', 'Happy'
  };
  static const Set<String> _negative = {
    'Sad', 'Restless', 'Anxious', 'Angry'
  };

  Future<void> load() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    setBusy(true);
    await _moodSub?.cancel();
    await _journalSub?.cancel();

    _moodSub =
        _moodService.getUserMoodStream(uid, windowDays: windowDays).listen(
      (entries) {
        _moods = entries;
        _recompute();
        if (isBusy) setBusy(false);
      },
      onError: (_) {
        if (isBusy) setBusy(false);
      },
    );

    _journalSub = _journalService
        .getJournalEntriesStream(userId: uid, sinceDays: windowDays)
        .listen(
      (entries) {
        _journaledDates = {
          for (final e in entries)
            if (e.timestamp != null) _dayKey(e.timestamp!)
        };
        _recompute();
      },
      onError: (_) {},
    );
  }

  void _recompute() {
    final pts = <_MoodPoint>[];
    for (final e in _moods) {
      DateTime dt;
      try {
        dt = DateTime.parse(e.timestamp).toLocal();
      } catch (_) {
        continue;
      }
      pts.add(_MoodPoint(dt, _score(e.moodLabel), e.moodLabel));
    }

    totalCheckIns = pts.length;
    hasEnoughData = pts.length >= 5;
    if (!hasEnoughData) {
      notifyListeners();
      return;
    }

    _computeWeekday(pts);
    _computeTimeOfDay(pts);
    _computeCorrelation(pts);
    _computeConsistency(pts);
    _computeBalance(pts);
    _buildCopy();

    notifyListeners();
  }

  void _computeWeekday(List<_MoodPoint> pts) {
    final buckets = List.generate(7, (_) => <double>[]);
    for (final p in pts) {
      buckets[p.dt.weekday - 1].add(p.score);
    }
    for (int i = 0; i < 7; i++) {
      weekdayAverages[i] = buckets[i].isEmpty ? null : _mean(buckets[i]);
    }
    final candidates = [for (int i = 0; i < 7; i++) if (buckets[i].length >= 2) i];
    showWeekday = candidates.length >= 2;
    if (!showWeekday) return;
    candidates.sort((a, b) => weekdayAverages[a]!.compareTo(weekdayAverages[b]!));
    toughestWeekday = candidates.first;
    brightestWeekday = candidates.last;
    final spread =
        weekdayAverages[brightestWeekday]! - weekdayAverages[toughestWeekday]!;
    if (spread < 0.08) showWeekday = false;
  }

  void _computeTimeOfDay(List<_MoodPoint> pts) {
    final buckets = List.generate(4, (_) => <double>[]);
    for (final p in pts) {
      buckets[_bucket(p.dt.hour)].add(p.score);
    }
    for (int i = 0; i < 4; i++) {
      timeAverages[i] = buckets[i].isEmpty ? null : _mean(buckets[i]);
    }
    final candidates = [for (int i = 0; i < 4; i++) if (buckets[i].length >= 2) i];
    showTimeOfDay = candidates.length >= 2;
    if (!showTimeOfDay) return;
    candidates.sort((a, b) => timeAverages[a]!.compareTo(timeAverages[b]!));
    toughestBucket = candidates.first;
    brightestBucket = candidates.last;
    final spread =
        timeAverages[brightestBucket]! - timeAverages[toughestBucket]!;
    if (spread < 0.08) showTimeOfDay = false;
  }

  void _computeCorrelation(List<_MoodPoint> pts) {
    // Compare per-day average mood on journaled days vs other days, so a day
    // with many check-ins doesn't dominate.
    final byDay = <String, List<double>>{};
    for (final p in pts) {
      (byDay[_dayKey(p.dt)] ??= []).add(p.score);
    }
    final journaled = <double>[];
    final other = <double>[];
    byDay.forEach((day, scores) {
      final avg = _mean(scores);
      if (_journaledDates.contains(day)) {
        journaled.add(avg);
      } else {
        other.add(avg);
      }
    });
    showCorrelation = false;
    if (journaled.length >= 2 && other.length >= 2) {
      journaledAvg = _mean(journaled);
      otherAvg = _mean(other);
      // Only surface it as encouragement when journaling days trend brighter.
      if (journaledAvg - otherAvg >= 0.05) showCorrelation = true;
    }
  }

  void _computeConsistency(List<_MoodPoint> pts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoff = today.subtract(const Duration(days: 13));
    final days = <String>{};
    for (final p in pts) {
      final d = DateTime(p.dt.year, p.dt.month, p.dt.day);
      if (!d.isBefore(cutoff)) days.add(_dayKey(d));
    }
    checkedInDays = days.length > 14 ? 14 : days.length;
    for (int i = 0; i < 14; i++) {
      final d = today.subtract(Duration(days: 13 - i));
      last14Checked[i] = days.contains(_dayKey(d));
    }
  }

  void _computeBalance(List<_MoodPoint> pts) {
    int pos = 0, neu = 0, neg = 0;
    for (final p in pts) {
      if (_positive.contains(p.label)) {
        pos++;
      } else if (_negative.contains(p.label)) {
        neg++;
      } else {
        neu++;
      }
    }
    final total = pts.length;
    positiveFraction = pos / total;
    neutralFraction = neu / total;
    negativeFraction = neg / total;
  }

  void _buildCopy() {
    if (showWeekday) {
      final bright = weekdayNames[brightestWeekday];
      final tough = weekdayNames[toughestWeekday];
      weekdayInsight =
          '${bright}s tend to be your brightest, while ${tough}s can feel a little heavier.';
      weekdaySuggestion =
          '${tough}s lean tougher — it can help to plan something kind for yourself, however small.';
    }

    if (showTimeOfDay) {
      timeInsight =
          'You tend to feel lighter in the ${bucketPlural[brightestBucket]}, and ${bucketPlural[toughestBucket]} can be a little harder. Worth being gentle with yourself then.';
    }

    if (showCorrelation) {
      correlationInsight =
          'You tend to feel a little brighter on the days you journal. Your words seem to be doing something kind for you — no pressure, just a gentle pattern worth noticing.';
    }

    consistencyInsight =
        "You've checked in $checkedInDays of the last 14 days. That steady attention to how you feel is its own quiet strength.";

    balanceInsight = _balanceSentence();

    if (showCorrelation) {
      heroTitle = 'You feel brighter when you journal';
      heroBody =
          'On the days you put words to things, your mood tends to lift. A small habit that seems to be quietly working for you.';
    } else if (showWeekday) {
      heroTitle = '${weekdayNames[brightestWeekday]}s are your bright spot';
      heroBody =
          'Across the last while, ${weekdayNames[brightestWeekday]}s have been your lightest days. Worth leaning into whatever makes them good.';
    } else {
      heroTitle = 'You keep showing up for yourself';
      heroBody =
          "You've checked in $checkedInDays of the last 14 days. Simply noticing how you feel is real, meaningful work.";
    }

    final parts = <String>[
      "Over the last while you've checked in $totalCheckIns times."
    ];
    if (showWeekday) {
      parts.add('You tend to shine on ${weekdayNames[brightestWeekday]}s.');
    }
    if (showCorrelation) parts.add('Journaling seems to lift your days.');
    parts.add("Keep listening to yourself — you're doing the work.");
    reflection = parts.join(' ');
  }

  // --- helpers ---

  double _mean(List<double> xs) =>
      xs.fold<double>(0, (a, b) => a + b) / xs.length;

  /// A warm, non-judgmental read of the emotional mix — leads with the dominant
  /// lean but never frames heavier days as a failing.
  String _balanceSentence() {
    const closing =
        'Feeling many things is deeply human — none of it is a problem to fix.';

    final cats = <MapEntry<String, double>>[
      MapEntry('brighter', positiveFraction),
      MapEntry('steady', neutralFraction),
      MapEntry('heavier', negativeFraction),
    ]..sort((a, b) => b.value.compareTo(a.value));
    final top = cats.first;
    final gap = cats[0].value - cats[1].value;

    // A fairly even spread — name the balance itself.
    if (gap < 0.15 && top.value < 0.55) {
      return 'Your recent check-ins have held a real balance — brighter moments, steadier ones, and heavier ones all woven together. $closing';
    }

    switch (top.key) {
      case 'brighter':
        return 'Lately your days have leaned brighter, with plenty of room for the steadier and heavier moments too. $closing';
      case 'steady':
        return 'Lately your days have felt mostly steady, holding a few brighter and heavier moments along the way. $closing';
      default: // heavier days most common — be especially gentle, add agency.
        return "There's been a little more weight than lightness lately — and that's okay. Heavier stretches pass, and simply noticing them is already a kind of care. Be gentle with yourself.";
    }
  }

  double _score(String label) {
    switch (label) {
      case 'Energized':
        return 1.0;
      case 'Joyful':
        return 0.9;
      case 'Blessed':
        return 0.8;
      case 'Happy':
        return 0.7;
      case 'Neutral':
        return 0.6;
      case 'Sad':
        return 0.4;
      case 'Restless':
        return 0.3;
      case 'Anxious':
        return 0.2;
      case 'Angry':
        return 0.1;
      default:
        return 0.0;
    }
  }

  int _bucket(int hour) {
    if (hour >= 5 && hour <= 11) return 0; // morning
    if (hour >= 12 && hour <= 16) return 1; // afternoon
    if (hour >= 17 && hour <= 21) return 2; // evening
    return 3; // night
  }

  String _dayKey(DateTime d) => '${d.year}-${_pad2(d.month)}-${_pad2(d.day)}';
  String _pad2(int n) => n < 10 ? '0$n' : '$n';

  @override
  void dispose() {
    _moodSub?.cancel();
    _journalSub?.cancel();
    super.dispose();
  }
}
