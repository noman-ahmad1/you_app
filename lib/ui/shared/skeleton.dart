import 'package:flutter/material.dart';
import 'package:you_app/ui/common/app_colors.dart';

/// A shimmering placeholder shown while first-load content streams in. Sweeps a
/// soft highlight across its child (any composition of [SkeletonBox]es).
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 - 2 * (1 - t), 0),
              end: Alignment(1 - 2 * (1 - t), 0),
              colors: [
                AppColors.secondaryVeryLight.withAlpha(90),
                Colors.white.withAlpha(180),
                AppColors.secondaryVeryLight.withAlpha(90),
              ],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single rounded grey placeholder block.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.secondaryVeryLight.withAlpha(120),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A card-shaped skeleton approximating a community post / reply row.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(150),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              SkeletonBox(width: 42, height: 42, radius: 21),
              SizedBox(width: 10),
              SkeletonBox(width: 120, height: 14),
            ],
          ),
          const SizedBox(height: 14),
          const SkeletonBox(height: 12),
          const SizedBox(height: 8),
          const SkeletonBox(width: 220, height: 12),
        ],
      ),
    );
  }
}

/// A full-list skeleton (a few [SkeletonCard]s) wrapped in a [Shimmer].
class SkeletonList extends StatelessWidget {
  final int count;
  final EdgeInsets padding;
  const SkeletonList({
    super.key,
    this.count = 5,
    this.padding = const EdgeInsets.only(top: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(count, (_) => const SkeletonCard()),
      ),
    );
  }
}
