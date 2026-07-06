import 'package:flutter/material.dart';

/// Counts up (or down) to [value] when it changes, animating the integer for a
/// small moment of delight on stat displays. Uses the same TweenAnimationBuilder
/// pattern already used by the mood-tracker progress bar.
class AnimatedCount extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final String Function(int)? formatter;

  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 700),
    this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      // Animate from the previous value to the new one on every change.
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        formatter != null ? formatter!(v) : '$v',
        style: style,
      ),
    );
  }
}
