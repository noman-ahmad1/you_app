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
            // Chat list placeholder
            Expanded(
              child: Center(
                child: Text(
                  'Dodo is resting right now...',
                  style: GoogleFonts.crimsonPro(
                    fontSize: 18,
                    color: AppColors.secondary.withAlpha(200),
                  ),
                ),
              ),
            ),

            // Input field
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
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
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
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
