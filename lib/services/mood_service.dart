import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:you_app/models/mood_model.dart';

class MoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to add a new mood entry
  Future<void> saveMoodEntry(MoodEntry entry) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint('Save Error: No authenticated user.');
      return;
    }

    try {
      final data = {
        'userId': userId,
        'moodLabel': entry.moodLabel,
        'timestamp': FieldValue.serverTimestamp(),
        'extraField': entry.extraField,
      };

      await _firestore.collection('mood').add(data);
      debugPrint('✅ Mood entry saved for $userId - ${entry.moodLabel}');
    } on FirebaseException catch (e) {
      debugPrint('🔥 Firebase Save Error: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('💥 General Save Error: $e');
    }
  }

  // Stream entries for the current user (filtered by userId)
  Stream<List<MoodEntry>> getUserMoodStream(String userId) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    return _firestore
        .collection('mood')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: thirtyDaysAgo)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MoodEntry.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Admin View: Fetch all mood entries (no user filter)
  Future<List<MoodEntry>> getAllMoodEntriesForAdmin() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint('⚠️ No authenticated user.');
      return [];
    }

    // Optional: verify if user is admin
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final isAdmin = userDoc.data()?['role'] == 'admin';
    if (!isAdmin) {
      debugPrint('🚫 Access denied. User is not an admin.');
      return [];
    }

    try {
      final querySnapshot = await _firestore
          .collection('mood')
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MoodEntry.fromFirestore(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      debugPrint('🔥 Firebase Fetch Error: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      debugPrint('💥 General Fetch Error: $e');
      return [];
    }
  }
}
