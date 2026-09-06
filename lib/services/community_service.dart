import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/models/community_post.dart';
import 'package:you_app/models/thread_reply.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/base/firestore_base.dart';

/// Outcome of creating a community thread. When [capReached] is true the free
/// user has used their monthly thread allowance and should see the paywall.
class CreatePostResult {
  final bool capReached;
  const CreatePostResult({required this.capReached});
}

/// Outcome of creating a reply. When [capReached] is true the free user has used
/// their monthly reply allowance and should see the paywall.
class CreateReplyResult {
  final bool capReached;
  const CreateReplyResult({required this.capReached});
}

class CommunityService with FirestoreServiceMixin {
  AnalyticsService get _analytics => locator<AnalyticsService>();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

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

  // 1b. Stream a single community document (for live fields like isLocked).
  Stream<Map<String, dynamic>?> getCommunity(String communityId) {
    return db.collection('communities').doc(communityId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
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

  // 3. Create a new post in a community via the createCommunityPost callable.
  // The function enforces the free-tier monthly thread cap atomically and strips
  // mentions from free users (direct client writes to `posts` are denied by
  // rules). Returns capReached when the free monthly allowance is exhausted.
  Future<CreatePostResult> createPost({
    required String communityId,
    required String content,
    required String authorUsername,
    List<String> mentionedUsers = const [],
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const CreatePostResult(capReached: false);

    final result = await _functions.httpsCallable('createCommunityPost').call({
      'communityId': communityId,
      'content': content,
      'authorUsername': authorUsername,
      'mentionedUsers': mentionedUsers,
    });

    final data = Map<String, dynamic>.from(result.data as Map);
    if (data['capReached'] == true) {
      return const CreatePostResult(capReached: true);
    }

    _analytics.logCommunityPost(communityId: communityId);
    return const CreatePostResult(capReached: false);
  }

  /// 4. Stream the most recent replies for a post (thread).
  ///
  /// Bounded deliberately — this was unlimited, so a popular thread streamed
  /// every reply live. Note the query orders DESCENDING so the limit keeps the
  /// NEWEST replies (ordering ascending would have clipped the newest ones,
  /// which is the opposite of what a thread reader wants), then reverses in
  /// memory so the view still renders oldest-to-newest as before.
  Stream<List<ThreadReply>> getThreadReplies(String postId, {int limit = 100}) {
    return db
        .collection('posts')
        .doc(postId)
        .collection('replies')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ThreadReply.fromMap(doc.data(), doc.id))
            .toList()
            .reversed
            .toList());
  }

  // 5. Add a reply to a specific post via the createCommunityReply callable.
  // The function enforces the free-tier monthly reply cap atomically, increments
  // the parent post's replyCount, and strips mentions from free users (direct
  // client writes to the replies subcollection are denied by rules). Returns
  // capReached when the free monthly reply allowance is exhausted.
  Future<CreateReplyResult> createReply({
    required String postId,
    required String content,
    required String authorUsername,
    List<String> mentionedUsers = const [],
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const CreateReplyResult(capReached: false);

    final result = await _functions.httpsCallable('createCommunityReply').call({
      'postId': postId,
      'content': content,
      'authorUsername': authorUsername,
      'mentionedUsers': mentionedUsers,
    });

    final data = Map<String, dynamic>.from(result.data as Map);
    if (data['capReached'] == true) {
      return const CreateReplyResult(capReached: true);
    }

    _analytics.logCommunityReply(postId: postId);
    return const CreateReplyResult(capReached: false);
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
  Future<void> toggleLikeReply(
      String postId, String replyId, bool isLiked) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final replyRef =
        db.collection('posts').doc(postId).collection('replies').doc(replyId);

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

  // 8. Delete a thread (author only).
  //
  // Unlike CREATE — which must go through a callable because rules deny client
  // writes (the freemium cap would be bypassed otherwise) — DELETE is a direct
  // client write: firestore.rules already restricts it to the author or an admin.
  // The `onPostDeleted` Cloud Function cascades the replies subcollection.
  Future<void> deletePost(String postId) async {
    await db.collection('posts').doc(postId).delete();
  }

  // 9. Delete a reply (author only).
  //
  // The parent's `replyCount` is decremented by the `onReplyDeleted` trigger —
  // deliberately NOT here, since a client that dies mid-write would otherwise
  // leave the count wrong. Note the free monthly reply quota is NOT refunded:
  // delete-and-repost would be a cap bypass.
  Future<void> deleteReply(String postId, String replyId) async {
    await db
        .collection('posts')
        .doc(postId)
        .collection('replies')
        .doc(replyId)
        .delete();
  }

  // 10. Join a community
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
    batch.update(communityRef, {'membersCount': FieldValue.increment(1)});

    await batch.commit();
    _analytics.logCommunityJoined(communityId: communityId);
  }
}
