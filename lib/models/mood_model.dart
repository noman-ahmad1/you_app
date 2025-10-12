import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/ui/common/app_constants.dart';

// --- Mood Configuration Map (The Source of Truth) ---
// This map allows us to look up the associated emoji/asset
// using the descriptive label, which is the only value stored in Firestore.
const Map<String, Map<String, dynamic>> moodDataMap = {
  'Energized': {'assetId': AppConstants.emoji_1},
  'Joyful': {'assetId': AppConstants.emoji_2},
  'Blessed': {'assetId': AppConstants.emoji_3},
  'Happy': {'assetId': AppConstants.emoji_4},
  'Neutral': {'assetId': AppConstants.emoji_5},
  'Sad': {'assetId': AppConstants.emoji_6},
  'Restless': {'assetId': AppConstants.emoji_7},
  'Anxious': {'assetId': AppConstants.emoji_8},
  'Angry': {'assetId': AppConstants.emoji_9},
};

Map<String, String> get assetToLabelMap {
  final Map<String, String> inverseMap = {};
  moodDataMap.forEach((label, data) {
    final assetId = data['assetId'] as String;
    inverseMap[assetId] = label;
  });
  return inverseMap;
}

// --- Mood Entry Model ---
class MoodEntry {
  final String id;
  final String userId;
  final String moodLabel; // The only field used for identification in Firestore
  final dynamic extraField;

  // Derived properties, calculated from moodLabel
  final String moodId; // Renamed to moodId, but represents the emoji/asset name

  // Timestamp data
  final String timestamp; // ISO 8601 string of when it was recorded
  final String dateOnly; // YYYY-MM-DD string

  MoodEntry({
    required this.id,
    required this.userId,
    required this.moodLabel,
    required this.moodId,
    required this.timestamp,
    required this.dateOnly,
    this.extraField,
  });

  // Factory constructor for creating a MoodEntry instance before saving.
  // This constructor takes the core data and uses the map to derive score/id.
  factory MoodEntry.create(String userId, String label, {dynamic extraField}) {
    final now = DateTime.now();
    final data =
        moodDataMap[label] ?? moodDataMap['Neutral']!; // Default to Neutral

    return MoodEntry(
      id: '', // Empty ID when creating, Firestore service will handle it
      userId: userId,
      moodLabel: label,
      moodId: data['assetId'] as String,
      timestamp: now.toIso8601String(),
      dateOnly: now.toIso8601String().split('T').first,
      extraField: extraField,
    );
  }

  // Factory constructor to create a MoodEntry from a Firestore map
  factory MoodEntry.fromFirestore(Map<String, dynamic> data, String docId) {
    final label = data['moodLabel'] as String? ?? 'Neutral';
    final derivedData = moodDataMap[label] ?? moodDataMap['Neutral']!;

    // Safely handle Firestore Timestamp object
    String formattedTimestamp;
    if (data['timestamp'] is Timestamp) {
      formattedTimestamp =
          (data['timestamp'] as Timestamp).toDate().toIso8601String();
    } else {
      formattedTimestamp =
          data['timestamp'] as String? ?? DateTime.now().toIso8601String();
    }

    return MoodEntry(
      id: docId,
      userId: data['userId'] ?? '',
      moodLabel: label,
      moodId: derivedData['assetId'] as String,
      timestamp: formattedTimestamp,
      dateOnly: formattedTimestamp.split('T').first,
      extraField: data['extraField'],
    );
  }

  // Method to prepare the minimum data required for saving to Firestore.
  Map<String, dynamic> toFirestore(String userId) {
    return {
      'userId': userId,
      'moodLabel': moodLabel, // Only the label is saved
      'extraField': extraField,
      // Note: 'timestamp' will be added by FieldValue.serverTimestamp() in the service.
    };
  }
}
