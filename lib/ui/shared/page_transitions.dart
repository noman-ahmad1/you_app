import 'package:flutter/material.dart';

/// Reusable transition builders for the stacked router (`CustomRoute`). They
/// keep motion calm and purposeful, matching the app's meditative tone.

/// Gentle cross-fade — good for calm destinations (e.g. Breathe).
Widget fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
    child: child,
  );
}

/// Fade + subtle scale-in from 96% — a soft "zoom into focus".
Widget scaleFadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
  return FadeTransition(
    opacity: curved,
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
      child: child,
    ),
  );
}

/// Slide up from the bottom with a fade — good for threads / chat.
Widget slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
          .animate(curved),
      child: child,
    ),
  );
}
