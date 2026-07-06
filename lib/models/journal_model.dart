import 'package:cloud_firestore/cloud_firestore.dart';

// An enum for the labels ensures type safety.
enum JournalLabel { personal, work }

// The medium of the entry: a typed note or a voice recording.
enum JournalType { text, voice }

class JournalEntry {
  final String? id; // Nullable, as it doesn't exist before saving
  final String userId;
  final String title;
  final String content;
  final JournalLabel label; // Use the enum here
  final JournalType type; // text (default) vs voice
  final String? audioUrl; // download URL for voice entries
  final int? audioDurationMs; // recording length for voice entries
  final DateTime? timestamp;

  JournalEntry({
    this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.label,
    this.type = JournalType.text,
    this.audioUrl,
    this.audioDurationMs,
    this.timestamp,
  });

  bool get isVoice => type == JournalType.voice;

  /// `m:ss` label for a voice entry's length (e.g. `0:34`).
  String get audioDurationLabel {
    final total = ((audioDurationMs ?? 0) / 1000).round();
    final m = total ~/ 60;
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

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
      // Legacy docs have no 'type' — default them to text.
      type: JournalType.values.byName(data['type'] ?? 'text'),
      audioUrl: data['audioUrl'] as String?,
      audioDurationMs: (data['audioDurationMs'] as num?)?.toInt(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'label': label.name, // Store the enum as a string (e.g., 'personal')
      'type': type.name, // 'text' | 'voice'
      // Only voice entries carry an audio payload.
      if (audioUrl != null) 'audioUrl': audioUrl,
      if (audioDurationMs != null) 'audioDurationMs': audioDurationMs,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
