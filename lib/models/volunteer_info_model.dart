import 'package:cloud_firestore/cloud_firestore.dart';

/// The PUBLIC half of a volunteer's application — readable by any signed-in
/// user, because the discovery UI shows tags, institution and ratings.
///
/// Identity-document URLs deliberately do NOT live here. They are stored in
/// `volunteer_info/{uid}/private/vetting` and reachable only via
/// [VolunteerService.getVetting], for the owner and admins. Those URLs carry
/// their own Storage access token, so putting them on a world-readable
/// document handed every user a download link to a volunteer's national ID.
class VolunteerInfo {
  final String uid;
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
