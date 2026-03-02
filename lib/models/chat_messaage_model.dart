import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single message document in the `messages` subcollection.
class ChatMessage {
  final String? id; // The document ID from Firestore (optional)
  final String senderId;
  final String text;
  final DateTime? timestamp;

  ChatMessage({
    this.id,
    required this.senderId,
    required this.text,
    this.timestamp,
  });

  /// Creates a ChatMessage instance from a Firestore data map.
  factory ChatMessage.fromJson(Map<String, dynamic> data) {
    return ChatMessage(
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      // Safely convert Firestore Timestamp to DateTime
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts the ChatMessage instance into a map for saving to Firestore.
  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'text': text,
      // Let Firestore's server generate the timestamp for accuracy
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
