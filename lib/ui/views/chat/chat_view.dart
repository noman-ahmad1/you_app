import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/models/chat_messaage_model.dart';
import 'package:you_app/ui/common/animation_decoder.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/moderation_service.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/shared/topbar.dart';

import 'chat_viewmodel.dart';
import "package:you_app/ui/shared/custom_lottie_loader.dart";

class ChatView extends StackedView<ChatViewModel> {
  final String volunteerId;
  final String volunteerName;
  final String requestId;
  const ChatView({
    Key? key,
    required this.volunteerId,
    required this.volunteerName,
    required this.requestId,
  }) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    ChatViewModel viewModel,
    Widget? child,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    return Scaffold(
        // appBar: TopBar(
        //   title: viewModel.volunteerName,
        //   imageAssetPath: AppConstants.back,
        //   color: AppColors.secondary,
        //   trailingAction: Container(
        //     height: height * 0.07,
        //     width: width * 0.07,
        //     child: InkWell(
        //       onTap: () async {
        //         print("ATTEMPTING DELETE AS USER: ${viewModel.currentUserId}");
        //         await viewModel.deleteChat();
        //       },
        //       child: Image.asset(AppConstants.delete),
        //     ),
        //   ),
        //   onBackPressed: () {
        //     viewModel.back();
        //   },
        // ),
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
          TopBar(
            leadingIconAsset: AppConstants.back, // Your 'Y' logo asset
            onLeadingPressed: () {
              viewModel.back();
            },
            title: viewModel.volunteerName.trim().split(' ').first,
            trailingActions: [
              if (viewModel.isCurrentUserVolunteer)
                InkWell(
                  onTap: () {
                    viewModel.escalate();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.red.withAlpha(80)),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 24,
                      color: AppColors.red,
                    ),
                  ),
                ),
              InkWell(
                onTap: () {
                  viewModel.endChat();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.primaryVeryDark.withAlpha(50)),
                  ),
                  child: Image.asset(AppConstants.cancel,
                      height: 24, width: 24, color: AppColors.primaryVeryDark),
                ),
              ),
            ],
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: viewModel.isBusy
                      ? const CustomLottieLoader(fullScreen: true)
                      : viewModel.messages.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              reverse: true, // Shows latest messages at the bottom
                              // Bottom padding leaves room for the floating input
                              // so the newest message isn't hidden behind it.
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                              itemCount: viewModel.messages.length,
                              itemBuilder: (context, index) {
                                final message = viewModel.messages[index];
                                final isMe =
                                    message.senderId == viewModel.currentUserId;
                                return _MessageBubble(
                                    message: message, isMe: isMe);
                              },
                            ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _MessageInputField(),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Lottie.asset(
        AppConstants.empty,
        decoder: customDecoder,
        width: 200,
        height: 200,
      ),
      // Text(
      //   'No messages yet. Start the conversation!',
      //   style: TextStyle(
      //     color: Colors.grey[600],
      //     fontSize: 16,
      //   ),
      // ),
    );
  }

  @override
  ChatViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      ChatViewModel(
        volunteerId: volunteerId,
        volunteerName: volunteerName,
        requestId: requestId,
      );
}

class _MessageInputField extends ViewModelWidget<ChatViewModel> {
  const _MessageInputField({super.key});

  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return Container(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Stack(
            children: [
              TextField(
                controller: viewModel.messageController,
                // --- Properties for Multiline Expansion ---
                keyboardType: TextInputType.multiline,
                maxLines:
                    5, // Restrict maximum lines to prevent infinite expansion
                minLines: 1,
                // -----------------------------------------
                cursorColor: AppColors.secondary,
                style: GoogleFonts.crimsonPro(
                  color: AppColors.secondary,
                ),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: GoogleFonts.crimsonPro(
                    color: AppColors.secondary.withAlpha(150),
                  ),
                  filled: true,
                  fillColor: AppColors.secondaryVeryLight.withAlpha(240),
                  contentPadding: const EdgeInsets.fromLTRB(
                      16, 16, 60, 16), // Increased right padding
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(
                      color: AppColors.secondary,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(
                      color: AppColors.secondary,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(
                      color: AppColors.secondary,
                      width: 2,
                    ),
                  ),
                ),
                onSubmitted: (_) => viewModel.sendMessage(),
              ),
              Positioned(
                right: 8.0,
                bottom: 5.5,
                child: GestureDetector(
                  onTap: viewModel.sendMessage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.secondaryVeryLight.withAlpha(75),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.secondary,
                        width: 2,
                      ),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    // Blur any shared contact info (phone / social handle / email / URL).
    final displayText = locator<ModerationService>().maskPii(message.text);
    final wasMasked = displayText != message.text;
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            gradient: isMe
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.secondary, AppColors.secondaryLight],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withAlpha(235),
                      AppColors.lightPurple.withAlpha(150),
                    ],
                  ),
            border: isMe
                ? null
                : Border.all(color: AppColors.primary.withAlpha(90), width: 1),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(22),
              topRight: const Radius.circular(22),
              bottomLeft:
                  isMe ? const Radius.circular(22) : const Radius.circular(6),
              bottomRight:
                  isMe ? const Radius.circular(6) : const Radius.circular(22),
            ),
            boxShadow: [
              BoxShadow(
                color: isMe
                    ? AppColors.secondary.withAlpha(64)
                    : Colors.black.withAlpha(18),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayText,
                style: GoogleFonts.crimsonPro(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isMe ? Colors.white : AppColors.primaryVeryDark,
                ),
              ),
              if (wasMasked) ...[
                const SizedBox(height: 4),
                Text(
                  'Contact info hidden for safety',
                  style: GoogleFonts.crimsonPro(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: isMe
                        ? Colors.white.withAlpha(200)
                        : AppColors.primaryVeryDark.withAlpha(160),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
