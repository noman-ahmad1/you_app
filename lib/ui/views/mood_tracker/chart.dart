import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';

import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/firestore_service.dart';
import 'package:you_app/models/mood_model.dart';

class BarChartSample7 extends StatefulWidget {
  BarChartSample7({super.key});

  final shadowColor = const Color(0xFFCCCCCC);
  final dataList = [
    const _BarData(AppColors.teal, 18, 18, 'assets/icons/emo1.png'),
    const _BarData(AppColors.lightPurple, 17, 8, 'assets/icons/emo2.png'),
    const _BarData(AppColors.pink, 10, 15, 'assets/icons/emo3.png'),
    const _BarData(AppColors.peach, 2.5, 5, 'assets/icons/emo4.png'),
    const _BarData(AppColors.darkYellow, 2, 2.5, 'assets/icons/emo5.png'),
    const _BarData(AppColors.yellow, 2, 2, 'assets/icons/emo6.png'),
    const _BarData(AppColors.camel, 10, 15, 'assets/icons/emo7.png'),
    const _BarData(AppColors.darkOrange, 10, 15, 'assets/icons/emo8.png'),
    const _BarData(AppColors.red, 10, 15, 'assets/icons/emo9.png'),
  ];

  @override
  State<BarChartSample7> createState() => _BarChartSample7State();
}

class _BarChartSample7State extends State<BarChartSample7> {
  final _firestoreService = locator<FirestoreService>();

  // Dynamic chart data from Firestore (per-user, last 30 days)
  List<_BarData> dynamicDataList = [];
  bool _isLoading = true;
  StreamSubscription<List<MoodEntry>>? _moodSubscription;

  BarChartGroupData generateBarGroup(
    int x,
    Color color,
    double value,
    double shadowValue,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: color,
          width: 15,
        ),
      ],
      showingTooltipIndicators: touchedGroupIndex == x ? [0] : [],
    );
  }

  int touchedGroupIndex = -1;
  int rotationTurns = 1;

  @override
  void initState() {
    super.initState();
    _subscribeToMoodStream();
  }

  Future<void> _subscribeToMoodStream() async {
    final userId = _firestoreService.userId;
    if (userId.isEmpty || userId == 'anonymous_user') {
      // No logged-in user — keep dummy data and stop loading
      debugPrint('BarChart: no logged-in user; showing default data.');
      setState(() => _isLoading = false);
      return;
    }

    // Listen to the user stream (your FirestoreService.mood.getUserMoodStream)
    _moodSubscription = _firestoreService.mood.getUserMoodStream(userId).listen(
        (List<MoodEntry> moods) {
      try {
        // Filter last 30 days on client as a safety net.
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        final recent = moods.where((m) {
          final dt = DateTime.tryParse(m.timestamp);
          if (dt == null) return false;
          return !dt.isBefore(thirtyDaysAgo); // dt >= thirtyDaysAgo
        }).toList();

        // Count occurrences by label
        final Map<String, int> moodCount = {};
        for (final m in recent) {
          moodCount[m.moodLabel] = (moodCount[m.moodLabel] ?? 0) + 1;
        }

        // Map into _BarData in the same order as moodDataMap
        dynamicDataList = moodDataMap.entries.map((entry) {
          final label = entry.key;
          final color = _getColorForLabel(label);
          final count = (moodCount[label] ?? 0).toDouble();
          final emoji = entry.value['assetId'] as String;
          return _BarData(color, count, count, emoji);
        }).toList();

        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        debugPrint('BarChart stream processing error: $e');
        setState(() => _isLoading = false);
      }
    }, onError: (e) {
      debugPrint('BarChart stream error: $e');
      setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _moodSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Choose source list: show static widget.dataList while loading
    final source = _isLoading ? widget.dataList : dynamicDataList;

    // Compute maxY dynamically (keeps 20 as minimum to preserve current look)
    final maxValue = source.isEmpty
        ? 20.0
        : math.max(15.0, source.map((d) => d.value).fold(0.0, math.max));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Container()),
              Text(
                'Emotional Insights',
                style: GoogleFonts.crimsonPro(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary),
              ),
              Expanded(
                  child: Align(
                alignment: Alignment.centerRight,
                child: Tooltip(
                  message: 'Rotate the chart 90 degrees (cw)',
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        rotationTurns += 1;
                      });
                    },
                    icon: RotatedBox(
                      quarterTurns: rotationTurns - 1,
                      child: const Icon(
                        color: AppColors.primaryVeryDark,
                        Icons.rotate_90_degrees_cw,
                      ),
                    ),
                  ),
                ),
              )),
            ],
          ),
          const SizedBox(height: 18),
          AspectRatio(
            aspectRatio: 1.4,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                rotationQuarterTurns: rotationTurns,
                borderData: FlBorderData(
                  show: true,
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: AppColors.secondary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: const AxisTitles(
                    drawBelowEverything: true,
                    sideTitles: SideTitles(
                      showTitles: false,
                      reservedSize: 30,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= source.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: _IconWidget(
                            emojiAsset: source[index].emojiAsset,
                            isSelected: touchedGroupIndex == index,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.secondary.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
                barGroups: source.asMap().entries.map((e) {
                  final index = e.key;
                  final data = e.value;
                  return generateBarGroup(
                    index,
                    data.color,
                    data.value,
                    data.shadowValue,
                  );
                }).toList(),
                maxY: maxValue,
                barTouchData: BarTouchData(
                  enabled: true,
                  handleBuiltInTouches: false,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.transparent,
                    tooltipMargin: 0,
                    getTooltipItem: (
                      BarChartGroupData group,
                      int groupIndex,
                      BarChartRodData rod,
                      int rodIndex,
                    ) {
                      return BarTooltipItem(
                        rod.toY.toString(),
                        TextStyle(
                          fontWeight: FontWeight.bold,
                          color: rod.color,
                          fontSize: 18,
                          shadows: const [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 12,
                            )
                          ],
                        ),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (event.isInterestedForInteractions &&
                        response != null &&
                        response.spot != null) {
                      setState(() {
                        touchedGroupIndex = response.spot!.touchedBarGroupIndex;
                      });
                    } else {
                      setState(() {
                        touchedGroupIndex = -1;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarData {
  const _BarData(this.color, this.value, this.shadowValue, this.emojiAsset);

  final Color color;
  final double value;
  final double shadowValue;
  final String emojiAsset;
}

class _IconWidget extends ImplicitlyAnimatedWidget {
  const _IconWidget({
    required this.emojiAsset,
    required this.isSelected,
  }) : super(duration: const Duration(milliseconds: 300));
  final String emojiAsset;
  final bool isSelected;

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() =>
      _IconWidgetState();
}

class _IconWidgetState extends AnimatedWidgetBaseState<_IconWidget> {
  Tween<double>? _rotationTween;

  @override
  Widget build(BuildContext context) {
    final rotation = math.pi * 4 * _rotationTween!.evaluate(animation);
    final scale = 1 + _rotationTween!.evaluate(animation) * 0.5;
    return Transform(
      transform:
          Matrix4.rotationZ(rotation).scaledByDouble(scale, scale, scale, 1.0),
      origin: const Offset(14, 14),
      child: Image.asset(
        widget.emojiAsset,
        width: 28,
        height: 28,
        colorBlendMode: widget.isSelected ? BlendMode.dst : BlendMode.modulate,
      ),
    );
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _rotationTween = visitor(
      _rotationTween,
      widget.isSelected ? 1.0 : 0.0,
      (dynamic value) => Tween<double>(
        begin: value as double,
        end: widget.isSelected ? 1.0 : 0.0,
      ),
    ) as Tween<double>?;
  }
}

Color _getColorForLabel(String label) {
  switch (label) {
    case 'Energized':
      return AppColors.teal;
    case 'Joyful':
      return AppColors.lightPurple;
    case 'Blessed':
      return AppColors.pink;
    case 'Happy':
      return AppColors.peach;
    case 'Neutral':
      return AppColors.darkYellow;
    case 'Sad':
      return AppColors.yellow;
    case 'Restless':
      return AppColors.camel;
    case 'Anxious':
      return AppColors.darkOrange;
    case 'Angry':
      return AppColors.red;
    default:
      return AppColors.secondary;
  }
}
