import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/views/volunteer_home/volunteer_home_viewmodel.dart';

class VolunteerNotificationsDrawer extends StatelessWidget {
  final VolunteerHomeViewModel viewModel;
  const VolunteerNotificationsDrawer({super.key, required this.viewModel});

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('d MMM').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = locator<AuthenticationService>();
    final currentUserId = authService.currentUser?.uid;

    if (currentUserId == null) {
      return _buildDrawerContent(context, []);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> liveNotifications = [];
        if (snapshot.hasData && snapshot.data != null) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data();
            final title = data['title'] as String? ?? 'Notification';
            final body = data['body'] as String? ?? '';
            final type = data['type'] as String? ?? '';
            final isRead = data['isRead'] as bool? ?? false;
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final customData = data['data'] as Map<String, dynamic>?;

            String icon = '🌱';
            VoidCallback? onTap;

            if (type == 'request_received' || type == 'chat_request') {
              icon = '⏳';
              onTap = () {
                Navigator.of(context).pop(); // Close drawer
                viewModel.setTab(0); // Switch to pending requests tab
              };
            } else if (type == 'new_message') {
              icon = '💬';
              final chatId = customData?['chatId'] as String?;
              if (chatId != null) {
                onTap = () {
                  Navigator.of(context).pop(); // Close drawer
                  final parts = chatId.split('_');
                  final requesterId = parts.firstWhere((id) => id != currentUserId, orElse: () => '');
                  locator<NavigationService>().navigateToChatView(
                    volunteerId: requesterId,
                    volunteerName: "User",
                    requestId: requesterId,
                  );
                };
              }
            } else if (type == 'whisper') {
              icon = '🌸';
            } else if (type == 'habit') {
              icon = '💜';
            } else if (type == 'chatbot') {
              icon = '🕊️';
            }

            liveNotifications.add({
              'icon': icon,
              'title': title,
              'body': body,
              'time': _formatTimeAgo(createdAt),
              'isUnread': !isRead,
              'onTap': onTap,
            });
          }
        }

        // Combine live notification data with volunteer specific dummy data if empty
        final combinedNotifications = [
          ...liveNotifications,
          if (liveNotifications.isEmpty) ...[
            {
              'icon': '⏳',
              'title': 'New Pending Chat Request',
              'body': 'A friend wants to connect with you.',
              'time': '5m ago',
              'isUnread': true,
              'onTap': () {
                Navigator.of(context).pop();
                viewModel.setTab(0);
              },
            },
            {
              'icon': '🌱',
              'title': 'System Notification',
              'body': 'Your availability status has been set to Online.',
              'time': '1h ago',
              'isUnread': false,
              'onTap': null,
            },
          ]
        ];

        return _buildDrawerContent(context, combinedNotifications);
      },
    );
  }

  Widget _buildDrawerContent(BuildContext context, List<Map<String, dynamic>> notifications) {
    return Drawer(
      backgroundColor: const Color(0xFFFBF8F5), // Soft off-white to match theme
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Title and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.crimsonPro(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.close,
                          size: 20, color: AppColors.secondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Notifications List
              Expanded(
                child: ListView.separated(
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationCard(
                      icon: notification['icon'] as String,
                      title: notification['title'] as String,
                      body: notification['body'] as String? ?? '',
                      time: notification['time'] as String,
                      isUnread: notification['isUnread'] as bool,
                      onTap: notification['onTap'] as VoidCallback?,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required String icon,
    required String title,
    required String body,
    required String time,
    required bool isUnread,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryVeryDark,
                        ),
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        time,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUnread) ...[
                  const SizedBox(width: 12),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF9070B6), // Purple dot
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
