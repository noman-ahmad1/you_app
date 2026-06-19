import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/models/community_post.dart';
import 'package:you_app/models/thread_reply.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/base/firestore_base.dart';

class CommunityService with FirestoreServiceMixin {
  AnalyticsService get _analytics => locator<AnalyticsService>();


  // 1. Fetch all available communities (capped to avoid unbounded reads)
  Stream<List<Map<String, dynamic>>> getCommunities({int limit = 50}) {
    return db
        .collection('communities')
        .orderBy('membersCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // 2. Stream top-level posts for a specific community.
  // [limit] grows as the user loads more, so the result is always a superset
  // of the previous page (no flicker / reordering of already-shown posts).
  Stream<List<CommunityPost>> getCommunityPosts(String communityId,
      {int limit = 20}) {
    return db
        .collection('posts')
        .where('communityId', isEqualTo: communityId)
        .orderBy('likeCount', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
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

    await db.collection('posts').add(post.toMap());
    _analytics.logCommunityPost(communityId: communityId);
  }

  // 4. Stream replies for a specific post (thread)
  Stream<List<ThreadReply>> getThreadReplies(String postId) {
    return db
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

    final batch = db.batch();
    
    // Add the reply document
    final replyRef = db.collection('posts').doc(postId).collection('replies').doc();
    batch.set(replyRef, reply.toMap());

    // Increment the reply count on the parent post
    final postRef = db.collection('posts').doc(postId);
    batch.update(postRef, {'replyCount': FieldValue.increment(1)});

    await batch.commit();
    _analytics.logCommunityReply(postId: postId);
  }

  // 6. Toggle like on a post
  Future<void> toggleLikePost(String postId, bool isLiked) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final postRef = db.collection('posts').doc(postId);
    
    if (isLiked) {
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
    _analytics.logPostLiked(liked: !isLiked);
  }

  // 7. Toggle like on a reply
  Future<void> toggleLikeReply(String postId, String replyId, bool isLiked) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final replyRef = db.collection('posts').doc(postId).collection('replies').doc(replyId);
    
    if (isLiked) {
      await replyRef.update({
        'likedBy': FieldValue.arrayRemove([uid]),
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      await replyRef.update({
        'likedBy': FieldValue.arrayUnion([uid]),
        'likeCount': FieldValue.increment(1),
      });
    }
  }

  // 8. Join a community
  Future<void> joinCommunity(String communityId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final batch = db.batch();
    
    // Update the user's joinedCommunities list
    final userRef = db.collection('users').doc(uid);
    batch.update(userRef, {
      'joinedCommunities': FieldValue.arrayUnion([communityId])
    });

    // Optionally increment the members count in the community doc
    final communityRef = db.collection('communities').doc(communityId);
    batch.update(communityRef, {
      'membersCount': FieldValue.increment(1)
    });

    await batch.commit();
    _analytics.logCommunityJoined(communityId: communityId);
  }
}

