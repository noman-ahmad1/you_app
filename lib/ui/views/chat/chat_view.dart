import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/models/chat_messaage_model.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/shared/topbar.dart';

import 'chat_viewmodel.dart';

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
        appBar: TopBar(
          title: viewModel.volunteerName,
          imageAssetPath: AppConstants.back,
          color: AppColors.secondary,
          trailingAction: Container(
            height: height * 0.07,
            width: width * 0.07,
            child: InkWell(
              onTap: () async {
                print("ATTEMPTING DELETE AS USER: ${viewModel.currentUserId}");
                await viewModel.deleteChat();
              },
              child: Image.asset(AppConstants.delete),
            ),
          ),
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
                            reverse:
                                true, // Shows latest messages at the bottom
                            padding: const EdgeInsets.all(12),
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
              _MessageInputField(),
            ],
          ),
        ));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No messages yet. Start the conversation!',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 16,
        ),
      ),
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

  @override
  void onViewModelReady(ChatViewModel viewModel) {
    // Start listening for messages as soon as the view is ready.
    viewModel.listenToMessages();
  }
}

class _MessageInputField extends ViewModelWidget<ChatViewModel> {
  const _MessageInputField({super.key});

  @override
  Widget build(BuildContext context, ChatViewModel viewModel) {
    return Container(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: TextField(
            controller: viewModel.messageController,
            // --- Properties for Multiline Expansion ---
            keyboardType: TextInputType.multiline,
            maxLines: null, // Allows the TextField to grow vertically
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
              fillColor: AppColors.secondaryVeryLight.withAlpha(75),
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
                borderRadius: BorderRadius.circular(50),
                borderSide: const BorderSide(
                  color: AppColors.secondary,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: const BorderSide(
                  color: AppColors.secondary,
                  width: 2,
                ),
              ),
              // --- THIS IS THE KEY CHANGE ---
              suffixIcon: Padding(
                padding: const EdgeInsets.only(
                    right: 8.0), // Adds some space from the edge
                child: GestureDetector(
                  onTap: viewModel.sendMessage,
                  child: Container(
                    // Removed fixed height/width to let the icon size itself
                    decoration: BoxDecoration(
                      color: AppColors.secondaryVeryLight.withAlpha(75),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.secondary,
                        width: 2,
                      ),
                    ),
                    padding:
                        const EdgeInsets.all(8), // Padding inside the circle
                    child: Image.asset(
                      AppConstants.send,
                      color: AppColors.secondary,
                      width: 25, // Use a fixed size for the icon
                    ),
                  ),
                ),
              ),
              // -----------------------------
            ),
            onSubmitted: (_) => viewModel.sendMessage(),
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
              bottomLeft:
                  isMe ? const Radius.circular(20) : const Radius.circular(5),
              bottomRight:
                  isMe ? const Radius.circular(5) : const Radius.circular(20),
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
            message.text,
            style: GoogleFonts.crimsonPro(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isMe ? AppColors.secondary : AppColors.lightPurple,
            ),
          ),
        ),
      ],
    );
  }
}
