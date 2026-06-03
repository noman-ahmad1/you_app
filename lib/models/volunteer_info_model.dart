import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the application and academic details specific to a volunteer.
/// This model separates detailed volunteer data from the core AppUser data.
class VolunteerInfo {
  final String uid;
  final String? idCardUrl;
  final String? idCardBackUrl;
  final String? studentIdUrl;
  final String? studentIdBackUrl;
  final String? currentLevelOfStudy;
  final String? institutionName;
  final String? graduationYear;
  final List<String>? tags;
  final bool agreementAccepted;
  final String status;

  /// Timestamp of when the application was created.
  final DateTime? createdAt;

  // Statistics
  final int completedChats;
  final double averageRating;
  final int totalReviews;

  VolunteerInfo({
    required this.uid,
    this.idCardUrl,
    this.idCardBackUrl,
    this.studentIdUrl,
    this.studentIdBackUrl,
    this.currentLevelOfStudy,
    this.institutionName,
    this.graduationYear,
    this.tags,
    required this.agreementAccepted,
    this.status = 'pending_verification', // Default status
    this.createdAt,
    this.completedChats = 0,
    this.averageRating = 0.0,
    this.totalReviews = 0,
  });

  // --- Serialization ---

  factory VolunteerInfo.fromJson(Map<String, dynamic> data) {
    return VolunteerInfo(
      uid: data['uid'] as String,
      idCardUrl: data['idCardUrl'] as String?,
      idCardBackUrl: data['idCardBackUrl'] as String?,
      studentIdUrl: data['studentIdUrl'] as String?,
      studentIdBackUrl: data['studentIdBackUrl'] as String?,
      currentLevelOfStudy: data['currentLevelOfStudy'] as String?,
      institutionName: data['institutionName'] as String?,
      graduationYear: data['graduationYear'] as String?,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      agreementAccepted: data['agreementAccepted'] as bool? ?? false,
      status: data['status'] as String? ?? 'pending_verification',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : data['createdAt'] != null
              ? DateTime.parse(data['createdAt'])
              : null,
      completedChats: data['completedChats'] as int? ?? 0,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: data['totalReviews'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'idCardUrl': idCardUrl,
      'idCardBackUrl': idCardBackUrl,
      'studentIdUrl': studentIdUrl,
      'studentIdBackUrl': studentIdBackUrl,
      'currentLevelOfStudy': currentLevelOfStudy,
      'institutionName': institutionName,
      'graduationYear': graduationYear,
      'tags': tags,
      'agreementAccepted': agreementAccepted,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'completedChats': completedChats,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
    };
  }
}
