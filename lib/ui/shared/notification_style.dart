import 'package:flutter/material.dart';
import 'package:you_app/ui/common/app_colors.dart';

/// Single source of truth for notification visuals, so the in-app banner and
/// the user/volunteer notification drawers stay on-theme and consistent.
class NotificationStyle {
  const NotificationStyle._();

  /// Shared soft off-white surface used by banners & drawers.
  static const Color surface = AppColors.surface;

  /// Brand accent (icon tint, unread dot, banner border).
  static const Color accent = AppColors.secondary;

  /// Emoji icon for a notification [type].
  static String iconFor(String type) {
    switch (type) {
      case 'request_received':
      case 'chat_request':
        return '⏳';
      case 'request_accepted':
        return '🎉';
      case 'new_message':
        return '💬';
      case 'broadcast':
        return '📢';
      case 'new_reply':
        return '↩️';
      case 'new_mention':
        return '🔖';
      case 'whisper':
        return '🌸';
      case 'habit':
        return '💜';
      case 'chatbot':
        return '🕊️';
      default:
        return '🌱';
    }
  }

  /// The emoji inside a tinted circular badge — the shared icon motif.
  static Widget iconBadge(String type, {double fontSize = 20, double pad = 8}) {
    return Container(
      padding: EdgeInsets.all(pad),
      decoration: const BoxDecoration(
        color: Color(0x33CDBABE), // secondaryVeryLight @ ~20%
        shape: BoxShape.circle,
      ),
      child: Text(iconFor(type), style: TextStyle(fontSize: fontSize)),
    );
  }
}
