import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/community_service.dart';
import 'package:you_app/services/escalation_service.dart';
import 'package:you_app/services/moderation_flag_service.dart';
import 'package:you_app/services/moderation_service.dart';
import 'package:you_app/models/community_post.dart';
import 'package:you_app/models/thread_reply.dart';
import 'package:you_app/ui/shared/in_app_notification_banner.dart';

class ThreadRepliesViewModel extends StreamViewModel<List<ThreadReply>> {
  final _navigationService = locator<NavigationService>();
  final _authService = locator<AuthenticationService>();
  final _snackbarService = locator<SnackbarService>();

  final CommunityPost post;

  final TextEditingController replyController = TextEditingController();

  List<ThreadReply> get replies => data ?? [];

  String get currentUserId => _authService.currentUser?.uid ?? '';
  String get currentUserName => _authService.currentUser?.fullName ?? 'Anonymous';

  ThreadRepliesViewModel({
    required this.post,
  }) {
    _communitySub = locator<CommunityService>()
        .getCommunity(post.communityId)
        .listen((community) {
      final locked = community?['isLocked'] == true;
      if (locked != _isLocked) {
        _isLocked = locked;
        notifyListeners();
      }
    });
  }

  // --- Lock state (admin can flip communities to read-only) ---
  StreamSubscription<Map<String, dynamic>?>? _communitySub;
  bool _isLocked = false;
  bool get isLocked => _isLocked;

  bool get isMember {
    final user = _authService.currentUser;
    if (user == null) return false;
    return user.joinedCommunities.contains(post.communityId);
  }

  Future<void> joinCommunity() async {
    try {
      await locator<CommunityService>().joinCommunity(post.communityId);
      await _authService.checkCurrentUserStatus(); // Refresh user data locally
      notifyListeners();
      InAppNotificationBanner.show(
        title: 'Joined Community!',
        body: 'You are now a member and can post threads.',
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
  Stream<List<ThreadReply>> get stream =>
      locator<CommunityService>().getThreadReplies(post.id).map((replies) {
        replies.sort((a, b) {
          int cmp = b.likeCount.compareTo(a.likeCount);
          if (cmp == 0) {
            cmp = a.createdAt.compareTo(b.createdAt);
          }
          return cmp;
        });
        return replies;
      });

  @override
  void onData(List<ThreadReply>? data) {
    setBusy(false);
  }

  @override
  void onError(error, StackTrace? stackTrace) {
    _snackbarService.showSnackbar(
      title: 'Error',
      message: 'Failed to load replies.',
    );
    setBusy(false);
  }

  Future<void> sendReply() async {
    final text = replyController.text.trim();
    if (text.isEmpty) return;

    if (_isLocked) {
      _snackbarService.showSnackbar(
        title: 'Read-only',
        message: 'This community is read-only. New replies are disabled.',
      );
      return;
    }

    // --- Moderation gate ---
    final moderation = locator<ModerationService>()
        .inspect(text, context: ModerationContext.community);
    if (moderation.isBlocked) {
      _snackbarService.showSnackbar(
        title: 'Reply blocked',
        message:
            'This reply appears to violate our community guidelines and was not published.',
      );
      locator<AnalyticsService>().logContentBlocked(
          source: 'reply', category: moderation.categoryNames.join(','));
      locator<ModerationFlagService>().recordBlocked(
        context: ModerationContext.community,
        senderId: currentUserId,
        communityId: post.communityId,
        text: text,
        result: moderation,
      );
      if (moderation.categories.contains(ModerationCategory.violence)) {
        locator<EscalationService>().escalateModeration(
          userId: currentUserId,
          userName: currentUserName,
          reason:
              'Blocked phrase: "${moderation.matchedTerms.isNotEmpty ? moderation.matchedTerms.first : 'violence'}"',
        );
      }
      return; // keep the text so the author can edit it
    }
    if (moderation.action == ModerationAction.maskSend) {
      _snackbarService.showSnackbar(
          message:
              'Sharing contact details is discouraged; it will be hidden from others.');
    } else if (moderation.action == ModerationAction.warnSend) {
      _snackbarService.showSnackbar(
          message: 'Please keep replies supportive and on-topic.');
    }

    replyController.clear();
    notifyListeners();

    try {
      await locator<CommunityService>().createReply(
        postId: post.id,
        content: text,
        authorUsername: currentUserName,
        mentionedUsers: [], // Needs user search to resolve IDs
      );
    } catch (e) {
      _snackbarService.showSnackbar(
        title: 'Error',
        message: 'Could not send reply. Please try again.',
      );
    }
  }

  void toggleLike() {
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

  void toggleReplyLike(ThreadReply reply) {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    
    final isLiked = reply.likedBy.contains(uid);
    if (isLiked) {
      reply.likedBy.remove(uid);
      reply.likeCount -= 1;
    } else {
      reply.likedBy.add(uid);
      reply.likeCount += 1;
    }
    notifyListeners();
    
    locator<CommunityService>().toggleLikeReply(post.id, reply.id, isLiked);
  }

  void back() {
    _navigationService.back();
  }

  @override
  void dispose() {
    _communitySub?.cancel();
    replyController.dispose();
    super.dispose();
  }
}
