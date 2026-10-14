/// An in-app notification from `users/{uid}/notifications`.
///
/// A plain Dart object: no Firestore types leak past the service that builds
/// it (see InAppNotificationService).
class AppNotification {
  final String id;
  final String title;
  final String body;

  /// e.g. `new_message`, `request_accepted`, `request_received`, `chat_request`.
  final String type;
  final bool isRead;
  final DateTime? createdAt;

  /// Free-form routing payload, e.g. `{chatId: ..., requestId: ...}`.
  final Map<String, dynamic> data;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.data,
  });

  String? get chatId => data['chatId'] as String?;
  String? get requestId => data['requestId'] as String?;

  /// [createdAt] must already be a [DateTime] — the service converts it.
  factory AppNotification.fromMap(
      String id, Map<String, dynamic> map, DateTime? createdAt) {
    final raw = map['data'];
    return AppNotification(
      id: id,
      title: map['title'] as String? ?? 'Notification',
      body: map['body'] as String? ?? '',
      type: map['type'] as String? ?? '',
      isRead: map['isRead'] as bool? ?? false,
      createdAt: createdAt,
      data: raw is Map ? Map<String, dynamic>.from(raw) : const {},
    );
  }
}

/// One emission of the unread-notifications stream.
class UnreadNotifications {
  final int count;

  /// Notifications that arrived since the previous emission. Always empty on
  /// the first emission, so already-waiting notifications don't all pop a
  /// banner the moment the screen opens.
  final List<AppNotification> added;

  const UnreadNotifications({required this.count, required this.added});
}
