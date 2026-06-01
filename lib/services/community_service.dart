import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:you_app/models/community_post.dart';
import 'package:you_app/models/thread_reply.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Fetch all available communities
  Stream<List<Map<String, dynamic>>> getCommunities() {
    return _firestore.collection('communities').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // 2. Stream top-level posts for a specific community
  Stream<List<CommunityPost>> getCommunityPosts(String communityId) {
    return _firestore
        .collection('posts')
        .where('communityId', isEqualTo: communityId)
        .orderBy('likeCount', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityPost.fromMap(doc.data(), doc.id))
            .toList());
  }

  // 3. Create a new post in a community
  Future<void> createPost({
    required String communityId,
    required String content,
    required String authorUsername,
    List<String> mentionedUsers = const [],
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final post = CommunityPost(
      id: '', // Will be assigned by Firestore
      communityId: communityId,
      authorId: uid,
      authorUsername: authorUsername,
      content: content,
      createdAt: DateTime.now(), // Fallback for local, server handles it
      mentionedUsers: mentionedUsers,
    );

    await _firestore.collection('posts').add(post.toMap());
  }

  // 4. Stream replies for a specific post (thread)
  Stream<List<ThreadReply>> getThreadReplies(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ThreadReply.fromMap(doc.data(), doc.id))
            .toList());
  }

  // 5. Add a reply to a specific post
  Future<void> createReply({
    required String postId,
    required String content,
    required String authorUsername,
    List<String> mentionedUsers = const [],
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final reply = ThreadReply(
      id: '',
      postId: postId,
      authorId: uid,
      authorUsername: authorUsername,
      content: content,
      createdAt: DateTime.now(),
      mentionedUsers: mentionedUsers,
    );

    final batch = _firestore.batch();
    
    // Add the reply document
    final replyRef = _firestore.collection('posts').doc(postId).collection('replies').doc();
    batch.set(replyRef, reply.toMap());

    // Increment the reply count on the parent post
    final postRef = _firestore.collection('posts').doc(postId);
    batch.update(postRef, {'replyCount': FieldValue.increment(1)});

    await batch.commit();
  }

  // 6. Toggle like on a post
  Future<void> toggleLikePost(String postId, List<String> currentLikedBy) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final postRef = _firestore.collection('posts').doc(postId);
    
    if (currentLikedBy.contains(uid)) {
      // User has already liked it -> unlike
      await postRef.update({
        'likedBy': FieldValue.arrayRemove([uid]),
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      // User hasn't liked it -> like
      await postRef.update({
        'likedBy': FieldValue.arrayUnion([uid]),
        'likeCount': FieldValue.increment(1),
      });
    }
  }
}

