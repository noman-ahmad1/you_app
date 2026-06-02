import 'package:cloud_firestore/cloud_firestore.dart';

class ThreadReply {
  final String id;
  final String postId;
  final String authorId;
  final String authorUsername;
  final String content;
  final DateTime createdAt;
  final List<String> mentionedUsers;
  final List<String> likedBy;
  int likeCount;

  ThreadReply({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorUsername,
    required this.content,
    required this.createdAt,
    this.mentionedUsers = const [],
    this.likedBy = const [],
    this.likeCount = 0,
  });

  factory ThreadReply.fromMap(Map<String, dynamic> data, String documentId) {
    return ThreadReply(
      id: documentId,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorUsername: data['authorUsername'] ?? 'Anonymous',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mentionedUsers: List<String>.from(data['mentionedUsers'] ?? []),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      likeCount: data['likeCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorUsername': authorUsername,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'mentionedUsers': mentionedUsers,
      'likedBy': likedBy,
      'likeCount': likeCount,
    };
  }
}
