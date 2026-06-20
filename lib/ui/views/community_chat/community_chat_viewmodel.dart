import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/community_service.dart';
import 'package:you_app/services/moderation_flag_service.dart';
import 'package:you_app/services/moderation_service.dart';
import 'package:you_app/models/community_post.dart';
import 'package:you_app/ui/views/community_chat/thread_replies_view.dart';
import 'package:you_app/ui/shared/in_app_notification_banner.dart';

class CommunityChatViewModel extends StreamViewModel<List<CommunityPost>> {
  final _navigationService = locator<NavigationService>();
  final _authService = locator<AuthenticationService>();
  final _snackbarService = locator<SnackbarService>();

  final String communityId;
  final String communityName;

  final TextEditingController messageController = TextEditingController();

  List<CommunityPost> get posts => data ?? [];

  // --- Pagination (growing-limit) ---
  static const int _pageSize = 20;
  int _postLimit = _pageSize;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  /// There may be more posts if the current page filled up to the limit.
  bool get canLoadMore => posts.length >= _postLimit;

  /// Grows the page size and re-subscribes to the stream. Old data is kept
  /// (clearOldData: false) so the visible list never flickers.
  void loadMore() {
    if (_isLoadingMore || !canLoadMore) return;
    _isLoadingMore = true;
    _postLimit += _pageSize;
    notifyListeners();
    notifySourceChanged();
  }

  String get currentUserId => _authService.currentUser?.uid ?? '';
  String get currentUserName => _authService.currentUser?.fullName ?? 'Anonymous';

  CommunityChatViewModel({
    required this.communityId,
    required this.communityName,
  });

  bool get isMember {
    final user = _authService.currentUser;
    if (user == null) return false;
    return user.joinedCommunities.contains(communityId);
  }

  Future<void> joinCommunity() async {
    try {
      await locator<CommunityService>().joinCommunity(communityId);
      await _authService.checkCurrentUserStatus(); // Refresh user data locally
      notifyListeners();
      InAppNotificationBanner.show(
        title: 'Joined Community!',
        body: 'You are now a member of $communityName.',
        type: 'request_accepted',
      );
    } catch (e) {
      _snackbarService.showSnackbar(
        title: 'Error',
        message: 'Could not join community. Please try again.',
      );
    }
  }

  @override
  Stream<List<CommunityPost>> get stream =>
      locator<CommunityService>().getCommunityPosts(communityId, limit: _postLimit);

  @override
  void onData(List<CommunityPost>? data) {
    _isLoadingMore = false;
    setBusy(false);
  }

  @override
  void onError(error, StackTrace? stackTrace) {
    _snackbarService.showSnackbar(
      title: 'Error',
      message: 'Failed to load community threads.',
    );
    setBusy(false);
  }

  Future<void> sendPost() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    // --- Moderation gate ---
    final moderation = locator<ModerationService>()
        .inspect(text, context: ModerationContext.community);
    if (moderation.isBlocked) {
      _snackbarService.showSnackbar(
        title: 'Post blocked',
        message:
            'This post appears to violate our community guidelines and was not published.',
      );
      locator<AnalyticsService>().logContentBlocked(
          source: 'post', category: moderation.categoryNames.join(','));
      locator<ModerationFlagService>().recordBlocked(
        context: ModerationContext.community,
        senderId: currentUserId,
        communityId: communityId,
        text: text,
        result: moderation,
      );
      return; // keep the text so the author can edit it
    }
    if (moderation.action == ModerationAction.maskSend) {
      _snackbarService.showSnackbar(
          message:
              'Sharing contact details is discouraged; it will be hidden from others.');
    } else if (moderation.action == ModerationAction.warnSend) {
      _snackbarService.showSnackbar(
          message: 'Please keep posts supportive and on-topic.');
    }

    messageController.clear();
    notifyListeners();

    try {
      // Basic Mention extraction
      // Find words starting with @ and remove the @
      final words = text.split(' ');
      List<String> mentionedUsernames = words
          .where((w) => w.startsWith('@') && w.length > 1)
          .map((w) => w.substring(1)) // Remove '@'
          .toList();

      // IMPORTANT: Currently we are storing the username as the mention string because we don't have
      // an easy mapping to userId on the client. In a full implementation, you'd have a dropdown that assigns userIds.
      // For this step, we will pass mentionedUsernames as mentionedUsers for now, or you'd search the DB to resolve IDs.
      // However, the backend expects userIds. Since this is an MVP, we'll pass an empty list unless we resolve it.
      // (Let's pass empty list to not crash the backend loop).
      
      await locator<CommunityService>().createPost(
        communityId: communityId,
        content: text,
        authorUsername: currentUserName,
        mentionedUsers: [], // Needs user search to resolve IDs
      );
    } catch (e) {
      _snackbarService.showSnackbar(
        title: 'Error',
        message: 'Could not create post. Please try again.',
      );
    }
  }

  void navigateToThread(CommunityPost post) {
    _navigationService.navigateWithTransition(
      ThreadRepliesView(
        post: post,
        communityName: communityName,
      ),
      transitionStyle: Transition.rightToLeft,
    );
  }

  void toggleLike(CommunityPost post) {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    
    final isLiked = post.likedBy.contains(uid);
    if (isLiked) {
      post.likedBy.remove(uid);
      post.likeCount -= 1;
    } else {
      post.likedBy.add(uid);
      post.likeCount += 1;
    }
    notifyListeners();
    
    locator<CommunityService>().toggleLikePost(post.id, isLiked);
  }

  void back() {
    _navigationService.back();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}

