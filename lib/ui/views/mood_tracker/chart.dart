import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
// import 'package:fl_chart_app/presentation/resources/app_resources.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';

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
        // BarChartRodData(
        //   toY: shadowValue,
        //   color: widget.shadowColor,
        //   width: 6,
        // ),
      ],
      showingTooltipIndicators: touchedGroupIndex == x ? [0] : [],
    );
  }

  int touchedGroupIndex = -1;

  int rotationTurns = 1;

  @override
  Widget build(BuildContext context) {
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
                        return SideTitleWidget(
                          meta: meta,
                          child: _IconWidget(
                            emojiAsset: widget.dataList[index].emojiAsset,
                            // color: widget.dataList[index].color,
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
                barGroups: widget.dataList.asMap().entries.map((e) {
                  final index = e.key;
                  final data = e.value;
                  return generateBarGroup(
                    index,
                    data.color,
                    data.value,
                    data.shadowValue,
                  );
                }).toList(),
                maxY: 20,
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
    // required this.color,
    required this.isSelected,
  }) : super(duration: const Duration(milliseconds: 300));
  final String emojiAsset;
  // final Color color;
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
        // color: widget.isSelected ? null : widget.color.withOpacity(0.5),
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
