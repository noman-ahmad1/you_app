import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/shared/topbar.dart';

import 'community_chat_viewmodel.dart';

class CommunityChatView extends StackedView<CommunityChatViewModel> {
  final String communityId;
  final String communityName;

  const CommunityChatView({
    Key? key,
    required this.communityId,
    required this.communityName,
  }) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    CommunityChatViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      appBar: TopBar(
        title: viewModel.communityName, // Shows the community name
        imageAssetPath: AppConstants.back,
        color: AppColors.secondary,
        onBackPressed: () {
          viewModel.back();
        },
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.background),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: viewModel.isBusy
                  ? const Center(
                      child: CircularProgressIndicator(
                      color: AppColors.secondary,
                    ))
                  : viewModel.messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          reverse: true, // Shows latest messages at the bottom
                          padding: const EdgeInsets.all(12),
                          itemCount: viewModel.messages.length,
                          itemBuilder: (context, index) {
                            final messageData = viewModel.messages[index];
                            final isMe = messageData['senderId'] ==
                                viewModel.currentUserId;

                            return _CommunityMessageBubble(
                              messageData: messageData,
                              isMe: isMe,
                            );
                          },
                        ),
            ),
            const _MessageInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'Be the first to share in this community!',
        style: GoogleFonts.crimsonPro(
          color: AppColors.primaryVeryDark.withAlpha(150),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  CommunityChatViewModel viewModelBuilder(BuildContext context) =>
      CommunityChatViewModel(
        communityId: communityId,
        communityName: communityName,
      );
}

// -------------------------------------------------------------------
// WIDGETS
// -------------------------------------------------------------------

class _MessageInputField extends ViewModelWidget<CommunityChatViewModel> {
  const _MessageInputField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, CommunityChatViewModel viewModel) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: TextField(
          controller: viewModel.messageController,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          cursorColor: AppColors.secondary,
          style: GoogleFonts.crimsonPro(
            color: AppColors.secondary,
          ),
          decoration: InputDecoration(
            hintText: "Share with the community...",
            hintStyle: GoogleFonts.crimsonPro(
              color: AppColors.secondary.withAlpha(150),
            ),
            filled: true,
            fillColor: AppColors.secondaryVeryLight.withAlpha(75),
            contentPadding: const EdgeInsets.fromLTRB(16, 16, 60, 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide:
                  const BorderSide(color: AppColors.secondary, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide:
                  const BorderSide(color: AppColors.secondary, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide:
                  const BorderSide(color: AppColors.secondary, width: 2),
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: viewModel.sendMessage,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondaryVeryLight.withAlpha(75),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.secondary, width: 2),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    AppConstants.send,
                    color: AppColors.secondary,
                    width: 25,
                  ),
                ),
              ),
            ),
          ),
          onSubmitted: (_) => viewModel.sendMessage(),
        ),
      ),
    );
  }
}

class _CommunityMessageBubble extends StatelessWidget {
  final Map<String, dynamic> messageData;
  final bool isMe;

  const _CommunityMessageBubble({
    required this.messageData,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final text = messageData['text'] ?? '';
    final senderName = messageData['senderName'] ?? 'Anonymous';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Show Sender Name for incoming messages (because it's a group chat)
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 14, bottom: 4),
              child: Text(
                senderName,
                style: GoogleFonts.crimsonPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryVeryDark.withAlpha(200),
                ),
              ),
            ),
          // The actual message bubble
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.secondaryVeryLight.withAlpha(75)
                      : AppColors.lightPurple.withAlpha(75),
                  border: Border.all(
                    color: isMe ? AppColors.secondary : AppColors.lightPurple,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: isMe
                        ? const Radius.circular(20)
                        : const Radius.circular(5),
                    bottomRight: isMe
                        ? const Radius.circular(5)
                        : const Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  text,
                  style: GoogleFonts.crimsonPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isMe ? AppColors.secondary : AppColors.lightPurple,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
