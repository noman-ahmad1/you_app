import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/models/chat_request_model.dart'; // Import ChatRequest model
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/views/home/home_viewmodel.dart';
import 'package:you_app/ui/views/home/volunteer_card.dart';

// This is correct: ViewModelWidget uses the parent's HomeViewModel
class VolunteersScreen extends ViewModelWidget<HomeViewModel> {
  const VolunteersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, HomeViewModel viewModel) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppConstants.background),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              TopBar(
                title: 'Volunteers',
                imageAssetPath: AppConstants.back,
                color: AppColors.secondary,
                onMenuPressed: () {},
              ),
              Expanded(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    // ✅ Delegate content building to a helper method
                    child: _buildContent(context, viewModel),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the main content based on the ViewModel's state.
  Widget _buildContent(BuildContext context, HomeViewModel viewModel) {
    // Show loading indicator only during the initial fetch *before* any interaction
    if (viewModel.isBusy &&
        !viewModel.hasActiveInteraction &&
        viewModel.volunteers.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(
        color: AppColors.secondary,
      ));
    }
    // Check for active chat first
    else if (viewModel.activeChatRequest != null) {
      return _buildActiveChatCard(
          context, viewModel, viewModel.activeChatRequest!);
    }
    // Then check for pending request
    else if (viewModel.pendingRequest != null) {
      return _buildPendingRequestCard(
          context, viewModel, viewModel.pendingRequest!);
    } else if (viewModel.isBusy) {
      // Show loading indicator specifically when fetching volunteers (and no active interaction)
      return const Center(
          child: CircularProgressIndicator(
        color: AppColors.secondary,
      ));
    }
    // Otherwise, show the list of available volunteers
    else {
      return _buildVolunteerList(context, viewModel);
    }
  }

  /// Widget to show when a chat is active.
  Widget _buildActiveChatCard(
      BuildContext context, HomeViewModel viewModel, ChatRequest request) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.secondaryVeryLight.withAlpha(50),
              border: Border.all(color: AppColors.secondary, width: 2),
              borderRadius: BorderRadius.circular(23),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(AppConstants.done, color: Colors.green),
                Space.verticalSpaceSmall(context),
                Text(
                  "You are connected!",
                  style: GoogleFonts.crimsonPro(
                      color: AppColors.secondary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Space.verticalSpaceTiny(context),
                Text(
                  "Your request was accepted. You can now chat with the volunteer.",
                  style: GoogleFonts.crimsonPro(
                      fontSize: 16, color: AppColors.primaryVeryDark),
                  textAlign: TextAlign.center,
                ),
                Space.verticalSpaceMedium(context),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondaryVeryLight.withAlpha(50),
                    border: Border.all(color: AppColors.secondary, width: 2),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    icon: Image.asset(AppConstants.activeChat,
                        height: 30, width: 30),
                    label: const Text(
                      "Go to Chat",
                      style: TextStyle(fontSize: 22),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.secondaryVeryLight.withAlpha(100),
                      foregroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                    ),
                    onPressed: viewModel.navigateToActiveChat,
                  ),
                ),
                Space.verticalSpaceSmall(context),
                Text(
                  "This chat will end automatically after 24 hours.",
                  style:
                      TextStyle(color: AppColors.primaryVeryDark, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget to show when a request is pending.
  Widget _buildPendingRequestCard(
      BuildContext context, HomeViewModel viewModel, ChatRequest request) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondaryVeryLight.withAlpha(50),
          border: Border.all(color: AppColors.secondary, width: 2),
          borderRadius: BorderRadius.circular(23),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AppConstants.pending, color: AppColors.primaryVeryDark),
            Space.verticalSpaceSmall(context),
            Text(
              "Request Sent",
              style: GoogleFonts.crimsonPro(
                  color: AppColors.secondary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Space.verticalSpaceVTiny(context),
            Text(
              "Waiting for the volunteer to accept your request...",
              style: GoogleFonts.crimsonPro(
                  fontSize: 18, color: AppColors.primaryVeryDark),
              textAlign: TextAlign.center,
            ),
            Space.verticalSpaceMedium(context),
            OutlinedButton(
              onPressed: viewModel.isBusy
                  ? null
                  : () => viewModel.cancelRequest(request),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: viewModel.isBusy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.secondary,
                      ))
                  : const Text(
                      "Cancel Request",
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget to show the list of available volunteers.
  Widget _buildVolunteerList(BuildContext context, HomeViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Hello ${viewModel.currentUserName},',
          style: GoogleFonts.crimsonPro(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary),
        ),
        Text(
          'Our volunteers are here to listen.',
          textAlign: TextAlign.center,
          style: GoogleFonts.crimsonPro(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryVeryDark),
        ),
        Space.verticalSpaceTiny(context),
        Expanded(
          child: viewModel.volunteers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: viewModel.volunteers.length,
                  itemBuilder: (context, index) {
                    final volunteer = viewModel.volunteers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 7.0),
                      child: VolunteerCard(
                        type: VolunteerCardType.availableChat, // Correct type
                        username: volunteer.fullName,
                        avatarPath:
                            // volunteer.profilePictureUrl ??
                            AppConstants.avatar,
                        rating: 4, // Placeholder
                        categories: const ['Anxiety', 'ADHD'], // Placeholder
                        onActionTap: () => viewModel.sendChatRequest(volunteer),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No volunteers are available right now.\nPlease check back later.',
        textAlign: TextAlign.center,
        style: GoogleFonts.crimsonPro(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.secondary.withOpacity(0.7)),
      ),
    );
  }
}
