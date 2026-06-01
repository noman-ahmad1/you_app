import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/community_service.dart';
import 'package:you_app/models/community_post.dart';
import 'package:you_app/models/thread_reply.dart';

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
  });

  @override
  Stream<List<ThreadReply>> get stream =>
      locator<CommunityService>().getThreadReplies(post.id);

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

    replyController.clear();
    notifyListeners();

    try {
      final words = text.split(' ');
      List<String> mentionedUsernames = words
          .where((w) => w.startsWith('@') && w.length > 1)
          .map((w) => w.substring(1))
          .toList();

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
    locator<CommunityService>().toggleLikePost(post.id, post.likedBy);
  }

  void back() {
    _navigationService.back();
  }

  @override
  void dispose() {
    replyController.dispose();
    super.dispose();
  }
}
