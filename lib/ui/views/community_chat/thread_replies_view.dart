import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/models/community_post.dart';
import 'package:you_app/models/thread_reply.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'thread_replies_viewmodel.dart';

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
              child: viewModel.isBusy
                  ? const Center(
                      child: CircularProgressIndicator(
                      color: AppColors.secondary,
                    ))
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: _OriginalPostCard(post: post),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                                    final isMe = reply.authorId == viewModel.currentUserId;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                      child: _ReplyCard(reply: reply, isMe: isMe),
                                    );
                                  },
                                  childCount: viewModel.replies.length,
                                ),
                              ),
                        // Add some bottom padding
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],
                    ),
            ),
            const _ReplyComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Text(
          'No replies yet. Be the first!',
          style: GoogleFonts.crimsonPro(
            color: AppColors.primaryVeryDark.withAlpha(150),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
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
        child: TextField(
          controller: viewModel.replyController,
          keyboardType: TextInputType.multiline,
          maxLines: null,
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
            fillColor: AppColors.secondaryVeryLight.withAlpha(75),
            contentPadding: const EdgeInsets.fromLTRB(16, 16, 60, 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(color: AppColors.secondary, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(color: AppColors.secondary, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(color: AppColors.secondary, width: 2),
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8.0),
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
          ),
          onSubmitted: (_) => viewModel.sendReply(),
        ),
      ),
    );
  }
}

class _OriginalPostCard extends StatelessWidget {
  final CommunityPost post;

  const _OriginalPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final timeString = timeago.format(post.createdAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(color: AppColors.primaryVeryDark.withAlpha(20), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.secondary.withAlpha(50),
                child: Text(
                  post.authorUsername.isNotEmpty ? post.authorUsername[0].toUpperCase() : '?',
                  style: GoogleFonts.crimsonPro(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.authorUsername,
                    style: GoogleFonts.crimsonPro(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryVeryDark,
                    ),
                  ),
                  Text(
                    '@${post.authorUsername.toLowerCase().replaceAll(' ', '')}',
                    style: GoogleFonts.crimsonPro(
                      fontSize: 14,
                      color: AppColors.primaryVeryDark.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            post.content,
            style: GoogleFonts.crimsonPro(
              fontSize: 18,
              color: AppColors.primaryVeryDark,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            timeString,
            style: GoogleFonts.crimsonPro(
              fontSize: 14,
              color: AppColors.primaryVeryDark.withAlpha(150),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.primaryVeryDark.withAlpha(20), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${post.replyCount}',
                style: GoogleFonts.crimsonPro(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryVeryDark,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Replies',
                style: GoogleFonts.crimsonPro(
                  fontSize: 15,
                  color: AppColors.primaryVeryDark.withAlpha(150),
                ),
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

  const _ReplyCard({
    required this.reply,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final timeString = timeago.format(reply.createdAt, locale: 'en_short');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(color: AppColors.primaryVeryDark.withAlpha(15), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isMe ? AppColors.secondary.withAlpha(50) : AppColors.lightPurple.withAlpha(50),
            child: Text(
              reply.authorUsername.isNotEmpty ? reply.authorUsername[0].toUpperCase() : '?',
              style: GoogleFonts.crimsonPro(
                color: isMe ? AppColors.secondary : AppColors.lightPurple,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      reply.authorUsername,
                      style: GoogleFonts.crimsonPro(
                        fontSize: 15,
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
                Text(
                  reply.content,
                  style: GoogleFonts.crimsonPro(
                    fontSize: 15,
                    color: AppColors.primaryVeryDark.withAlpha(220),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 16,
                      color: AppColors.primaryVeryDark.withAlpha(100),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
