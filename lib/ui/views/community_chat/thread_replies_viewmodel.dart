import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/community_service.dart';
import 'package:you_app/services/escalation_service.dart';
import 'package:you_app/services/moderation_flag_service.dart';
import 'package:you_app/services/moderation_service.dart';
import 'package:you_app/services/monetization_service.dart';
import 'package:you_app/models/community_post.dart';
import 'package:you_app/models/thread_reply.dart';
import 'package:you_app/ui/shared/in_app_notification_banner.dart';
import 'package:you_app/ui/views/community_chat/community_card_widgets.dart';
import 'package:you_app/ui/views/paywall/paywall_helper.dart';

/// A person who can be @-mentioned in this thread.
typedef MentionCandidate = ({String id, String username});

class ThreadRepliesViewModel extends StreamViewModel<List<ThreadReply>> {
  final _navigationService = locator<NavigationService>();
  final _authService = locator<AuthenticationService>();
  final _monetizationService = locator<MonetizationService>();
  final _snackbarService = locator<SnackbarService>();

  final CommunityPost post;

  final TextEditingController replyController = TextEditingController();

  List<ThreadReply> get replies => data ?? [];

  String get currentUserId => _authService.currentUser?.uid ?? '';
  String get currentUserName => _authService.currentUser?.fullName ?? 'Anonymous';

  // --- @-mentions (Premium only) ---
  /// Whether this user may @-mention people in replies.
  bool get canMention => _monetizationService.isPremium;
  // Records the UID for each @username the user picked from the suggestions.
  final Map<String, String> _pickedIdByUsername = {};
  String? _lastMentionQuery;

  // --- Monthly reply cap ---
  /// True once the free monthly reply cap has been hit (persists across restarts
  /// until Premium or the monthly reset). Drives the persistent upgrade button.
  bool _replyCapReached = false;
  bool get replyCapReached => _replyCapReached;

  /// Opens the Premium paywall from the reply cap-reached button.
  Future<void> openReplyPaywall() async {
    locator<AnalyticsService>().logGateHit(feature: PaywallFeature.communityReplies);
    await PaywallHelper.show(feature: PaywallFeature.communityReplies);
  }

  // --- Optimistic "Posting…" cards (shown until the real reply streams in) ---
  final List<PendingContent> _pendingReplies = [];
  int _pendingCounter = 0;
  List<PendingContent> get pendingReplies => List.unmodifiable(_pendingReplies);

  void _removePending(int id) {
    final before = _pendingReplies.length;
    _pendingReplies.removeWhere((p) => p.id == id);
    if (_pendingReplies.length != before) notifyListeners();
  }

  /// Drops pending cards whose content now exists as a real reply by this user.
  void _reconcilePending(List<ThreadReply> replies) {
    if (_pendingReplies.isEmpty) return;
    final mine = replies
        .where((r) => r.authorId == currentUserId)
        .map((r) => r.content.trim())
        .toList();
    var changed = false;
    for (final content in mine) {
      final idx =
          _pendingReplies.indexWhere((p) => p.content.trim() == content);
      if (idx != -1) {
        _pendingReplies.removeAt(idx);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

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
    // Recompute the mention suggestion state as the user types.
    replyController.addListener(_onReplyChanged);
    // Reflect live subscription changes (Premium granted mid-session).
    _authService.addListener(_onSubscriptionChanged);
    // Show the "limit reached" button immediately if already capped.
    _refreshCapStatus();
  }

  Future<void> _refreshCapStatus() async {
    final capped = await _monetizationService.isCommunityReplyCapReached();
    if (capped != _replyCapReached) {
      _replyCapReached = capped;
      notifyListeners();
    }
  }

  void _onReplyChanged() {
    final q = mentionQuery;
    if (q != _lastMentionQuery) {
      _lastMentionQuery = q;
      notifyListeners();
    }
  }

  void _onSubscriptionChanged() {
    _refreshCapStatus(); // Premium granted → hide the cap button
    notifyListeners(); // refresh the mention affordance
  }

  /// The thread participants (post author + everyone who replied), deduped and
  /// excluding the current user — the source of @-mention suggestions.
  List<MentionCandidate> get mentionCandidates {
    final byId = <String, String>{};
    if (post.authorId.isNotEmpty && post.authorId != currentUserId) {
      byId[post.authorId] = post.authorUsername;
    }
    for (final r in replies) {
      if (r.authorId.isNotEmpty && r.authorId != currentUserId) {
        byId[r.authorId] = r.authorUsername;
      }
    }
    return byId.entries
        .map((e) => (id: e.key, username: e.value))
        .toList(growable: false);
  }

  /// The handle currently being typed after an unclosed `@`, or null when the
  /// caret isn't in a mention token. Empty string means `@` was just typed.
  String? get mentionQuery {
    final sel = replyController.selection;
    final text = replyController.text;
    if (!sel.isValid || sel.baseOffset < 0 || sel.baseOffset > text.length) {
      return null;
    }
    final upToCaret = text.substring(0, sel.baseOffset);
    final at = upToCaret.lastIndexOf('@');
    if (at < 0) return null;
    final token = upToCaret.substring(at + 1);
    if (token.contains(RegExp(r'\s'))) return null; // handle already ended
    return token;
  }

  /// Suggestions matching the active mention query (Premium only).
  List<MentionCandidate> get mentionSuggestions {
    final q = mentionQuery;
    if (!canMention || q == null) return const [];
    final ql = q.toLowerCase();
    return mentionCandidates
        .where((c) => c.username.toLowerCase().contains(ql))
        .take(6)
        .toList(growable: false);
  }

  /// Replaces the active `@token` with `@username ` and records the picked UID.
  void insertMention(MentionCandidate candidate) {
    final sel = replyController.selection;
    final text = replyController.text;
    if (!sel.isValid) return;
    final upToCaret = text.substring(0, sel.baseOffset);
    final at = upToCaret.lastIndexOf('@');
    if (at < 0) return;

    final mentionText = '@${candidate.username} ';
    final newText =
        text.substring(0, at) + mentionText + text.substring(sel.baseOffset);
    replyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: at + mentionText.length),
    );
    _pickedIdByUsername[candidate.username] = candidate.id;
    notifyListeners();
  }

  /// Resolves the UIDs to notify: picked mentions whose `@username` still
  /// appears in the sent text. Always empty for non-premium users (backstop:
  /// the server also drops mentions from free authors).
  List<String> _resolveMentions(String text) {
    if (!canMention) return const [];
    final ids = <String>{};
    _pickedIdByUsername.forEach((username, id) {
      if (text.contains('@$username')) ids.add(id);
    });
    return ids.toList();
  }

  /// Free-tier tap on the mention affordance → gate analytics + paywall.
  Future<void> openMentionPaywall() async {
    locator<AnalyticsService>().logGateHit(feature: PaywallFeature.mention);
    await PaywallHelper.show(feature: PaywallFeature.mention);
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

  bool _joining = false;
  bool get joining => _joining;

  Future<void> joinCommunity() async {
    if (_joining) return;
    _joining = true;
    notifyListeners();
    try {
      await locator<CommunityService>().joinCommunity(post.communityId);
      await _authService.checkCurrentUserStatus(); // Refresh user data locally
      HapticFeedback.lightImpact();
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
    } finally {
      _joining = false;
      notifyListeners();
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
    if (data != null) _reconcilePending(data);
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
    // Already capped this month — don't waste a call; nudge to the paywall.
    if (_replyCapReached) {
      await openReplyPaywall();
      return;
    }

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

    final mentionedUsers = _resolveMentions(text);

    replyController.clear();
    _pickedIdByUsername.clear();

    // Optimistic "Posting…" card shown instantly until the real reply streams
    // in (reconciled in onData) — or removed on cap/error/timeout.
    final pending = PendingContent(id: ++_pendingCounter, content: text);
    _pendingReplies.add(pending);
    notifyListeners();
    Future.delayed(const Duration(seconds: 15), () => _removePending(pending.id));

    try {
      final result = await locator<CommunityService>().createReply(
        postId: post.id,
        content: text,
        authorUsername: currentUserName,
        mentionedUsers: mentionedUsers, // premium only; free resolves to []
      );

      // Free user is out of monthly replies — restore the text, show the
      // persistent upgrade button, and open the paywall once immediately.
      if (result.capReached) {
        _removePending(pending.id);
        replyController.text = text;
        _replyCapReached = true;
        notifyListeners();
        await openReplyPaywall();
      }
    } catch (e) {
      _removePending(pending.id);
      _snackbarService.showSnackbar(
        title: 'Error',
        message: 'Could not send reply. Please try again.',
      );
    }
  }

  Future<void> toggleLike() async {
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

    try {
      await locator<CommunityService>().toggleLikePost(post.id, isLiked);
    } catch (_) {
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

  Future<void> toggleReplyLike(ThreadReply reply) async {
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

    try {
      await locator<CommunityService>().toggleLikeReply(post.id, reply.id, isLiked);
    } catch (_) {
      if (isLiked) {
        reply.likedBy.add(uid);
        reply.likeCount += 1;
      } else {
        reply.likedBy.remove(uid);
        reply.likeCount -= 1;
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
    _authService.removeListener(_onSubscriptionChanged);
    replyController.removeListener(_onReplyChanged);
    replyController.dispose();
    super.dispose();
  }
}
