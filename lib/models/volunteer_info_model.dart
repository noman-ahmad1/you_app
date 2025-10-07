import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the application and academic details specific to a volunteer.
/// This model separates detailed volunteer data from the core AppUser data.
class VolunteerInfo {
  final String uid;
  final String? idCardUrl;
  final String? studentIdUrl;
  final String? currentLevelOfStudy;
  final String? institutionName;
  final String? graduationYear;
  final String? specializationCategory;
  final bool agreementAccepted;
  final String status;

  /// Timestamp of when the application was created.
  final DateTime? createdAt;

  VolunteerInfo({
    required this.uid,
    this.idCardUrl,
    this.studentIdUrl,
    this.currentLevelOfStudy,
    this.institutionName,
    this.graduationYear,
    this.specializationCategory,
    required this.agreementAccepted,
    this.status = 'pending_verification', // Default status
    this.createdAt,
  });

  // --- Serialization ---

  factory VolunteerInfo.fromJson(Map<String, dynamic> data) {
    return VolunteerInfo(
      uid: data['uid'] as String,
      idCardUrl: data['idCardUrl'] as String?,
      studentIdUrl: data['studentIdUrl'] as String?,
      currentLevelOfStudy: data['currentLevelOfStudy'] as String?,
      institutionName: data['institutionName'] as String?,
      graduationYear: data['graduationYear'] as String?,
      specializationCategory: data['specializationCategory'] as String?,
      agreementAccepted: data['agreementAccepted'] as bool? ?? false,
      status: data['status'] as String? ?? 'pending_verification',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : data['createdAt'] != null
              ? DateTime.parse(data['createdAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'idCardUrl': idCardUrl,
      'studentIdUrl': studentIdUrl,
      'currentLevelOfStudy': currentLevelOfStudy,
      'institutionName': institutionName,
      'graduationYear': graduationYear,
      'specializationCategory': specializationCategory,
      'agreementAccepted': agreementAccepted,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
