import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// 1. Fetch all available communities
  Stream<List<Map<String, dynamic>>> getCommunities() {
    return _firestore.collection('communities').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Inject the document ID
        return data;
      }).toList();
    });
  }

// 2. Stream messages for a specific community
  Stream<QuerySnapshot> getCommunityMessages(String communityId) {
    return _firestore
        .collection('communities')
        .doc(communityId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

// 3. Send a message to a community
  Future<void> sendCommunityMessage({
    required String communityId,
    required String text,
    required String senderName,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('communities')
        .doc(communityId)
        .collection('messages')
        .add({
      'senderId': uid,
      'senderName': senderName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
