import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, volunteer, admin }

enum AuthStatus { authenticated, unauthenticated, pendingVerification }

class AppUser {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final String? profilePictureUrl; // For Volunteer and Admin
  final DateTime? dateOfBirth; // For User and Volunteer
  final String? gender; // For User and Volunteer
  final String? username; // For User (must be distinct)
  final String? phoneNumber;
  final bool emailVerified;
  final bool phoneVerified;
  final String status;
  final String availabilityStatus;
  final DateTime? createdAt;
  final List<String>? permissions;

  AppUser({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.profilePictureUrl,
    this.dateOfBirth,
    this.gender,
    this.username,
    this.phoneNumber,
    required this.emailVerified,
    required this.phoneVerified,
    required this.status,
    this.availabilityStatus = 'offline',
    this.createdAt,
    this.permissions,
  });

  factory AppUser.fromJson(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      // Convert the string from Firestore back to a UserRole enum
      role: UserRole.values.byName(data['role'] ?? 'user'),
      profilePictureUrl: data['profilePictureUrl'],
      // Convert Firestore Timestamp back to DateTime, handling nulls
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      gender: data['gender'],
      username: data['username'],
      phoneNumber: data['phoneNumber'],
      emailVerified: data['emailVerified'] ?? false,
      phoneVerified: data['phoneVerified'] ?? false,
      status: data['status'] ?? 'active',
      availabilityStatus: data['availabilityStatus'] ?? 'offline',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      // Ensure the list from Firestore is correctly typed as List<String>
      permissions: data['permissions'] != null
          ? List<String>.from(data['permissions'])
          : null,
    );
  }

  String get fullName => '$firstName $lastName';
  bool get isVolunteer => role == UserRole.volunteer;
  bool get isAdmin => role == UserRole.admin;
  bool get isOnline => availabilityStatus == 'online';
  bool get isVerified =>
      emailVerified && (role == UserRole.user || phoneVerified);
  bool get canManageUsers =>
      isAdmin && (permissions?.contains('manage_users') ?? true);
  bool get canManageContent =>
      isAdmin && (permissions?.contains('manage_content') ?? true);
  bool get canViewAnalytics =>
      isAdmin && (permissions?.contains('view_analytics') ?? true);

  AppUser copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    UserRole? role,
    String? phoneNumber,
    bool? emailVerified,
    bool? phoneVerified,
    String? status,
    String? availabilityStatus,
    DateTime? createdAt,
    List<String>? permissions,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      status: status ?? this.status,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      createdAt: createdAt ?? this.createdAt,
      permissions: permissions ?? this.permissions,
    );
  }
}
