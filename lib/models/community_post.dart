import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String communityId;
  final String authorId;
  final String authorUsername;
  final String content;
  final DateTime createdAt;
  int likeCount;
  final int replyCount;
  final List<String> mentionedUsers;
  List<String> likedBy;

  CommunityPost({
    required this.id,
    required this.communityId,
    required this.authorId,
    required this.authorUsername,
    required this.content,
    required this.createdAt,
    this.likeCount = 0,
    this.replyCount = 0,
    this.mentionedUsers = const [],
    this.likedBy = const [],
  });

  factory CommunityPost.fromMap(Map<String, dynamic> data, String documentId) {
    return CommunityPost(
      id: documentId,
      communityId: data['communityId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorUsername: data['authorUsername'] ?? 'Anonymous',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likeCount: data['likeCount'] ?? 0,
      replyCount: data['replyCount'] ?? 0,
      mentionedUsers: List<String>.from(data['mentionedUsers'] ?? []),
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'communityId': communityId,
      'authorId': authorId,
      'authorUsername': authorUsername,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'likeCount': likeCount,
      'replyCount': replyCount,
      'mentionedUsers': mentionedUsers,
      'likedBy': likedBy,
    };
  }
}
