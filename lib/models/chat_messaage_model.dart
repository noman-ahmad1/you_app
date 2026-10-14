import 'package:you_app/models/model_codec.dart';

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
      timestamp: parseModelDate(data['timestamp']),
    );
  }

  /// Converts the ChatMessage instance into a map for saving to Firestore.
  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'text': text,
      // Let the server generate the timestamp for accuracy
      'timestamp': serverTimestamp,
    };
  }
}
