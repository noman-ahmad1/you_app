import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // For formatting time ago
import 'package:stacked/stacked.dart';
import 'package:you_app/models/chat_request_model.dart'; // Import model
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/views/volunteer_home/user_card.dart';
import 'package:you_app/ui/views/volunteer_home/volunteer_home_viewmodel.dart';

// Assuming this is a StackedView for a standalone screen displaying PENDING requests.
class RequestScreen extends StackedView<VolunteerHomeViewModel> {
  const RequestScreen({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    VolunteerHomeViewModel viewModel,
    Widget? child,
  ) {
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
                  children: [
                    Text(
                      'Approve request to chat',
                      style: GoogleFonts.crimsonPro(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary),
                    ),
                    Expanded(
                      // ✅ Use the correct list: pendingRequests
                      child: viewModel.isBusyRequests &&
                              viewModel.pendingRequests.isEmpty
                          ? const Center(
                              child: CircularProgressIndicator(
                              color: AppColors.secondary,
                            ))
                          : viewModel.pendingRequests
                                  .isEmpty // ✅ Use pendingRequests
                              ? Center(
                                  child: Text(
                                  "No pending requests.",
                                  style: GoogleFonts.crimsonPro(fontSize: 20),
                                ))
                              : ListView.builder(
                                  // ✅ Use pendingRequests
                                  itemCount: viewModel.pendingRequests.length,
                                  itemBuilder: (context, index) {
                                    // ✅ Use pendingRequests
                                    final request =
                                        viewModel.pendingRequests[index];
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 7.0),
                                      child: UserCard(
                                        username: request.requesterName,
                                        avatarPath:
                                            request.requesterAvatarUrl ??
                                                AppConstants.avatar,
                                        lastMessage: "Wants to connect",
                                        timeAgo:
                                            _formatTimeAgo(request.createdAt),
                                        type: UserCardType.request,
                                        onAcceptTap: () =>
                                            viewModel.acceptRequest(request),
                                        onRejectTap: () =>
                                            viewModel.declineRequest(request),
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

  String _formatTimeAgo(DateTime? dateTime) {
    // ... (your existing helper function is correct)
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

  @override
  VolunteerHomeViewModel viewModelBuilder(BuildContext context) =>
      VolunteerHomeViewModel();

  @override
  void onViewModelReady(VolunteerHomeViewModel viewModel) {
    // ViewModel constructor now handles starting the listeners.
    // You could potentially remove this if the constructor always runs,
    // but keeping it here ensures listeners are active if the view rebuilds.
    viewModel.listenForRequests();
    // viewModel.listenForActiveChats(); // Good to keep both active
  }
}
