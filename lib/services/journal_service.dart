import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:you_app/models/journal_model.dart';

class JournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adds a new journal entry to a subcollection for the current user.
  Future<void> addJournalEntry(JournalEntry entry) async {
    try {
      // Storing entries in a subcollection is a secure and scalable pattern.
      final journalCollection = _firestore
          .collection('users')
          .doc(entry.userId)
          .collection('journal')
          .withConverter<JournalEntry>(
            fromFirestore: JournalEntry.fromFirestore,
            toFirestore: (journalEntry, _) => journalEntry.toFirestore(),
          );

      await journalCollection.add(entry);
    } catch (e) {
      // In a real app, log this error to a service like Sentry or Firebase Crashlytics
      print('Error adding journal entry: $e');
      // Rethrow the exception so the ViewModel can catch it and show a dialog
      rethrow;
    }
  }

  Stream<List<JournalEntry>> getJournalEntriesStream({required String userId}) {
    final journalCollection = _firestore
        .collection('users')
        .doc(userId)
        .collection('journal') // The name you chose in your rules
        .orderBy('timestamp', descending: true) // Sorts with latest on top
        .withConverter<JournalEntry>(
          fromFirestore: JournalEntry.fromFirestore,
          toFirestore: (entry, _) => entry.toFirestore(),
        );

    // .snapshots() returns a Stream. The .map() converts the raw snapshot
    // into a clean List<JournalEntry>.
    return journalCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> updateJournalEntry({
    required String userId,
    required String entryId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('journal')
          .doc(entryId)
          .update(data);
    } catch (e) {
      debugPrint("Error updating journal entry: $e");
      rethrow;
    }
  }

  Future<void> deleteJournalEntry({
    required String userId,
    required String entryId,
  }) async {
    try {
      // Construct the exact path to the document to be deleted.
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('journal') // Ensure this matches your collection name
          .doc(entryId)
          .delete();
    } catch (e) {
      // Log the error for debugging purposes.
      debugPrint("Error deleting journal entry: $e");
      // Rethrow the exception so the ViewModel can catch it and show an error dialog to the user.
      rethrow;
    }
  }
}
