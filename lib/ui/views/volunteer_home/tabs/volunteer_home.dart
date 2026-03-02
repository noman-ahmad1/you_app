import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:stacked/stacked.dart';
import 'package:you_app/models/chat_request_model.dart'; // Import ChatRequest
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/views/volunteer_home/user_card.dart';
import 'package:you_app/ui/views/volunteer_home/volunteer_home_viewmodel.dart';

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
            title: 'Incoming Requests',
            imageAssetPath: AppConstants.logo,
            onMenuPressed: () {},
          ),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Status:',
                          style: GoogleFonts.crimsonPro(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryVeryDark),
                        ),
                        Row(
                          children: [
                            Text(
                              viewModel.availabilityStatusString,
                              style: GoogleFonts.crimsonPro(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: viewModel.isAvailable
                                      ? Colors.green
                                      : Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            CupertinoSwitch(
                              // Or use Switch() for Material style
                              value: viewModel.isAvailable,
                              onChanged: viewModel.toggleAvailability,
                              activeColor: AppColors.secondary,
                            ),
                          ],
                        ),
                      ],
                    ),
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
                          ? const Center(
                              child: CircularProgressIndicator(
                              color: AppColors.secondary,
                            ))
                          : viewModel.activeChats.isEmpty
                              ? Center(
                                  child: Text(
                                  "No active chats.",
                                  style: GoogleFonts.crimsonPro(fontSize: 20),
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
                                                AppConstants.avatar,
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
}
