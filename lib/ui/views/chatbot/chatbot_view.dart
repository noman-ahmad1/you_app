import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/animation_decoder.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
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
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ListView.builder(
                      reverse: true,
                      // Bottom padding leaves room for the floating input.
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                      itemCount: viewModel.messages.length,
                      itemBuilder: (context, index) {
                        final msg = viewModel
                            .messages[viewModel.messages.length - 1 - index];
                        final isMe = msg['isMe'] == 'true';
                        return _MessageBubble(
                            text: msg['text'] ?? '', isMe: isMe);
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Loading Indicator for Dodo thinking
                        if (viewModel.isBusy)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 8, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  "Dodo is typing...",
                                  style: GoogleFonts.crimsonPro(
                                    color: AppColors.primaryVeryDark,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const CustomLottieLoader(
                                  width: 70,
                                  height: 70,
                                  loaderWidth: 200,
                                  loaderHeight: 200,
                                )
                              ],
                            ),
                          ),
                        // Input field identical to ChatView
                        const _MessageInputField(),
                      ],
                    ),
                  ),
                ],
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
  const _MessageInputField({super.key});

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
            color: isMe
                ? AppColors.secondaryVeryLight.withAlpha(75)
                : AppColors.primary.withAlpha(75),
            border: Border.all(
              color: isMe ? AppColors.secondary : AppColors.primaryVeryDark,
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
            text,
            style: GoogleFonts.crimsonPro(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isMe ? AppColors.secondary : AppColors.primaryVeryDark,
            ),
          ),
        ),
      ],
    );
  }
}
