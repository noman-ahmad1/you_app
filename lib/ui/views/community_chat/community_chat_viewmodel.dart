import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/community_service.dart';
import 'package:you_app/models/community_post.dart';
import 'package:you_app/ui/views/community_chat/thread_replies_view.dart';

class CommunityChatViewModel extends StreamViewModel<List<CommunityPost>> {
  final _navigationService = locator<NavigationService>();
  final _authService = locator<AuthenticationService>();
  final _snackbarService = locator<SnackbarService>();

  final String communityId;
  final String communityName;

  final TextEditingController messageController = TextEditingController();

  List<CommunityPost> get posts => data ?? [];

  String get currentUserId => _authService.currentUser?.uid ?? '';
  String get currentUserName => _authService.currentUser?.fullName ?? 'Anonymous';

  CommunityChatViewModel({
    required this.communityId,
    required this.communityName,
  });

  @override
  Stream<List<CommunityPost>> get stream =>
      locator<CommunityService>().getCommunityPosts(communityId);

  @override
  void onData(List<CommunityPost>? data) {
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
    locator<CommunityService>().toggleLikePost(post.id, post.likedBy);
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

