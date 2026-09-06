import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/animation_decoder.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/moderation_service.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/views/community_chat/community_card_widgets.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/shared/busy_button.dart';
import 'package:you_app/ui/shared/fade_slide_in.dart';
import 'package:you_app/ui/shared/floating_composer_layout.dart';
import 'package:you_app/ui/shared/skeleton.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/models/community_post.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'community_chat_viewmodel.dart';

class CommunityChatView extends StackedView<CommunityChatViewModel> {
  final String communityId;
  final String communityName;

  const CommunityChatView({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  Widget builder(
    BuildContext context,
    CommunityChatViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
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
              leadingIconAsset: AppConstants.back,
              iconColor: AppColors.primaryVeryDark,
              onLeadingPressed: () {
                Navigator.pop(context);
              },
              title: communityName,
              trailingActions: [],
            ),
            Expanded(
              child: FloatingComposerLayout(
                composer: viewModel.isLocked
                    ? const _LockedBanner()
                    : viewModel.isMember
                        ? const _PostComposer()
                        : SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: BusyButton(
                                busy: viewModel.joining,
                                onPressed: viewModel.joinCommunity,
                                label: 'Join Community to Post',
                                busyLabel: 'Joining…',
                              ),
                            ),
                          ),
                listBuilder: (context, bottomInset) {
                  final pending = viewModel.pendingPosts;
                  if (viewModel.isBusy && viewModel.posts.isEmpty) {
                    return const SkeletonList();
                  }
                  if (viewModel.posts.isEmpty && pending.isEmpty) {
                    return _buildEmptyState();
                  }
                  return NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      // Trigger load-more as the user nears the bottom.
                      if (notification.metrics.pixels >=
                          notification.metrics.maxScrollExtent - 200) {
                        viewModel.loadMore();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      // Bottom padding tracks the floating composer.
                      padding: EdgeInsets.fromLTRB(12, 16, 12, bottomInset),
                      // Pending "Posting…" cards render first (at the top).
                      itemCount: pending.length +
                          viewModel.posts.length +
                          (viewModel.canLoadMore ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index < pending.length) {
                          return PendingCard(
                            authorName: viewModel.currentUserName,
                            content: pending[index].content,
                          );
                        }
                        final postIndex = index - pending.length;
                        if (postIndex >= viewModel.posts.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        final post = viewModel.posts[postIndex];
                        final isMe = post.authorId == viewModel.currentUserId;

                        return FadeSlideIn(
                          index: postIndex,
                          child: _CommunityPostCard(
                            post: post,
                            isMe: isMe,
                            isLiked:
                                post.likedBy.contains(viewModel.currentUserId),
                            onTap: () => viewModel.navigateToThread(post),
                            onLike: () => viewModel.toggleLike(post),
                            onDelete:
                                isMe ? () => viewModel.deletePost(post) : null,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Lottie.asset(
            AppConstants.empty,
            decoder: customDecoder,
            width: 250,
            height: 250,
          ),
          Text(
            'Be the first to start a thread!',
            style: GoogleFonts.crimsonPro(
              color: AppColors.primaryVeryDark.withAlpha(150),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  CommunityChatViewModel viewModelBuilder(BuildContext context) =>
      CommunityChatViewModel(
        communityId: communityId,
        communityName: communityName,
      );
}

// -------------------------------------------------------------------
// WIDGETS
// -------------------------------------------------------------------

class _PostComposer extends ViewModelWidget<CommunityChatViewModel> {
  const _PostComposer();

  @override
  Widget build(BuildContext context, CommunityChatViewModel viewModel) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (viewModel.threadCapReached) const _ThreadUpgradeButton(),
            Stack(
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
                    hintText: "Start a new thread...",
                    hintStyle: GoogleFonts.crimsonPro(
                      color: AppColors.secondary.withAlpha(150),
                    ),
                    filled: true,
                    fillColor: AppColors.secondaryVeryLight.withAlpha(240),
                    contentPadding: const EdgeInsets.fromLTRB(16, 16, 60, 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(
                          color: AppColors.secondary, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(
                          color: AppColors.secondary, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(
                          color: AppColors.secondary, width: 2),
                    ),
                  ),
                  onSubmitted: (_) => viewModel.sendPost(),
                ),
                Positioned(
                  right: 8.0,
                  bottom: 5.5,
                  child: GestureDetector(
                    onTap: viewModel.sendPost,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.secondaryVeryLight.withAlpha(75),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.secondary, width: 2),
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
          ],
        ),
      ),
    );
  }
}

/// Persistent CTA shown above the composer once the free monthly thread cap is
/// hit. Tapping it opens the Premium paywall.
class _ThreadUpgradeButton extends ViewModelWidget<CommunityChatViewModel> {
  const _ThreadUpgradeButton();

  @override
  Widget build(BuildContext context, CommunityChatViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: viewModel.openThreadPaywall,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.secondary, AppColors.secondaryLight],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withAlpha(70),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(AppConstants.premiumBadgeFill,
                    width: 20, height: 20, color: Colors.white),
                const SizedBox(width: 7),
                Text(
                  'Monthly limit reached · Unlock unlimited threads',
                  style: GoogleFonts.crimsonPro(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LockedBanner extends StatelessWidget {
  const _LockedBanner();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.secondaryVeryLight.withAlpha(240),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.secondary.withAlpha(60)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline,
                  size: 20, color: AppColors.secondary),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'This community is read-only',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.crimsonPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
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

class _CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final bool isMe;
  final bool isLiked;
  final VoidCallback onTap;
  final VoidCallback onLike;

  /// Only supplied for the author's own thread — see [isMe].
  final VoidCallback? onDelete;

  const _CommunityPostCard({
    required this.post,
    required this.isMe,
    required this.isLiked,
    required this.onTap,
    required this.onLike,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeString =
        timeago.format(post.createdAt, locale: 'en_short'); // e.g., '5m', '2h'
    final initial = post.authorUsername.isNotEmpty
        ? post.authorUsername[0].toUpperCase()
        : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha(240),
                AppColors.secondaryVeryLight.withAlpha(70),
              ],
            ),
            border: Border.all(
                color: AppColors.primaryVeryDark.withAlpha(20), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryVeryDark.withAlpha(20),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GradientAvatar(initial: initial, isMe: isMe),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                post.authorUsername,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.crimsonPro(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryVeryDark,
                                ),
                              ),
                            ),
                            if (isMe) const YouChip(),
                          ],
                        ),
                        Text(
                          timeString,
                          style: GoogleFonts.crimsonPro(
                            fontSize: 12.5,
                            color: AppColors.primaryVeryDark.withAlpha(130),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isMe && onDelete != null)
                    DeleteButton(onDelete: onDelete!),
                ],
              ),
              const SizedBox(height: 12),
              // Post Body (contact info blurred for safety)
              Text(
                locator<ModerationService>().maskPii(post.content),
                style: GoogleFonts.crimsonPro(
                  fontSize: 16,
                  color: AppColors.primaryVeryDark.withAlpha(230),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  StatChip(
                    iconAsset: AppConstants.reply,
                    label: '${post.replyCount}',
                  ),
                  const SizedBox(width: 10),
                  LikeChip(
                    isLiked: isLiked,
                    onLike: onLike,
                    count: post.likeCount,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
