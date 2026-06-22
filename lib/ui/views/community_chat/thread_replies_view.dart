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
import 'package:you_app/ui/shared/floating_composer_layout.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/models/community_post.dart';
import 'package:you_app/models/thread_reply.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'thread_replies_viewmodel.dart';
import "package:you_app/ui/shared/custom_lottie_loader.dart";

class ThreadRepliesView extends StackedView<ThreadRepliesViewModel> {
  final CommunityPost post;
  final String communityName;

  const ThreadRepliesView({
    Key? key,
    required this.post,
    required this.communityName,
  }) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    ThreadRepliesViewModel viewModel,
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
              title: "Thread",
              trailingActions: [],
            ),
            Expanded(
              child: FloatingComposerLayout(
                composer: viewModel.isLocked
                    ? const _LockedBanner()
                    : viewModel.isMember
                        ? const _ReplyComposer()
                        : SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ElevatedButton(
                                onPressed: viewModel.joinCommunity,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: Text(
                                  'Join Community to Reply',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                listBuilder: (context, bottomInset) => viewModel.isBusy
                  ? const CustomLottieLoader(fullScreen: true)
                  : CustomScrollView(slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: _OriginalPostCard(
                            post: post,
                            isLiked:
                                post.likedBy.contains(viewModel.currentUserId),
                            onLike: viewModel.toggleLike,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            'Replies',
                            style: GoogleFonts.crimsonPro(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryVeryDark,
                            ),
                          ),
                        ),
                      ),
                      viewModel.replies.isEmpty
                          ? SliverToBoxAdapter(child: _buildEmptyState())
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final reply = viewModel.replies[index];
                                  final isMe =
                                      reply.authorId == viewModel.currentUserId;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0, vertical: 6.0),
                                    child: _ReplyCard(
                                      reply: reply,
                                      isMe: isMe,
                                      isLiked: reply.likedBy
                                          .contains(viewModel.currentUserId),
                                      onLike: () =>
                                          viewModel.toggleReplyLike(reply),
                                    ),
                                  );
                                },
                                childCount: viewModel.replies.length,
                              ),
                            ),
                      // Bottom padding tracks the floating composer's height.
                      SliverToBoxAdapter(
                          child: SizedBox(height: bottomInset)),
                    ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Lottie.asset(
          AppConstants.empty,
          decoder: customDecoder,
          width: 200,
          height: 200,
        ),
        // Text(
        //   'No replies yet. Be the first!',
        //   style: GoogleFonts.crimsonPro(
        //     color: AppColors.primaryVeryDark.withAlpha(150),
        //     fontSize: 16,
        //     fontWeight: FontWeight.w500,
        //   ),
        // ),
      ),
    );
  }

  @override
  ThreadRepliesViewModel viewModelBuilder(BuildContext context) =>
      ThreadRepliesViewModel(post: post);
}

// -------------------------------------------------------------------
// WIDGETS
// -------------------------------------------------------------------

class _ReplyComposer extends ViewModelWidget<ThreadRepliesViewModel> {
  const _ReplyComposer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ThreadRepliesViewModel viewModel) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Stack(
          children: [
            TextField(
              controller: viewModel.replyController,
              keyboardType: TextInputType.multiline,
              maxLines: 5,
              minLines: 1,
              cursorColor: AppColors.secondary,
              style: GoogleFonts.crimsonPro(
                color: AppColors.secondary,
              ),
              decoration: InputDecoration(
                hintText: "Reply... (@ to mention)",
                hintStyle: GoogleFonts.crimsonPro(
                  color: AppColors.secondary.withAlpha(150),
                ),
                filled: true,
                fillColor: AppColors.secondaryVeryLight.withAlpha(240),
                contentPadding: const EdgeInsets.fromLTRB(16, 16, 60, 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide:
                      const BorderSide(color: AppColors.secondary, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide:
                      const BorderSide(color: AppColors.secondary, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide:
                      const BorderSide(color: AppColors.secondary, width: 2),
                ),
              ),
              onSubmitted: (_) => viewModel.sendReply(),
            ),
            Positioned(
              right: 8.0,
              bottom: 5.5,
              child: GestureDetector(
                onTap: viewModel.sendReply,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondaryVeryLight.withAlpha(75),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.secondary, width: 2),
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
    );
  }
}

class _LockedBanner extends StatelessWidget {
  const _LockedBanner({Key? key}) : super(key: key);

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

class _OriginalPostCard extends StatelessWidget {
  final CommunityPost post;
  final bool isLiked;
  final VoidCallback onLike;

  const _OriginalPostCard({
    required this.post,
    required this.isLiked,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final timeString = timeago.format(post.createdAt);

    final initial = post.authorUsername.isNotEmpty
        ? post.authorUsername[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withAlpha(245),
            AppColors.secondaryVeryLight.withAlpha(85),
          ],
        ),
        border:
            Border.all(color: AppColors.primaryVeryDark.withAlpha(20), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryVeryDark.withAlpha(25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientAvatar(initial: initial, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorUsername,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.crimsonPro(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryVeryDark,
                      ),
                    ),
                    Text(
                      '@${post.authorUsername.toLowerCase().replaceAll(' ', '')}',
                      style: GoogleFonts.crimsonPro(
                        fontSize: 13.5,
                        color: AppColors.primaryVeryDark.withAlpha(150),
                      ),
                    ),
                  ],
                ),
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
          const SizedBox(height: 16),
          Text(
            locator<ModerationService>().maskPii(post.content),
            style: GoogleFonts.crimsonPro(
              fontSize: 17,
              color: AppColors.primaryVeryDark,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.primaryVeryDark.withAlpha(18), height: 1),
          const SizedBox(height: 12),
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
    );
  }
}

class _ReplyCard extends StatelessWidget {
  final ThreadReply reply;
  final bool isMe;
  final bool isLiked;
  final VoidCallback onLike;

  const _ReplyCard({
    required this.reply,
    required this.isMe,
    required this.isLiked,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final timeString = timeago.format(reply.createdAt, locale: 'en_short');

    final initial = reply.authorUsername.isNotEmpty
        ? reply.authorUsername[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withAlpha(225),
            AppColors.primaryLight.withAlpha(90),
          ],
        ),
        border:
            Border.all(color: AppColors.primaryVeryDark.withAlpha(15), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryVeryDark.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientAvatar(initial: initial, isMe: isMe, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              reply.authorUsername,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.crimsonPro(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryVeryDark,
                              ),
                            ),
                          ),
                          if (isMe) const YouChip(),
                        ],
                      ),
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
                const SizedBox(height: 4),
                Text(
                  locator<ModerationService>().maskPii(reply.content),
                  style: GoogleFonts.crimsonPro(
                    fontSize: 15,
                    color: AppColors.primaryVeryDark.withAlpha(230),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: LikeChip(
                    isLiked: isLiked,
                    onLike: onLike,
                    count: reply.likeCount,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Future<LottieComposition?> _customDecoder(List<int> bytes) {
//   return LottieComposition.decodeZip(
//     bytes,
//     filePicker: (files) {
//       return files.firstWhereOrNull(
//         (f) => f.name.startsWith('animations/') && f.name.endsWith('.json'),
//       );
//     },
//   );
// }
