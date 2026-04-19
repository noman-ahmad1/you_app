import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/user_service.dart';
import 'package:you_app/services/volunteer_service.dart';
import 'package:you_app/services/mood_service.dart';
import 'package:you_app/services/journal_service.dart';
import 'package:you_app/services/chat_service.dart';
import 'package:you_app/services/chat_request_service.dart';
import 'package:you_app/services/community_service.dart';

class CommunityChatViewModel extends StreamViewModel<QuerySnapshot> {
  final _navigationService = locator<NavigationService>();
  final _authService = locator<AuthenticationService>();
  final _snackbarService = locator<SnackbarService>();

  final String communityId;
  final String communityName;

  final TextEditingController messageController = TextEditingController();

  List<Map<String, dynamic>> get messages {
    if (data == null) return [];
    return data!.docs.map((doc) {
      final mapData = doc.data() as Map<String, dynamic>;
      mapData['id'] = doc.id;
      return mapData;
    }).toList();
  }

  String get currentUserId => _authService.currentUser?.uid ?? '';
  // Assuming your AppUser model has a fullName or firstName property
  String get currentUserName =>
      _authService.currentUser?.fullName ?? 'Anonymous';

  CommunityChatViewModel({
    required this.communityId,
    required this.communityName,
  });

  @override
  Stream<QuerySnapshot> get stream =>
      locator<CommunityService>().getCommunityMessages(communityId);

  @override
  void onData(QuerySnapshot? data) {
    setBusy(false);
  }

  @override
  void onError(error, StackTrace? stackTrace) {
    _snackbarService.showSnackbar(
      title: 'Error',
      message: 'Failed to load community messages.',
    );
    setBusy(false);
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();
    notifyListeners();

    try {
      await locator<CommunityService>().sendCommunityMessage(
        communityId: communityId,
        text: text,
        senderName: currentUserName,
      );
    } catch (e) {
      _snackbarService.showSnackbar(
        title: 'Error',
        message: 'Could not send message. Please try again.',
      );
    }
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
