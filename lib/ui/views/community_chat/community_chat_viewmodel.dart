import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/firestore_service.dart';

class CommunityChatViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _firestoreService = locator<FirestoreService>();
  final _authService = locator<AuthenticationService>();

  final String communityId;
  final String communityName;

  final TextEditingController messageController = TextEditingController();

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;

  StreamSubscription? _messagesSubscription;

  String get currentUserId => _authService.currentUser?.uid ?? '';
  // Assuming your AppUser model has a fullName or firstName property
  String get currentUserName =>
      _authService.currentUser?.fullName ?? 'Anonymous';

  CommunityChatViewModel({
    required this.communityId,
    required this.communityName,
  });

  void listenToMessages() {
    setBusy(true);
    _messagesSubscription = _firestoreService.community
        .getCommunityMessages(communityId)
        .listen((snapshot) {
      _messages = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Keep the document ID just in case
        return data;
      }).toList();

      setBusy(false);
      notifyListeners();
    }, onError: (error) {
      print("Error listening to community messages: $error");
      setBusy(false);
    });
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();
    notifyListeners();

    try {
      await _firestoreService.community.sendCommunityMessage(
        communityId: communityId,
        text: text,
        senderName: currentUserName,
      );
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  void back() {
    _navigationService.back();
  }

  @override
  void dispose() {
    messageController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
