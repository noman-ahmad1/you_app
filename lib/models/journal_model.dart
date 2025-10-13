import 'package:cloud_firestore/cloud_firestore.dart';

// An enum for the labels ensures type safety.
enum JournalLabel { personal, work }

class JournalEntry {
  final String? id; // Nullable, as it doesn't exist before saving
  final String userId;
  final String title;
  final String content;
  final JournalLabel label; // Use the enum here
  final DateTime? timestamp;

  JournalEntry({
    this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.label,
    this.timestamp,
  });

  // --- FIRESTORE CONVERTERS ---

  factory JournalEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return JournalEntry(
      id: snapshot.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      // Convert the string from Firestore back to an enum
      label: JournalLabel.values.byName(data['label'] ?? 'personal'),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'label': label.name, // Store the enum as a string (e.g., 'personal')
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
