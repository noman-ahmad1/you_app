import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/models/chat_request_model.dart'; // Import ChatRequest model
import 'package:you_app/ui/common/animation_decoder.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/views/home/home_viewmodel.dart';
import 'package:you_app/ui/views/home/widgets/volunteer_card.dart';
import 'package:you_app/ui/views/chat/widgets/review_dialog.dart';
import "package:you_app/ui/shared/custom_lottie_loader.dart";

// This is correct: ViewModelWidget uses the parent's HomeViewModel
class VolunteersScreen extends ViewModelWidget<HomeViewModel> {
  const VolunteersScreen({super.key});

  @override
  Widget build(BuildContext context, HomeViewModel viewModel) {
    // When the user lands on this tab and has an unreviewed, just-completed
    // chat, prompt for a review over the volunteer list. Submitting or skipping
    // returns them to the normal list.
    _maybeShowReviewDialog(context, viewModel);
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
                leadingIconAsset: AppConstants.logoRound, // Your 'Y' logo asset
                onLeadingPressed: () {
                  // Handle tap
                },
                title: 'Listeners',
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
                              color: AppColors.primaryVeryDark,
                              width: 24,
                              height: 24),
                        ),
                      ),
                      Positioned(
                        right: -4,
                        top: -4,
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: viewModel.unreadNotificationsCount > 0
                                ? 1.0
                                : 0.0,
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
                  // Icon 2 (e.g., Profile/Flower)
                  // InkWell(
                  //   onTap: () {},
                  //   child: Container(
                  //     padding: const EdgeInsets.all(4),
                  //     decoration: BoxDecoration(
                  //       shape: BoxShape.circle,
                  //       border: Border.all(
                  //           color: AppColors.primaryVeryDark.withAlpha(50)),
                  //     ),
                  //     child: Image.asset('assets/images/avatar.png',
                  //         width: 24, height: 24),
                  //   ),
                  // ),
                ],
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

  /// Opens the post-chat review dialog once, when this tab is visible and the
  /// view model has flagged a completed-but-unreviewed chat. The view model's
  /// [HomeViewModel.isReviewDialogOpen] guard keeps rebuilds from stacking
  /// dialogs; resolving the dialog clears the prompt and reveals the list.
  void _maybeShowReviewDialog(BuildContext context, HomeViewModel viewModel) {
    if (viewModel.currentIndex != 2 ||
        viewModel.pendingReviewRequest == null ||
        viewModel.isReviewDialogOpen) {
      return;
    }
    viewModel.markReviewDialogOpen();
    final volunteerName = viewModel.reviewVolunteerName;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ReviewDialog(volunteerName: volunteerName),
      );
      if (result != null) {
        final rating = (result['rating'] as num).toDouble();
        final comment = result['comment'] as String? ?? '';
        await viewModel.submitVolunteerReview(rating, comment);
      } else {
        await viewModel.skipVolunteerReview();
      }
    });
  }

  /// Builds the main content based on the ViewModel's state.
  Widget _buildContent(BuildContext context, HomeViewModel viewModel) {
    // Show loading indicator only during the initial fetch *before* any interaction
    if (viewModel.isBusy &&
        !viewModel.hasActiveInteraction &&
        viewModel.volunteers.isEmpty) {
      return const Center(
        child: CustomLottieLoader(),
      );
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
        child: CustomLottieLoader(),
      );
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
              color: AppColors.background.withAlpha(200),
              border: Border.all(color: AppColors.background, width: 2),
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
                Lottie.asset(
                  AppConstants.done2,
                  decoder: customDecoder,
                  width: 150,
                  height: 150,
                ),
                // Image.asset(AppConstants.done, color: Colors.green),
                Space.verticalSpaceTiny(context),
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
                    // border: Border.all(
                    //     color: AppColors.secondaryVeryLight, width: 2),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      // BoxShadow(
                      //   color: Colors.black.withAlpha(50),
                      //   blurRadius: 20,
                      //   offset: const Offset(0, 4),
                      // ),
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
                      backgroundColor: AppColors.secondaryVeryLight,
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
          color: AppColors.background.withAlpha(200),
          border: Border.all(color: AppColors.background, width: 2),
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
            Lottie.asset(
              AppConstants.pending2,
              decoder: customDecoder,
              width: 150,
              height: 150,
            ),
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
                  ? const CustomLottieLoader(
                      width: 50,
                      height: 50,
                      loaderWidth: 200,
                      loaderHeight: 200,
                    )
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
  ///
  /// A [CustomScrollView] so the tag filters can PIN to the top: the marketing
  /// header scrolls away, the chips stay reachable while the user scrolls a long
  /// list of listeners. Mirrors the journal screen's `_FilterBarHeaderDelegate`.
  Widget _buildVolunteerList(BuildContext context, HomeViewModel viewModel) {
    // A SliverPersistentHeader needs a FIXED extent, but a FilterChip sizes
    // itself. 48px is the chip's interactive height (kMinInteractiveDimension);
    // +12 for the breathing room the old Column had below it.
    const double chipsExtent = 48 + 12;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOU\'RE NOT ALONE',
                  style: GoogleFonts.crimsonPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.secondary,
                  ),
                ),
                Space.verticalSpaceVTiny(context),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.crimsonPro(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryVeryDark,
                    ),
                    children: const [
                      TextSpan(text: 'Talk to someone '),
                      TextSpan(
                        text: 'who truly cares.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Space.verticalSpaceTiny(context),
                Text(
                  'Pairing is exclusive for 24 hours — to keep your space focused.',
                  style: GoogleFonts.crimsonPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[700],
                  ),
                ),
                Space.verticalSpaceVTiny(context),
              ],
            ),
          ),
        ),
        // --- Tags filter — PINNED ---
        SliverPersistentHeader(
          pinned: true,
          delegate: _TagFilterHeaderDelegate(
            extent: chipsExtent,
            selectedTags: viewModel.selectedFilterTags,
            onTagTap: viewModel.toggleFilterTag,
          ),
        ),
        if (viewModel.filteredVolunteers.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final volunteer = viewModel.filteredVolunteers[index];
                final volunteerTags = viewModel.volunteerTags[volunteer.uid];
                final volunteerRating =
                    viewModel.volunteerRatings[volunteer.uid] ?? 4.0;
                final displayTags =
                    (volunteerTags != null && volunteerTags.isNotEmpty)
                        ? volunteerTags
                        : const ['Mental Health', 'Support'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7.0),
                  child: VolunteerCard(
                    type: VolunteerCardType.availableChat,
                    username: volunteer.fullName,
                    avatarPath:
                        volunteer.profilePictureUrl ?? volunteer.defaultAvatar,
                    rating: volunteerRating.round(),
                    categories: displayTags,
                    onActionTap: () => viewModel.sendChatRequest(volunteer),
                  ),
                );
              },
              childCount: viewModel.filteredVolunteers.length,
            ),
          ),
        // Clears the floating bottom nav bar.
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Lottie.asset(
            AppConstants.searchVolunteer,
            decoder: customDecoder,
            width: 200,
            height: 200,
          ),
          Text(
            'No volunteers are available right now.\nPlease check back later.',
            textAlign: TextAlign.center,
            style: GoogleFonts.crimsonPro(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.secondary.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

/// Pins the horizontal tag-filter chips to the top of the volunteers scroll, so
/// they stay reachable while the listener list scrolls beneath them.
///
/// The strip is frosted (same treatment as the journal's filter bar) because the
/// screen has an image background — an unpainted pinned header would let cards
/// show straight through it as they scroll under.
class _TagFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double extent;
  final List<String> selectedTags;
  final void Function(String tag) onTagTap;

  _TagFilterHeaderDelegate({
    required this.extent,
    required this.selectedTags,
    required this.onTagTap,
  });

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          alignment: Alignment.centerLeft,
          color: AppColors.background.withAlpha(overlapsContent ? 120 : 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AppConstants.volunteerTags.map((tag) {
                final isSelected = selectedTags.contains(tag);
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      tag,
                      style: GoogleFonts.crimsonPro(
                        color: isSelected ? Colors.white : AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => onTagTap(tag),
                    selectedColor: AppColors.secondary,
                    backgroundColor: AppColors.background,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(
                        color: AppColors.secondary,
                        width: 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // Without comparing the selection, tapping a chip would not repaint the
  // PINNED header — the chip would appear not to respond.
  @override
  bool shouldRebuild(covariant _TagFilterHeaderDelegate oldDelegate) {
    return oldDelegate.extent != extent ||
        !listEquals(oldDelegate.selectedTags, selectedTags);
  }
}
