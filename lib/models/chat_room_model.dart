import 'package:you_app/models/model_codec.dart';

/// Represents the top-level chat room document in the `chats` collection.
class ChatRoom {
  final String id; // The document ID (e.g., userA_volunteerB)
  final List<String> participants; // List of participant UIDs
  final Map<String, dynamic> participantInfo; // Stores names, avatars, etc.
  final DateTime? createdAt; // Timestamp of the first message
  final Map<String, dynamic>? lastMessage; // A map of the last message details

  ChatRoom({
    required this.id,
    required this.participants,
    required this.participantInfo,
    this.createdAt,
    this.lastMessage,
  });

  /// Creates a ChatRoom from a stored document's [id] and [data].
  factory ChatRoom.fromMap(String id, Map<String, dynamic> data) {
    return ChatRoom(
      id: id,
      participants: List<String>.from(data['participants'] ?? []),
      participantInfo: Map<String, dynamic>.from(data['participantInfo'] ?? {}),
      createdAt: parseModelDate(data['createdAt']),
      lastMessage: data['lastMessage'] != null
          ? Map<String, dynamic>.from(data['lastMessage'])
          : null,
    );
  }

  /// Converts the ChatRoom instance into a map for saving to Firestore.
  Map<String, dynamic> toJson() {
    return {
      'participants': participants,
      'participantInfo': participantInfo,
      'createdAt': serverTimestamp, // Set on creation
      'lastMessage': lastMessage,
    };
  }
}
