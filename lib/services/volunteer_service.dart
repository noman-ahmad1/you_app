import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/models/volunteer_info_model.dart';

class VolunteerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<VolunteerInfo?> get(String uid) async {
    final doc = await _firestore.collection('volunteer_info').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;

    // Convert the Firestore Map to the VolunteerInfo model
    return VolunteerInfo.fromJson(doc.data()!);
  }

  // SET/CREATE: Save or overwrite the volunteer info document
  Future<void> saveInfo(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('volunteer_info').doc(uid).set(data);
  }

  // UPDATE: Generic update for the volunteer info document
  Future<void> update(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('volunteer_info').doc(uid).update(data);
  }

  /// Adds a review for a volunteer and updates their overall statistics.
  Future<void> addReviewAndCompleteChat({
    required String volunteerId,
    required String userId,
    required double rating,
    required String comment,
  }) async {
    final volunteerRef =
        _firestore.collection('volunteer_info').doc(volunteerId);
    final reviewsRef = volunteerRef.collection('reviews').doc();

    await _firestore.runTransaction((transaction) async {
      final volunteerDoc = await transaction.get(volunteerRef);

      if (!volunteerDoc.exists) {
        throw Exception("Volunteer not found");
      }

      final data = volunteerDoc.data()!;
      int completedChats = data['completedChats'] ?? 0;
      int totalReviews = data['totalReviews'] ?? 0;
      double averageRating = (data['averageRating'] ?? 0.0).toDouble();

      // Calculate new averages
      double newAverageRating =
          ((averageRating * totalReviews) + rating) / (totalReviews + 1);

      // Update volunteer document
      transaction.update(volunteerRef, {
        'completedChats': completedChats + 1,
        'totalReviews': totalReviews + 1,
        'averageRating': newAverageRating,
      });

      // Add the review document
      transaction.set(reviewsRef, {
        'userId': userId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
