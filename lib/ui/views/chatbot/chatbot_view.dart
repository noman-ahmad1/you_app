import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/topbar.dart';

import 'chatbot_viewmodel.dart';

class ChatbotView extends StackedView<ChatbotViewModel> {
  const ChatbotView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    ChatbotViewModel viewModel,
    Widget? child,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;

    return Scaffold(
      appBar: TopBar(
        title: 'Dodo',
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
            // Chat list
            // Expanded(
            //   child: ListView.builder(
            //     padding: const EdgeInsets.all(12),
            //     controller: viewModel.scrollController,
            //     itemCount: viewModel.messages.length,
            //     itemBuilder: (context, index) {
            //       final msg = viewModel.messages[index];
            //       final isUser = msg.isUser;

            //       return Align(
            //         alignment:
            //             isUser ? Alignment.centerRight : Alignment.centerLeft,
            //         child: Padding(
            //           padding: const EdgeInsets.symmetric(vertical: 6),
            //           child: ClipRRect(
            //             borderRadius: BorderRadius.only(
            //               topLeft: const Radius.circular(20),
            //               topRight: const Radius.circular(20),
            //               bottomLeft: isUser
            //                   ? const Radius.circular(20)
            //                   : const Radius.circular(5),
            //               bottomRight: isUser
            //                   ? const Radius.circular(5)
            //                   : const Radius.circular(20),
            //             ),
            //             child: BackdropFilter(
            //               filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            //               child: Container(
            //                 padding: EdgeInsets.all(width * 0.03),
            //                 decoration: BoxDecoration(
            //                   color: isUser
            //                       ? AppColors.secondary.withAlpha(180)
            //                       : AppColors.secondaryVeryLight.withAlpha(140),
            //                   border: Border.all(
            //                     color: AppColors.secondary,
            //                     width: 1.5,
            //                   ),
            //                   borderRadius: BorderRadius.only(
            //                     topLeft: const Radius.circular(20),
            //                     topRight: const Radius.circular(20),
            //                     bottomLeft: isUser
            //                         ? const Radius.circular(20)
            //                         : const Radius.circular(5),
            //                     bottomRight: isUser
            //                         ? const Radius.circular(5)
            //                         : const Radius.circular(20),
            //                   ),
            //                   boxShadow: [
            //                     BoxShadow(
            //                       color: Colors.black.withAlpha(25),
            //                       blurRadius: 12,
            //                       offset: const Offset(0, 4),
            //                     ),
            //                   ],
            //                 ),
            //                 child: Text(
            //                   msg.text,
            //                   style: GoogleFonts.crimsonPro(
            //                     fontSize: 15,
            //                     fontWeight: FontWeight.w500,
            //                     color:
            //                         isUser ? Colors.white : AppColors.secondary,
            //                   ),
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ),
            //       );
            //     },
            //   ),
            // ),

            // Input field
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        // controller: viewModel.inputController,
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
                              AppColors.secondaryVeryLight.withAlpha(120),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        // onSubmitted: (_) => viewModel.sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      // onTap: viewModel.sendMessage,
                      child: CircleAvatar(
                        backgroundColor: AppColors.secondary,
                        child: const Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  ],
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
