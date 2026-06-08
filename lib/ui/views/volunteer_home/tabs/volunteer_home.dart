import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/models/chat_request_model.dart'; // Import ChatRequest
import 'package:you_app/ui/common/animation_decoder.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/views/volunteer_home/user_card.dart';
import 'package:you_app/ui/views/volunteer_home/volunteer_home_viewmodel.dart';
import "package:you_app/ui/shared/custom_lottie_loader.dart";

// This is likely a tab, so ViewModelWidget is appropriate
class VolunteerHome extends ViewModelWidget<VolunteerHomeViewModel> {
  const VolunteerHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, VolunteerHomeViewModel viewModel) {
    // ❌ Removed the nested ViewModelBuilder

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
            image: AssetImage(AppConstants.background), fit: BoxFit.cover),
      ),
      child: Column(
        children: [
          TopBar(
            leadingIconAsset: AppConstants.logoRound, // Your 'Y' logo asset
            onLeadingPressed: () {
              // Handle tap
            },
            title: 'Home',
            subtitle: DateFormat('EEEE, MMMM d').format(DateTime.now()),
            trailingActions: [
              // Icon 1 (e.g., Notifications)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  InkWell(
                    onTap: () {
                      viewModel.markAllNotificationsAsRead();
                      Scaffold.of(context).openDrawer();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primaryVeryDark.withAlpha(50)),
                      ),
                      child: Image.asset(AppConstants.notification,
                          width: 24,
                          height: 24,
                          color: AppColors.primaryVeryDark),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity:
                            viewModel.unreadNotificationsCount > 0 ? 1.0 : 0.0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '${viewModel.unreadNotificationsCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Icon 2 (e.g., Profile/Flower)
            ],
          ),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Space.verticalSpaceTiny(context),
                    _buildAvailabilityCard(MediaQuery.of(context).size.width,
                        MediaQuery.of(context).size.height, viewModel),
                    const Divider(height: 20),
                    Text(
                      'Welcome ${viewModel.currentUserName}',
                      style: GoogleFonts.crimsonPro(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary),
                    ),
                    Text(
                      // Added subtitle for clarity
                      'Your Active Conversations',
                      style: GoogleFonts.crimsonPro(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryVeryDark),
                    ),
                    Space.verticalSpaceTiny(context),
                    Expanded(
                      child: viewModel.isBusyActiveChats &&
                              viewModel.activeChats.isEmpty
                          ? const Center(child: CustomLottieLoader())
                          : viewModel.activeChats.isEmpty
                              ? Center(
                                  child: Column(
                                  children: [
                                    Lottie.asset(
                                      AppConstants.empty,
                                      decoder: customDecoder,
                                      width: 200,
                                      height: 200,
                                    ),
                                    Text(
                                      "No active chats.",
                                      style:
                                          GoogleFonts.crimsonPro(fontSize: 20),
                                    ),
                                  ],
                                ))
                              : ListView.builder(
                                  // ✅ Use activeChats list
                                  itemCount: viewModel.activeChats.length,
                                  itemBuilder: (context, index) {
                                    // ✅ Use activeChats list
                                    final chatRequest =
                                        viewModel.activeChats[index];
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 7.0),
                                      child: UserCard(
                                        // ✅ Pass data from chatRequest
                                        username: chatRequest.requesterName,
                                        avatarPath:
                                            chatRequest.requesterAvatarUrl ??
                                                AppConstants.avatarBinary,
                                        lastMessage:
                                            "Tap to chat", // Placeholder or fetch last message
                                        timeAgo: _formatTimeAgo(chatRequest
                                            .createdAt), // Time request was created/accepted
                                        type: UserCardType
                                            .activeChat, // Correct type
                                        // ✅ Connect tap to navigateToActiveChat
                                        onMessageTap: () => viewModel
                                            .navigateToActiveChat(chatRequest),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to format the timestamp
  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('d MMM').format(dateTime); // e.g., 15 Oct
    }
  }

  Widget _buildAvailabilityCard(
      double width, double height, VolunteerHomeViewModel viewModel) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
        child: Container(
          width: width,
          padding: EdgeInsets.all(width * 0.05),
          decoration: BoxDecoration(
            color: viewModel.isAvailable
                ? const Color(0xFFE8F5E9).withAlpha(150) // Light green
                : AppColors.secondaryVeryLight.withAlpha(90),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
                color:
                    viewModel.isAvailable ? Colors.green : AppColors.secondary,
                width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: viewModel.isAvailable
                      ? Colors.green.withAlpha(50)
                      : AppColors.secondary.withAlpha(50),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  viewModel.isAvailable ? Icons.sensors : Icons.sensors_off,
                  color: viewModel.isAvailable
                      ? Colors.green[700]
                      : AppColors.secondary,
                  size: 28,
                ),
              ),
              SizedBox(width: width * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Availability Status",
                      style: GoogleFonts.crimsonPro(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryVeryDark,
                      ),
                    ),
                    Text(
                      viewModel.isAvailable
                          ? "Online - Ready for chats"
                          : "Offline - Away",
                      style: GoogleFonts.crimsonPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: viewModel.isAvailable
                            ? Colors.green[800]
                            : AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: viewModel.isAvailable,
                activeThumbColor: Colors.green,
                inactiveThumbColor: AppColors.secondary,
                onChanged: (val) {
                  viewModel.toggleAvailability(val);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
