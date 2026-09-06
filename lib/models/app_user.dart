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

  /// Admin-authored reason shown to the user when their account is blocked
  /// (suspended/banned). Written only by the admin panel.
  final String? statusReason;

  /// The volunteer's availability toggle — 'online' | 'offline'. This alone
  /// decides whether they appear in discovery: once on, it stays on until they
  /// switch it off (or sign out, which deletes their FCM token and so makes them
  /// unreachable anyway).
  final String availabilityStatus;

  /// When the volunteer's app was last alive. Advisory only — nothing gates on
  /// it today. It exists so the admin panel can spot dormant volunteers, and so
  /// staleness expiry can be switched on later without an app release. See
  /// PresenceService.
  final DateTime? lastSeen;

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
    this.statusReason,
    this.availabilityStatus = 'offline',
    this.lastSeen,
    this.createdAt,
    this.permissions,
    this.fcmToken,
    this.joinedCommunities = const [],
    this.subscriptionTier = 'free',
    this.subscriptionExpiry,
    this.subscriptionSource,
  });

  /// Parses a role string without throwing. An unrecognised value degrades to
  /// [UserRole.user] rather than killing the auth stream.
  static UserRole _roleFrom(dynamic raw) {
    final name = raw is String ? raw : 'user';
    for (final role in UserRole.values) {
      if (role.name == name) return role;
    }
    return UserRole.user;
  }

  /// Coerces the several shapes a date has taken in this collection over time
  /// (Timestamp, ISO string, DateTime) into a DateTime, or null if unparseable.
  static DateTime? _dateFrom(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  factory AppUser.fromJson(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      // Convert the string from Firestore back to a UserRole enum. byName()
      // THROWS on an unknown value, and this runs inside the auth stream — a
      // future role like 'moderator' would take down sign-in for that account.
      role: _roleFrom(data['role']),
      profilePictureUrl: data['profilePictureUrl'],
      // Convert Firestore Timestamp back to DateTime, handling nulls
      dateOfBirth: _dateFrom(data['dateOfBirth']),
      gender: data['gender'],
      username: data['username'],
      phoneNumber: data['phoneNumber'],
      emailVerified: data['emailVerified'] ?? false,
      phoneVerified: data['phoneVerified'] ?? false,
      status: data['status'] ?? 'active',
      statusReason: data['statusReason'],
      availabilityStatus: data['availabilityStatus'] ?? 'offline',
      lastSeen: _dateFrom(data['lastSeen']),
      createdAt: _dateFrom(data['createdAt']),
      // Ensure the list from Firestore is correctly typed as List<String>
      permissions: data['permissions'] != null
          ? List<String>.from(data['permissions'])
          : null,
      fcmToken: data['fcmToken'],
      joinedCommunities: data['joinedCommunities'] != null
          ? List<String>.from(data['joinedCommunities'])
          : [],
      subscriptionTier: data['subscriptionTier'] ?? 'free',
      subscriptionExpiry: _dateFrom(data['subscription_expiry']),
      subscriptionSource: data['subscription_source'],
    );
  }

  String get fullName => '$firstName $lastName';
  bool get isVolunteer => role == UserRole.volunteer;
  bool get isAdmin => role == UserRole.admin;
  bool get isOnline => availabilityStatus == 'online';
  bool get isVerified =>
      emailVerified && (role == UserRole.user || phoneVerified);

  /// Account statuses that must deny access entirely. The admin panel sets
  /// `suspended`/`banned` as moderation actions; `deleted` is the soft-delete
  /// convention. A blocked user is signed out — see
  /// AuthenticationService._enforceAccountStatus.
  static const Set<String> blockedStatuses = {'suspended', 'banned', 'deleted'};
  bool get isBlocked => blockedStatuses.contains(status);
  bool get canManageUsers =>
      isAdmin && (permissions?.contains('manage_users') ?? true);
  bool get canManageContent =>
      isAdmin && (permissions?.contains('manage_content') ?? true);
  bool get canViewAnalytics =>
      isAdmin && (permissions?.contains('view_analytics') ?? true);
  bool get isPremium =>
      subscriptionTier == 'premium' &&
      (subscriptionExpiry == null ||
          subscriptionExpiry!.isAfter(DateTime.now()));

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
    String? statusReason,
    String? availabilityStatus,
    DateTime? lastSeen,
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
      statusReason: statusReason ?? this.statusReason,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      lastSeen: lastSeen ?? this.lastSeen,
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
