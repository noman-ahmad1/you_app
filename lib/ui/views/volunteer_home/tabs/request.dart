import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // For formatting time ago
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/models/chat_request_model.dart'; // Import model
import 'package:you_app/ui/common/animation_decoder.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/views/volunteer_home/user_card.dart';
import 'package:you_app/ui/views/volunteer_home/volunteer_home_viewmodel.dart';
import "package:you_app/ui/shared/custom_lottie_loader.dart";

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
            leadingIconAsset: AppConstants.logo, // Your 'Y' logo asset
            onLeadingPressed: () {
              // Handle tap
            },
            title: 'Requests',
            subtitle: DateFormat('EEEE, MMMM d').format(DateTime.now()),
            trailingActions: [
              // Icon 1 (e.g., Notifications)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  InkWell(
                    onTap: () {
                      viewModel.markAllNotificationsAsRead();
                      Scaffold.of(context).openDrawer();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primaryVeryDark.withAlpha(50)),
                      ),
                      child: Image.asset(AppConstants.notification,
                          width: 24,
                          height: 24,
                          color: AppColors.primaryVeryDark),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity:
                            viewModel.unreadNotificationsCount > 0 ? 1.0 : 0.0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '${viewModel.unreadNotificationsCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
                              child: CustomLottieLoader()
                              )
                          : viewModel.pendingRequests
                                  .isEmpty // ✅ Use pendingRequests
                              ? Center(
                                  child: Column(
                                  children: [
                                    Lottie.asset(
                                      AppConstants.empty,
                                      decoder: customDecoder,
                                      width: 200,
                                      height: 200,
                                    ),
                                    Text(
                                      "No pending requests.",
                                      style:
                                          GoogleFonts.crimsonPro(fontSize: 20),
                                    ),
                                  ],
                                ))
                              : ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 120),
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
                                                AppConstants.avatarBinary,
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
