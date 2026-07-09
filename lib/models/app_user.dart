import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/ui/common/app_constants.dart';

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
  final String? fcmToken;
  final List<String> joinedCommunities;
  final String subscriptionTier; // 'free' | 'premium'
  final DateTime? subscriptionExpiry; // null => no expiry (indefinite grant)
  final String? subscriptionSource; // e.g. 'admin', 'promo'

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
    this.fcmToken,
    this.joinedCommunities = const [],
    this.subscriptionTier = 'free',
    this.subscriptionExpiry,
    this.subscriptionSource,
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
      fcmToken: data['fcmToken'],
      joinedCommunities: data['joinedCommunities'] != null
          ? List<String>.from(data['joinedCommunities'])
          : [],
      subscriptionTier: data['subscriptionTier'] ?? 'free',
      subscriptionExpiry: (data['subscription_expiry'] as Timestamp?)?.toDate(),
      subscriptionSource: data['subscription_source'],
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
  bool get isPremium =>
      subscriptionTier == 'premium' &&
      (subscriptionExpiry == null || subscriptionExpiry!.isAfter(DateTime.now()));

  String get defaultAvatar {
    final g = gender?.toLowerCase();
    if (g == 'female') {
      return AppConstants.avatarFemale;
    } else if (g == 'male') {
      return AppConstants.avatar;
    } else {
      return AppConstants.avatarBinary;
    }
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    UserRole? role,
    String? profilePictureUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? username,
    String? phoneNumber,
    bool? emailVerified,
    bool? phoneVerified,
    String? status,
    String? availabilityStatus,
    DateTime? createdAt,
    List<String>? permissions,
    String? fcmToken,
    List<String>? joinedCommunities,
    String? subscriptionTier,
    DateTime? subscriptionExpiry,
    String? subscriptionSource,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      // Carry these through — omitting them previously wiped the fields on any
      // copyWith (e.g. flipping emailVerified would drop username/gender/etc.).
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      status: status ?? this.status,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      createdAt: createdAt ?? this.createdAt,
      permissions: permissions ?? this.permissions,
      fcmToken: fcmToken ?? this.fcmToken,
      joinedCommunities: joinedCommunities ?? this.joinedCommunities,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      subscriptionSource: subscriptionSource ?? this.subscriptionSource,
    );
  }
}
