import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:collection/collection.dart';
import 'package:you_app/ui/common/animation_decoder.dart';
import 'package:you_app/ui/common/app_constants.dart';

class LottieLikeButton extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;
  final double size;

  const LottieLikeButton({
    Key? key,
    required this.isLiked,
    required this.onTap,
    this.size = 36.0,
  }) : super(key: key);

  @override
  State<LottieLikeButton> createState() => _LottieLikeButtonState();
}

class _LottieLikeButtonState extends State<LottieLikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Setting up the animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Set initial state based on isLiked
    if (widget.isLiked) {
      _controller.value = 1.0;
    } else {
      _controller.value = 0.0;
    }
  }

  @override
  void didUpdateWidget(LottieLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked != oldWidget.isLiked) {
      if (widget.isLiked) {
        _controller.forward(from: 0.0);
      } else {
        _controller.reverse(from: 1.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      // Lottie animation often has some internal padding.
      // You can adjust size or apply a scale if necessary.
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!widget.isLiked)
              Icon(
                Icons.favorite_border_rounded,
                size: widget.size * 0.6,
                color: const Color(0xFF1E1E1E).withAlpha(100), // AppColors.primaryVeryDark
              ),
            OverflowBox(
              maxWidth: widget.size *
                  2, // Scale up Lottie slightly if it has too much padding
              maxHeight: widget.size * 2,
              child: Lottie.asset(
                AppConstants.like,
                controller: _controller,
                fit: BoxFit.cover,
                decoder: customDecoder,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Future<LottieComposition?> _customDecoder(List<int> bytes) {
  //   return LottieComposition.decodeZip(
  //     bytes,
  //     filePicker: (files) {
  //       return files.firstWhereOrNull(
  //         (f) => f.name.startsWith('animations/') && f.name.endsWith('.json'),
  //       );
  //     },
  //   );
  // }
}
