import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/animation_decoder.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/models/community_post.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'community_chat_viewmodel.dart';
import 'package:you_app/ui/shared/lottie_like_button.dart';
import "package:you_app/ui/shared/custom_lottie_loader.dart";

class CommunityChatView extends StackedView<CommunityChatViewModel> {
  final String communityId;
  final String communityName;

  const CommunityChatView({
    Key? key,
    required this.communityId,
    required this.communityName,
  }) : super(key: key);

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
              child: viewModel.isBusy
                  ? const CustomLottieLoader(fullScreen: true)
                  : viewModel.posts.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          itemCount: viewModel.posts.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final post = viewModel.posts[index];
                            final isMe =
                                post.authorId == viewModel.currentUserId;

                            return _CommunityPostCard(
                              post: post,
                              isMe: isMe,
                              isLiked: post.likedBy
                                  .contains(viewModel.currentUserId),
                              onTap: () => viewModel.navigateToThread(post),
                              onLike: () => viewModel.toggleLike(post),
                            );
                          },
                        ),
            ),
            if (viewModel.isMember)
              const _PostComposer()
            else
              SafeArea(
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      'Join Community to Post',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
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
  const _PostComposer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, CommunityChatViewModel viewModel) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: TextField(
          controller: viewModel.messageController,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          cursorColor: AppColors.secondary,
          style: GoogleFonts.crimsonPro(
            color: AppColors.secondary,
          ),
          decoration: InputDecoration(
            hintText: "Start a new thread... (@ to mention)",
            hintStyle: GoogleFonts.crimsonPro(
              color: AppColors.secondary.withAlpha(150),
            ),
            filled: true,
            fillColor: AppColors.secondaryVeryLight.withAlpha(75),
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
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: viewModel.sendPost,
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
          ),
          onSubmitted: (_) => viewModel.sendPost(),
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

  const _CommunityPostCard({
    required this.post,
    required this.isMe,
    required this.isLiked,
    required this.onTap,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final timeString =
        timeago.format(post.createdAt, locale: 'en_short'); // e.g., '5m', '2h'

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.background.withAlpha(200),
          border: Border(
            bottom: BorderSide(
              color: AppColors.primaryVeryDark.withAlpha(20),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: isMe
                  ? AppColors.secondary.withAlpha(50)
                  : AppColors.primaryVeryDark.withAlpha(50),
              child: Text(
                post.authorUsername.isNotEmpty
                    ? post.authorUsername[0].toUpperCase()
                    : '?',
                style: GoogleFonts.crimsonPro(
                  color: isMe ? AppColors.secondary : AppColors.primaryVeryDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Right Column: Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Name & Timestamp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        post.authorUsername,
                        style: GoogleFonts.crimsonPro(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryVeryDark,
                        ),
                      ),
                      Text(
                        timeString,
                        style: GoogleFonts.crimsonPro(
                          fontSize: 13,
                          color: AppColors.primaryVeryDark.withAlpha(130),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Post Body
                  Text(
                    post.content,
                    style: GoogleFonts.crimsonPro(
                      fontSize: 16,
                      color: AppColors.primaryVeryDark.withAlpha(220),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Action Row
                  Row(
                    children: [
                      Image(
                          image: AssetImage(AppConstants.reply),
                          width: 20,
                          color: AppColors.primaryVeryDark.withAlpha(150)),
                      const SizedBox(width: 6),
                      Text(
                        '${post.replyCount}',
                        style: GoogleFonts.crimsonPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryVeryDark.withAlpha(120),
                        ),
                      ),
                      const SizedBox(width: 24),
                      LottieLikeButton(
                        isLiked: isLiked,
                        onTap: onLike,
                        size:
                            32, // Adjust size slightly to match original footprint
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.likeCount}',
                        style: GoogleFonts.crimsonPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryVeryDark.withAlpha(120),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
