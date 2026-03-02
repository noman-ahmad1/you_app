import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRequest {
  final String? id; // The document ID from Firestore
  final String requesterId;
  final String requesterName;
  final String? requesterAvatarUrl;
  final String volunteerId;
  final String status;
  final DateTime? createdAt;
  final String? topic;

  ChatRequest({
    this.id,
    required this.requesterId,
    required this.requesterName,
    this.requesterAvatarUrl,
    required this.volunteerId,
    this.status = 'pending',
    this.createdAt,
    this.topic,
  });

  /// Converts the ChatRequest instance into a map for saving to Firestore.
  Map<String, dynamic> toJson() {
    return {
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterAvatarUrl': requesterAvatarUrl,
      'volunteerId': volunteerId,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(), // Let the server set the time
      'topic': topic,
    };
  }

  /// Creates a ChatRequest instance from a Firestore document snapshot.
  factory ChatRequest.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ChatRequest(
      id: doc.id,
      requesterId: data['requesterId'],
      requesterName: data['requesterName'],
      requesterAvatarUrl: data['requesterAvatarUrl'],
      volunteerId: data['volunteerId'],
      status: data['status'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      topic: data['topic'],
    );
  }
}
