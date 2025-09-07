import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/ui_helpers.dart';

enum SwipeDirection { left, right, both }

class SwipeButton extends StatefulWidget {
  final String text;
  final String iconAsset;
  final double width;
  final double height;
  final VoidCallback? onSwipe;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final SwipeDirection direction;

  const SwipeButton({
    super.key,
    required this.text,
    required this.iconAsset,
    this.width = double.infinity,
    this.height = 100,
    this.onSwipe,
    this.onSwipeLeft,
    this.onSwipeRight,
    required this.direction,
  });

  @override
  State<SwipeButton> createState() => _SwipeButtonState();
}

class _SwipeButtonState extends State<SwipeButton>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late AnimationController _positionController;
  bool _swiped = false;
  double _dragValue = 0.5; // For center swipe

  @override
  void initState() {
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      lowerBound: 0,
      upperBound: 1,
    );
    _positionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    super.initState();
  }

  @override
  void dispose() {
    _expandController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    final borderRadius = BorderRadius.circular(widget.height / 2);
    final thumbSize = widget.height;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Track
          ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
              child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondaryVeryLight.withAlpha(10),
                    borderRadius: borderRadius,
                    border: Border.all(color: AppColors.secondary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: widget.direction == SwipeDirection.both
                      ? Padding(
                          padding: EdgeInsets.fromLTRB(
                              width * 0.05, 0, width * 0.05, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.text,
                                style: GoogleFonts.crimsonPro(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                              Space.horizontalSpaceMedium(context),
                              Text(
                                widget.text,
                                style: GoogleFonts.crimsonPro(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          widget.text,
                          style: GoogleFonts.crimsonPro(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        )),
            ),
          ),

          // Thumb
          if (widget.direction == SwipeDirection.both)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              left: _dragValue * (widget.width - thumbSize),
              top: 0,
              child: GestureDetector(
                onHorizontalDragStart: (_) {
                  setState(() {});
                },
                onHorizontalDragUpdate: (details) {
                  final delta =
                      details.primaryDelta! / (widget.width - thumbSize);
                  setState(() {
                    _dragValue = (_dragValue + delta).clamp(0.0, 1.0);
                  });
                },
                onHorizontalDragEnd: (_) {
                  // Check if swiped to left or right edge
                  if (_dragValue < 0.2) {
                    HapticFeedback.mediumImpact();
                    widget.onSwipeLeft?.call();
                  } else if (_dragValue > 0.8) {
                    HapticFeedback.mediumImpact();
                    widget.onSwipeRight?.call();
                  }
                  // Return to center if not swiped to edge
                  setState(() => _dragValue = 0.5);
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(thumbSize / 2),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
                      child: Container(
                        width: thumbSize - 8,
                        height: thumbSize - 8,
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: AppColors.secondary, width: 2),
                          color: AppColors.secondaryVeryLight.withAlpha(10),
                          borderRadius: BorderRadius.circular(thumbSize / 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            widget.iconAsset,
                            width: (thumbSize - 8) * 0.9,
                            height: (thumbSize - 8) * 0.9,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            AnimatedBuilder(
              animation: _expandController,
              builder: (context, child) {
                final double initialWidth = widget.height;
                final expandedWidth = initialWidth +
                    (_expandController.value * (widget.width - initialWidth));
                return Align(
                  alignment: widget.direction == SwipeDirection.right
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      final delta = (widget.direction == SwipeDirection.left)
                          ? details.primaryDelta! /
                              (widget.width - widget.height)
                          : -details.primaryDelta! /
                              (widget.width - widget.height);
                      if (!_swiped) {
                        _expandController.value =
                            (_expandController.value + delta).clamp(0.0, 1.0);
                        if (_expandController.value == 1) {
                          _swiped = true;
                          HapticFeedback.mediumImpact();
                          widget.onSwipe?.call();
                        }
                      }
                    },
                    onHorizontalDragEnd: (_) {
                      if (!_swiped) {
                        _expandController.reverse();
                      } else {
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            _expandController.reverse();
                            _swiped = false;
                          }
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
                          child: Container(
                            width: expandedWidth - 8,
                            height: widget.height - 8,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.secondary, width: 2),
                              color: AppColors.secondaryVeryLight.withAlpha(10),
                              borderRadius: borderRadius,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.zero,
                            child: Center(
                              child: Image.asset(
                                widget.iconAsset,
                                width: (widget.height - 8) * 0.9,
                                height: (widget.height - 8) * 0.9,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
