import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/ui/views/paywall/paywall_helper.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/community_service.dart';
import 'package:you_app/services/escalation_service.dart';
import 'package:you_app/services/moderation_flag_service.dart';
import 'package:you_app/services/moderation_service.dart';
import 'package:you_app/services/monetization_service.dart';
import 'package:you_app/models/community_post.dart';
import 'package:you_app/ui/views/community_chat/community_card_widgets.dart';
import 'package:you_app/ui/views/community_chat/thread_replies_view.dart';
import 'package:you_app/ui/shared/in_app_notification_banner.dart';

class CommunityChatViewModel extends StreamViewModel<List<CommunityPost>> {
  final _navigationService = locator<NavigationService>();
  final _authService = locator<AuthenticationService>();
  final _monetizationService = locator<MonetizationService>();
  final _snackbarService = locator<SnackbarService>();

  final String communityId;
  final String communityName;

  final TextEditingController messageController = TextEditingController();

  List<CommunityPost> get posts => data ?? [];

  /// True once the free monthly thread cap has been hit this session. Drives the
  /// persistent "unlock unlimited threads" button above the composer.
  bool _threadCapReached = false;
  bool get threadCapReached => _threadCapReached;

  /// Opens the Premium paywall from the thread cap-reached button.
  Future<void> openThreadPaywall() async {
    locator<AnalyticsService>()
        .logGateHit(feature: PaywallFeature.communityThreads);
    await PaywallHelper.show(feature: PaywallFeature.communityThreads);
  }

  // --- Optimistic "Posting…" cards (shown until the real thread streams in) ---
  final List<PendingContent> _pendingPosts = [];
  int _pendingCounter = 0;
  List<PendingContent> get pendingPosts => List.unmodifiable(_pendingPosts);

  void _removePending(int id) {
    final before = _pendingPosts.length;
    _pendingPosts.removeWhere((p) => p.id == id);
    if (_pendingPosts.length != before) notifyListeners();
  }

  /// Drops pending cards whose content now exists as a real post by this user
  /// (the seamless swap). Removes at most one pending per matched post.
  void _reconcilePending(List<CommunityPost> posts) {
    if (_pendingPosts.isEmpty) return;
    final mine = posts
        .where((p) => p.authorId == currentUserId)
        .map((p) => p.content.trim())
        .toList();
    var changed = false;
    for (final content in mine) {
      final idx = _pendingPosts.indexWhere((p) => p.content.trim() == content);
      if (idx != -1) {
        _pendingPosts.removeAt(idx);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

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
  String get currentUserName =>
      _authService.currentUser?.fullName ?? 'Anonymous';

  CommunityChatViewModel({
    required this.communityId,
    required this.communityName,
  }) {
    _communitySub = locator<CommunityService>()
        .getCommunity(communityId)
        .listen((community) {
      final locked = community?['isLocked'] == true;
      if (locked != _isLocked) {
        _isLocked = locked;
        notifyListeners();
      }
    });
    // Show the "limit reached" button immediately if already capped (persists
    // across restarts until Premium or the monthly reset), and keep it in sync
    // when Premium is granted mid-session.
    _refreshCapStatus();
    _authService.addListener(_refreshCapStatus);
  }

  Future<void> _refreshCapStatus() async {
    final capped = await _monetizationService.isCommunityThreadCapReached();
    if (capped != _threadCapReached) {
      _threadCapReached = capped;
      notifyListeners();
    }
  }

  // --- Lock state (admin can flip communities to read-only) ---
  StreamSubscription<Map<String, dynamic>?>? _communitySub;
  bool _isLocked = false;
  bool get isLocked => _isLocked;

  bool get isMember {
    final user = _authService.currentUser;
    if (user == null) return false;
    return user.joinedCommunities.contains(communityId);
  }

  bool _joining = false;
  bool get joining => _joining;

  Future<void> joinCommunity() async {
    if (_joining) return;
    _joining = true;
    notifyListeners();
    try {
      await locator<CommunityService>().joinCommunity(communityId);
      await _authService.checkCurrentUserStatus(); // Refresh user data locally
      HapticFeedback.lightImpact();
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
    } finally {
      _joining = false;
      notifyListeners();
    }
  }

  @override
  Stream<List<CommunityPost>> get stream => locator<CommunityService>()
      .getCommunityPosts(communityId, limit: _postLimit);

  @override
  void onData(List<CommunityPost>? data) {
    _isLoadingMore = false;
    if (data != null) _reconcilePending(data);
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
    // Already capped this month — don't waste a call; nudge to the paywall.
    if (_threadCapReached) {
      await openThreadPaywall();
      return;
    }

    final text = messageController.text.trim();
    if (text.isEmpty) return;

    if (_isLocked) {
      _snackbarService.showSnackbar(
        title: 'Read-only',
        message: 'This community is read-only. New posts are disabled.',
      );
      return;
    }

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
      // Any SEVERE block (banned/hate/violence/sexual) raises an escalation —
      // the admin crisis feed expects severe blocks, not just violence.
      if (moderation.severity == 'severe') {
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
          message: 'Please keep posts supportive and on-topic.');
    }

    messageController.clear();

    // Optimistic "Posting…" card shown instantly until the real thread streams
    // in (reconciled in onData) — or removed on cap/error/timeout.
    final pending = PendingContent(id: ++_pendingCounter, content: text);
    _pendingPosts.add(pending);
    notifyListeners();
    // Safety net: never leave a stuck card if the write never propagates.
    Future.delayed(
        const Duration(seconds: 15), () => _removePending(pending.id));

    try {
      // New-thread mentions are out of scope (premium @-mentions live in the
      // reply composer); the callable enforces the free monthly thread cap.
      final result = await locator<CommunityService>().createPost(
        communityId: communityId,
        content: text,
        authorUsername: currentUserName,
        mentionedUsers: const [],
      );

      // Free user is out of monthly threads — restore the text, show the
      // persistent upgrade button, and open the paywall once immediately.
      if (result.capReached) {
        _removePending(pending.id);
        messageController.text = text;
        _threadCapReached = true;
        notifyListeners();
        await openThreadPaywall();
      }
    } catch (e) {
      _removePending(pending.id);
      _snackbarService.showSnackbar(
        title: 'Error',
        message: 'Could not create post. Please try again.',
      );
    }
  }

  /// Deletes the user's own thread, after confirming. Deleting a post cascades
  /// its replies server-side (`onPostDeleted`), so the confirmation says so —
  /// the author is also removing other people's replies to them.
  Future<void> deletePost(CommunityPost post) async {
    if (post.authorId != currentUserId) return;

    final response = await locator<DialogService>().showConfirmationDialog(
      title: 'Delete thread?',
      description: post.replyCount > 0
          ? 'This will permanently delete your thread and its '
              '${post.replyCount} ${post.replyCount == 1 ? 'reply' : 'replies'}. '
              'This cannot be undone.'
          : 'This will permanently delete your thread. This cannot be undone.',
      confirmationTitle: 'Delete',
      cancelTitle: 'Cancel',
    );
    if (response?.confirmed != true) return;

    try {
      await locator<CommunityService>().deletePost(post.id);
      // No local list surgery needed — the Firestore stream drops it for us.
    } catch (e) {
      _snackbarService.showSnackbar(
        title: 'Error',
        message: 'Could not delete this thread. Please try again.',
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

  Future<void> toggleLike(CommunityPost post) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;

    final isLiked = post.likedBy.contains(uid);
    // Optimistic update.
    if (isLiked) {
      post.likedBy.remove(uid);
      post.likeCount -= 1;
    } else {
      post.likedBy.add(uid);
      post.likeCount += 1;
    }
    notifyListeners();

    try {
      await locator<CommunityService>().toggleLikePost(post.id, isLiked);
    } catch (_) {
      // Roll back the optimistic change if the write failed.
      if (isLiked) {
        post.likedBy.add(uid);
        post.likeCount += 1;
      } else {
        post.likedBy.remove(uid);
        post.likeCount -= 1;
      }
      notifyListeners();
    }
  }

  void back() {
    _navigationService.back();
  }

  @override
  void dispose() {
    _communitySub?.cancel();
    _authService.removeListener(_refreshCapStatus);
    messageController.dispose();
    super.dispose();
  }
}
