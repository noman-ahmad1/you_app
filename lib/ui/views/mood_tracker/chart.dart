import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/mood_service.dart';
import 'package:you_app/models/mood_model.dart';
import 'package:you_app/ui/common/app_colors.dart';

class WeeklyMoodChart extends StatefulWidget {
  const WeeklyMoodChart({super.key});

  @override
  State<WeeklyMoodChart> createState() => _WeeklyMoodChartState();
}

class _WeeklyMoodChartState extends State<WeeklyMoodChart> {
  final _authenticationService = locator<AuthenticationService>();
  StreamSubscription<List<MoodEntry>>? _moodSubscription;

  bool _isLoading = true;
  List<double> _weeklyScores = List.filled(7, 0.0);
  int _totalCheckIns = 0;
  int _streak = 0;
  String _topMoodEmoji = '😊'; // Default

  @override
  void initState() {
    super.initState();
    _subscribeToMoodStream();
  }

  void _subscribeToMoodStream() {
    final userId = _authenticationService.currentUser?.uid ?? '';
    if (userId.isEmpty || userId == 'anonymous_user') {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    _moodSubscription = locator<MoodService>().getUserMoodStream(userId).listen(
        (List<MoodEntry> moods) {
      if (!mounted) return;
      _processMoodData(moods);
    }, onError: (e) {
      debugPrint('WeeklyMoodChart stream error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _processMoodData(List<MoodEntry> moods) {
    _totalCheckIns = moods.length;

    // Calculate Streak
    _streak = _calculateStreak(moods);

    final now = DateTime.now();
    // Start of today
    final today = DateTime(now.year, now.month, now.day);

    // We want data for the last 7 days including today
    // Or we want data for the current week? The design says M T W T F S S
    // Let's assume it's a rolling 7 days, ending today, but labels are M-S.
    // Or standard M-S of the current week. Let's do last 7 days to always show data,
    // and just use the correct weekday labels.

    List<double> scores = List.filled(7, 0.0);
    List<DateTime> last7Days = [];
    for (int i = 6; i >= 0; i--) {
      last7Days.add(today.subtract(Duration(days: i)));
    }

    Map<String, int> recentMoodCounts = {};

    for (int i = 0; i < 7; i++) {
      final day = last7Days[i];
      final dayMoods = moods.where((m) {
        try {
          final dt = DateTime.parse(m.timestamp);
          return dt.year == day.year &&
              dt.month == day.month &&
              dt.day == day.day;
        } catch (_) {
          return false;
        }
      }).toList();

      if (dayMoods.isNotEmpty) {
        double totalScore = 0;
        for (var m in dayMoods) {
          totalScore += _getScoreForLabel(m.moodLabel);
          recentMoodCounts[m.moodLabel] =
              (recentMoodCounts[m.moodLabel] ?? 0) + 1;
        }
        scores[i] = totalScore / dayMoods.length;
      }
    }

    // Find top mood in the last 7 days
    if (recentMoodCounts.isNotEmpty) {
      String topLabel = recentMoodCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      // Get emoji from map, default to 😊 if not found or asset is empty
      final asset = moodDataMap[topLabel]?['assetId'];
      _topMoodEmoji = _getEmojiCharacterForLabel(topLabel);
    } else {
      _topMoodEmoji = '😊';
    }

    setState(() {
      _weeklyScores = scores;
      _isLoading = false;
    });
  }

  int _calculateStreak(List<MoodEntry> entries) {
    if (entries.isEmpty) return 0;

    List<DateTime> entryDates = entries.map((e) {
      try {
        return DateTime.parse(e.timestamp);
      } catch (_) {
        return DateTime.now();
      }
    }).toList();

    entryDates.sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime now = DateTime.now();
    DateTime currentDate = DateTime(now.year, now.month, now.day);

    DateTime firstEntryDate = DateTime(
        entryDates.first.year, entryDates.first.month, entryDates.first.day);
    if (firstEntryDate
        .isBefore(currentDate.subtract(const Duration(days: 1)))) {
      return 0;
    }

    Set<String> uniqueDates = {};
    for (var date in entryDates) {
      uniqueDates.add("${date.year}-${date.month}-${date.day}");
    }

    List<DateTime> sortedUniqueDates = uniqueDates.map((s) {
      var parts = s.split('-');
      return DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    }).toList();

    sortedUniqueDates.sort((a, b) => b.compareTo(a));

    DateTime checkDate = currentDate;
    for (int i = 0; i < sortedUniqueDates.length; i++) {
      if (i == 0) {
        if (sortedUniqueDates[i] == checkDate ||
            sortedUniqueDates[i] ==
                checkDate.subtract(const Duration(days: 1))) {
          streak++;
          checkDate = sortedUniqueDates[i];
        } else {
          break;
        }
      } else {
        if (sortedUniqueDates[i] ==
            checkDate.subtract(const Duration(days: 1))) {
          streak++;
          checkDate = sortedUniqueDates[i];
        } else {
          break;
        }
      }
    }
    return streak;
  }

  double _getScoreForLabel(String label) {
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

  String _getEmojiCharacterForLabel(String label) {
    // A quick mapping to actual emoji characters since the design shows a real emoji
    // not an asset for the "Top mood" card.
    switch (label) {
      case 'Energized':
        return '⚡';
      case 'Joyful':
        return '😆';
      case 'Blessed':
        return '😇';
      case 'Happy':
        return '😊';
      case 'Neutral':
        return '😐';
      case 'Sad':
        return '😢';
      case 'Restless':
        return '😬';
      case 'Anxious':
        return '😰';
      case 'Angry':
        return '😡';
      default:
        return '😊';
    }
  }

  @override
  void dispose() {
    _moodSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(24.0),
        child: CircularProgressIndicator(),
      ));
    }

    final now = DateTime.now();
    List<String> dayLabels = [];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      dayLabels.add(DateFormat('E')
          .format(d)
          .substring(0, 1)
          .toUpperCase()); // M, T, W...
    }

    const Color primaryText = AppColors.secondary;
    const Color secondaryText = AppColors.secondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.background
                .withAlpha(200), // Very light background for the whole section
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.background, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Chart Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                  color: AppColors.background, // Light background for chart
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  return _buildBar(dayLabels[index], _weeklyScores[index]);
                }),
              ),
            ),
            const SizedBox(height: 16),
            // Cards Area
            Row(
              children: [
                Expanded(
                    child: _buildInfoCard('$_totalCheckIns', 'Check-ins',
                        primaryText, secondaryText)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInfoCard(
                        '${_streak}d', 'Streak', primaryText, secondaryText)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildInfoCard(
                        _topMoodEmoji, 'Top mood', primaryText, secondaryText,
                        isEmoji: true)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String day, double score) {
    // If there is no score, show a minimal height
    final double fillHeight = (score == 0.0) ? 20.0 : score * 120.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.lightPink, width: 1.5),
          ),
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 36,
            height: fillHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [AppColors.lightPink, AppColors.lightPurple],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          day,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF7B7890),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
      String value, String label, Color primaryText, Color secondaryText,
      {bool isEmoji = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: isEmoji
                ? const TextStyle(fontSize: 28)
                : GoogleFonts.crimsonPro(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
