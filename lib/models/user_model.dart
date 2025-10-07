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
    this.createdAt,
    this.permissions,
  });

  String get fullName => '$firstName $lastName';
  bool get isVolunteer => role == UserRole.volunteer;
  bool get isAdmin => role == UserRole.admin;
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
      createdAt: createdAt ?? this.createdAt,
      permissions: permissions ?? this.permissions,
    );
  }
}
