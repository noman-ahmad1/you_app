import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/shared/floating_composer_layout.dart';
import 'package:you_app/ui/shared/topbar.dart';

import 'chatbot_viewmodel.dart';
import "package:you_app/ui/shared/custom_lottie_loader.dart";

class ChatbotView extends StackedView<ChatbotViewModel> {
  const ChatbotView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    ChatbotViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.pinkBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            TopBar(
              isDodo: false,
              leadingIconAsset: AppConstants.back, // Your 'Y' logo asset
              onLeadingPressed: () {
                Navigator.pop(context);
              },
              title: 'Dodo',
              titleColor: AppColors.secondary,
              iconColor: AppColors.secondary,
              backgroundColor: AppColors.lightPink,
              trailingActions: [],
            ),
            Expanded(
              child: FloatingComposerLayout(
                composer: const _MessageInputField(),
                listBuilder: (context, bottomInset) => ListView.builder(
                  reverse: true,
                  // Bottom padding tracks the floating input's height so the
                  // newest message stays visible as it grows to multiple lines.
                  padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset),
                  // When Dodo is replying, show a typing bubble as the
                  // bottom-most item (index 0 in a reversed list) so it sits
                  // in-flow with messages and never overlaps the reply.
                  itemCount:
                      viewModel.messages.length + (viewModel.isBusy ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (viewModel.isBusy && index == 0) {
                      return const _TypingBubble();
                    }
                    final msgIndex = viewModel.isBusy ? index - 1 : index;
                    final msg = viewModel
                        .messages[viewModel.messages.length - 1 - msgIndex];
                    final isMe = msg['isMe'] == 'true';
                    return _MessageBubble(text: msg['text'] ?? '', isMe: isMe);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  ChatbotViewModel viewModelBuilder(BuildContext context) => ChatbotViewModel();
}

class _MessageInputField extends ViewModelWidget<ChatbotViewModel> {
  const _MessageInputField();

  @override
  Widget build(BuildContext context, ChatbotViewModel viewModel) {
    return Container(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 10.0),
          child: Stack(
            children: [
              TextField(
                controller: viewModel.messageController,
                keyboardType: TextInputType.multiline,
                maxLines: 5,
                minLines: 1,
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
                  fillColor:
                      const Color.fromARGB(255, 227, 177, 203).withAlpha(240),
                  contentPadding: const EdgeInsets.fromLTRB(16, 16, 60, 16),
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
  final String text;
  final bool isMe;

  const _MessageBubble({required this.text, required this.isMe});

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
                      AppColors.lightPink.withAlpha(160),
                    ],
                  ),
            border: isMe
                ? null
                : Border.all(
                    color: AppColors.secondaryVeryLight.withAlpha(120),
                    width: 1),
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
          child: Text(
            text,
            style: GoogleFonts.crimsonPro(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isMe ? Colors.white : AppColors.primaryVeryDark,
            ),
          ),
        ),
      ],
    );
  }
}

/// In-list "Dodo is typing…" bubble, styled like a Dodo (other) message so it
/// flows with the conversation and is replaced cleanly by the reply.
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha(235),
                AppColors.lightPink.withAlpha(160),
              ],
            ),
            border: Border.all(
                color: AppColors.secondaryVeryLight.withAlpha(120), width: 1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Dodo is typing',
                style: GoogleFonts.crimsonPro(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppColors.primaryVeryDark.withAlpha(190),
                ),
              ),
              const CustomLottieLoader(
                width: 34,
                height: 34,
                loaderWidth: 120,
                loaderHeight: 120,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
