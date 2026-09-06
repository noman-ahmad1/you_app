import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/shared/notification_style.dart';
import 'package:you_app/ui/views/chat/chat_viewmodel.dart';

class InAppNotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final String type;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const InAppNotificationBanner({
    super.key,
    required this.title,
    required this.body,
    required this.type,
    this.onTap,
    required this.onDismiss,
  });

  /// Triggers a sliding banner from anywhere in the app using the global navigator overlay.
  static void show({
    required String title,
    required String body,
    required String type,
    VoidCallback? onTap,
  }) {
    if (ChatViewModel.isActive && type == 'new_message') return;

    final overlayState = StackedService.navigatorKey?.currentState?.overlay;
    if (overlayState == null) return;

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => InAppNotificationBanner(
        title: title,
        body: body,
        type: type,
        onTap: onTap,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }

  @override
  State<InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    // Auto dismiss after 4 seconds
    _dismissTimer = Timer(const Duration(seconds: 4), () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (!mounted || _isDismissing) return;
    _isDismissing = true;
    _dismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + 12;

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: () {
              if (widget.onTap != null) widget.onTap!();
              _dismiss();
            },
            onVerticalDragUpdate: (details) {
              // Swipe up to dismiss immediately
              if (details.delta.dy < -5) {
                _dismiss();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: NotificationStyle.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.secondary.withAlpha(50),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    NotificationStyle.iconBadge(widget.type),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.crimsonPro(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryVeryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.body,
                            style: GoogleFonts.crimsonPro(
                              fontSize: 12,
                              color: AppColors.primaryVeryDark.withAlpha(160),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: AppColors.secondary.withAlpha(150),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _dismiss,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
