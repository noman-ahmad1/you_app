import 'package:you_app/models/model_codec.dart';

class ChatRequest {
  final String? id; // The document ID from Firestore
  final String requesterId;
  final String requesterName;
  final String? requesterAvatarUrl;
  final String volunteerId;

  /// The volunteer's display name, stamped when the request is accepted so the
  /// requester can address them (e.g. in the post-chat review dialog) without a
  /// separate lookup. Null for legacy/pending requests.
  final String? volunteerName;
  final String status;
  final DateTime? createdAt;

  /// When the volunteer accepted the request. Drives the 24-hour auto-expiry:
  /// the chat ends automatically 24 hours after this moment. Null while pending
  /// (and for legacy accepted requests created before this field existed).
  final DateTime? acceptedAt;

  /// When the chat was ended/expired. Only set by the auto-expiry and the
  /// end-chat flows, so its presence marks a chat eligible for a review prompt.
  final DateTime? endedAt;

  /// Whether the requester has already been prompted to review this chat
  /// (submitted or skipped). Prevents the review dialog from re-appearing.
  final bool userReviewed;
  final String? topic;

  ChatRequest({
    this.id,
    required this.requesterId,
    required this.requesterName,
    this.requesterAvatarUrl,
    required this.volunteerId,
    this.volunteerName,
    this.status = 'pending',
    this.createdAt,
    this.acceptedAt,
    this.endedAt,
    this.userReviewed = false,
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
      'createdAt': serverTimestamp, // Let the server set the time
      'topic': topic,
    };
  }

  /// Creates a ChatRequest from a stored document's [id] and [data].
  factory ChatRequest.fromMap(String id, Map<String, dynamic> data) {
    return ChatRequest(
      id: id,
      requesterId: data['requesterId'],
      requesterName: data['requesterName'],
      requesterAvatarUrl: data['requesterAvatarUrl'],
      volunteerId: data['volunteerId'],
      volunteerName: data['volunteerName'] as String?,
      status: data['status'],
      createdAt: parseModelDate(data['createdAt']),
      acceptedAt: parseModelDate(data['acceptedAt']),
      endedAt: parseModelDate(data['endedAt']),
      userReviewed: data['userReviewed'] == true,
      topic: data['topic'],
    );
  }
}
