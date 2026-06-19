import 'dart:async';
import 'package:stacked/stacked.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/models/app_user.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/base/app_log.dart';
import 'package:you_app/services/user_service.dart';
import 'package:you_app/services/volunteer_service.dart';
import 'package:you_app/services/mood_service.dart';
import 'package:you_app/services/journal_service.dart';
import 'package:you_app/services/chat_service.dart';
import 'package:you_app/services/chat_request_service.dart';
import 'package:you_app/services/community_service.dart';
import 'package:you_app/services/push_notification_service.dart';
import 'package:you_app/app/app.locator.dart'; // REQUIRED FOR SERVICE LOCATOR PATTERN

class AuthenticationService with ListenableServiceMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Resolved lazily to avoid construction-order issues during setupLocator.
  AnalyticsService get _analytics => locator<AnalyticsService>();

  // REMOVED: final FirestoreService _firestoreService;
  // FirestoreService is now accessed via locator<FirestoreService>()

  // Phone verification properties
  final ReactiveValue<bool> _isPhoneVerificationSent =
      ReactiveValue<bool>(false);
  final ReactiveValue<bool> _isPhoneVerified = ReactiveValue<bool>(false);
  final ReactiveValue<String?> _verificationId = ReactiveValue<String?>(null);
  final ReactiveValue<int?> _forceResendingToken = ReactiveValue<int?>(null);
  final ReactiveValue<bool> _isPhoneCodeSent = ReactiveValue<bool>(false);
  final ReactiveValue<String?> _pendingPhoneNumber =
      ReactiveValue<String?>(null);

  final ReactiveValue<AppUser?> _currentUser = ReactiveValue<AppUser?>(null);
  final ReactiveValue<AuthStatus> _authStatus =
      ReactiveValue<AuthStatus>(AuthStatus.unauthenticated);
  final ReactiveValue<bool> _isLoading = ReactiveValue<bool>(false);
  final ReactiveValue<String?> _error = ReactiveValue<String?>(null);
  final ReactiveValue<List<AppUser>> _allUsers =
      ReactiveValue<List<AppUser>>([]);
  List<AppUser> get allUsers => _allUsers.value;

  StreamSubscription<User?>? _authSubscription;

  AppUser? get currentUser => _currentUser.value;
  AuthStatus get authStatus => _authStatus.value;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  bool get isLoggedIn => _currentUser.value != null;
  // Phone verification getters
  bool get isPhoneVerificationSent => _isPhoneVerificationSent.value;
  bool get isPhoneVerified => _isPhoneVerified.value;
  bool get isPhoneCodeSent => _isPhoneCodeSent.value;
  String? get pendingPhoneNumber => _pendingPhoneNumber.value;

  // Constructor no longer requires FirestoreService argument
  AuthenticationService() {
    listenToReactiveValues([
      _currentUser,
      _authStatus,
      _isLoading,
      _error,
      _allUsers,
      _isPhoneVerificationSent,
      _isPhoneVerified,
      _verificationId,
      _forceResendingToken,
      _isPhoneCodeSent,
      _pendingPhoneNumber
    ]);
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isLoading.value = true;

    // try {
    //   await _googleSignIn.initialize(
    //       // Scopes can be specified here or wherever you call signIn()
    //       );
    // } catch (e) {
    //   print('GoogleSignIn initialization failed: $e');
    // }

    // Set up auth state listener
    _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      try {
        // Use the Service Locator to get FirestoreService
        final userData = await locator<UserService>().get(firebaseUser.uid);
        final appUser = _createAppUser(firebaseUser, userData);

        _currentUser.value = appUser;

        // Identify the user for analytics/crash segmentation (no content/PII).
        _analytics.setUser(
          uid: appUser.uid,
          role: appUser.role.name,
          gender: appUser.gender,
          status: appUser.status,
        );

        // Sync FCM token automatically after authentication
        Future.microtask(() {
          try {
            if (locator.isRegistered<PushNotificationService>()) {
              locator<PushNotificationService>().syncTokenAfterLogin();
            }
          } catch (e) {
            AppLog.error('AuthenticationService.fcmTokenSync', e);
          }
        });

        // Determine auth status - Admins have different verification requirements
        if (appUser.isAdmin) {
          // Admins are always considered authenticated once email is verified
          _authStatus.value = appUser.emailVerified
              ? AuthStatus.authenticated
              : AuthStatus.pendingVerification;
        } else if (!appUser.emailVerified) {
          _authStatus.value = AuthStatus.pendingVerification;
        } else if (appUser.isVolunteer &&
            (!appUser.phoneVerified || appUser.status != 'verified')) {
          _authStatus.value = AuthStatus.pendingVerification;
        } else {
          _authStatus.value = AuthStatus.authenticated;
        }

        // If user is admin, pre-load users list
        if (appUser.isAdmin) {
          await fetchAllUsers();
        }
      } catch (e) {
        _error.value = 'Failed to load user data: $e';
        _authStatus.value = AuthStatus.unauthenticated;
      }
    } else {
      _currentUser.value = null;
      _allUsers.value = []; // Clear users list on logout
      _authStatus.value = AuthStatus.unauthenticated;
    }

    _isLoading.value = false;
    notifyListeners();
  }

  // New method to force refresh the current user's state (useful after external actions like password reset)
  Future<void> checkCurrentUserStatus() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await firebaseUser.reload();
      await _onAuthStateChanged(firebaseUser);
    }
  }

  bool hasPermission(String permission) {
    return _currentUser.value?.isAdmin == true &&
        (_currentUser.value?.permissions?.contains(permission) ?? true);
  }

  bool canManageUser(String targetUserId) {
    final currentUser = _currentUser.value;
    if (currentUser == null) return false;

    // Admins can manage all users except themselves for certain operations
    if (currentUser.isAdmin && currentUser.uid != targetUserId) {
      return hasPermission('manage_users');
    }

    return false;
  }

  // Simplified to call the FirestoreService via locator
  Future<Map<String, dynamic>?> _getUserData(String uid) async {
    return locator<UserService>().get(uid);
  }

  AppUser _createAppUser(User firebaseUser, Map<String, dynamic>? userData) {
    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      firstName: userData?['firstName'] ?? '',
      lastName: userData?['lastName'] ?? '',
      role: userData?['role'] == 'admin'
          ? UserRole.admin
          : userData?['role'] == 'volunteer'
              ? UserRole.volunteer
              : UserRole.user,
      phoneNumber: userData?['phoneNumber'],
      emailVerified: firebaseUser.emailVerified,
      phoneVerified: userData?['phoneVerified'] ?? false,
      status: userData?['status'] ?? 'active',
      createdAt: userData?['createdAt']?.toDate(),
      permissions: List<String>.from(userData?['permissions'] ?? []),
      profilePictureUrl: userData?['profilePictureUrl'],
      gender: userData?['gender'],
      username: userData?['username'],
      dateOfBirth: (userData?['dateOfBirth'] as Timestamp?)?.toDate(),
      joinedCommunities: userData?['joinedCommunities'] != null
          ? List<String>.from(userData!['joinedCommunities'])
          : [],
    );
  }

  Future<AppUser?> createAdminUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    List<String> permissions = const [
      'manage_users',
      'manage_content',
      'view_analytics'
    ],
  }) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      notifyListeners();

      // Security check - only allow existing admins to create new admins
      if (!_currentUser.value!.isAdmin) {
        throw Exception('Insufficient permissions to create admin user');
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDataMap = {
        'uid': userCredential.user!.uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': 'admin',
        'emailVerified': true, // Admins are auto-verified
        'phoneVerified': true,
        'status': 'active',
        'permissions': permissions,
        'createdBy': _currentUser.value!.uid, // Track who created this admin
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      };

      // Use FirestoreService via locator to set user data
      await locator<UserService>().set(userCredential.user!.uid, userDataMap);

      final userData = await _getUserData(userCredential.user!.uid);
      final appUser = _createAppUser(userCredential.user!, userData);

      return appUser;
    } on FirebaseAuthException catch (e) {
      _error.value = _handleAuthError(e);
      throw Exception(_error.value);
    } finally {
      _isLoading.value = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllUsers() async {
    if (!_currentUser.value!.isAdmin) {
      throw Exception('Insufficient permissions');
    }

    try {
      _isLoading.value = true;
      notifyListeners();

      // Use FirestoreService via locator to fetch all user data maps
      final dataMaps = await locator<UserService>().getAll();

      final users = dataMaps.map((data) {
        return AppUser(
          uid: data['uid'],
          email: data['email'],
          firstName: data['firstName'],
          lastName: data['lastName'],
          role: data['role'] == 'admin'
              ? UserRole.admin
              : data['role'] == 'volunteer'
                  ? UserRole.volunteer
                  : UserRole.user,
          phoneNumber: data['phoneNumber'],
          emailVerified: data['emailVerified'] ?? false,
          phoneVerified: data['phoneVerified'] ?? false,
          status: data['status'] ?? 'active',
          createdAt: data['createdAt']?.toDate(),
          permissions: List<String>.from(data['permissions'] ?? []),
        );
      }).toList();

      _allUsers.value = users;
    } catch (e) {
      _error.value = 'Failed to fetch users: $e';
      throw Exception(_error.value);
    } finally {
      _isLoading.value = false;
      notifyListeners();
    }
  }

  Future<void> updateUserRole(String userId, UserRole newRole) async {
    if (!_currentUser.value!.isAdmin) {
      throw Exception('Insufficient permissions');
    }

    try {
      // Use FirestoreService via locator to update the user document
      await locator<UserService>().update(userId, {
        'role': newRole.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _currentUser.value!.uid,
      });

      // Update local state if the updated user is the current user
      if (userId == _currentUser.value!.uid) {
        _currentUser.value = _currentUser.value!.copyWith(role: newRole);
      }

      // Refresh users list
      await fetchAllUsers();
    } catch (e) {
      _error.value = 'Failed to update user role: $e';
      throw Exception(_error.value);
    }
  }

  // ADMIN-ONLY: Verify volunteer
  Future<void> verifyVolunteer(String volunteerId) async {
    if (!_currentUser.value!.isAdmin) {
      throw Exception('Insufficient permissions');
    }

    try {
      // Use FirestoreService via locator to update the user document status
      await locator<UserService>().update(volunteerId, {
        'status': 'verified',
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': _currentUser.value!.uid,
      });

      await fetchAllUsers();
    } catch (e) {
      _error.value = 'Failed to verify volunteer: $e';
      throw Exception(_error.value);
    }
  }

  // ADMIN-ONLY: Delete user
  Future<void> deleteUser(String userId) async {
    if (!_currentUser.value!.isAdmin) {
      throw Exception('Insufficient permissions');
    }

    try {
      // Prevent self-deletion
      if (userId == _currentUser.value!.uid) {
        throw Exception('Cannot delete your own account');
      }

      // Use FirestoreService via locator to update the user document status
      await locator<UserService>().update(userId, {
        'status': 'deleted',
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _currentUser.value!.uid,
      });

      await fetchAllUsers();
    } catch (e) {
      _error.value = 'Failed to delete user: $e';
      throw Exception(_error.value);
    }
  }

  Future<String?> getCurrentUserRole() async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) {
      return null;
    }

    try {
      // Fetch the user document directly from Firestore
      final userData = await locator<UserService>().get(firebaseUser.uid);

      // Return the role string (e.g., 'volunteer', 'user', 'admin')
      // If userData is null or 'role' is missing, it returns null
      return userData?['role'] as String?;
    } catch (e) {
      // Log the error but return null to prevent app crash on startup
      AppLog.error('AuthenticationService.getCurrentUserRole', e);
      return null;
    }
  }

  // --- Password Management Methods (Unchanged) ---

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      _error.value = _handleAuthError(e);
      throw Exception(_error.value);
    } finally {
      _isLoading.value = false;
      notifyListeners();
    }
  }

  // Note: This method is typically used on the app after a deep link redirects
  // from an email containing the oobCode (out-of-band code).
  Future<void> confirmPasswordReset({
    required String oobCode,
    required String newPassword,
  }) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      notifyListeners();

      await _auth.confirmPasswordReset(
        code: oobCode,
        newPassword: newPassword,
      );
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      _error.value = _handleAuthError(e);
      throw Exception(_error.value);
    } finally {
      _isLoading.value = false;
      notifyListeners();
    }
  }

  // --- END Password Management Methods ---

  // Authentication Methods
  Future<AppUser?> signUpUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      notifyListeners();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDataMap = {
        'uid': userCredential.user!.uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': 'user',
        'emailVerified': false,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      };

      // Use FirestoreService via locator to set user data
      await locator<UserService>().set(userCredential.user!.uid, userDataMap);
      await userCredential.user!.sendEmailVerification();

      final userData = await _getUserData(userCredential.user!.uid);
      final appUser = _createAppUser(userCredential.user!, userData);

      _analytics.logSignUp(method: 'email', role: 'user');
      return appUser;
    } on FirebaseAuthException catch (e) {
      _error.value = _handleAuthError(e);
      throw Exception(_error.value);
    } finally {
      _isLoading.value = false;
      notifyListeners();
    }
  }

  Future<AppUser?> signUpVolunteer({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      notifyListeners();

      // Check if phone is verified
      if (!_isPhoneVerified.value || _pendingPhoneNumber.value == null) {
        throw Exception('Phone number must be verified before signup');
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDataMap = {
        'uid': userCredential.user!.uid,
        'email': email,
        'firstName': null,
        'lastName': null,
        'phoneNumber': _pendingPhoneNumber.value, // Use verified phone number
        'role': 'volunteer',
        'status': 'profile_incomplete',
        'emailVerified': false,
        'phoneVerified': true, // Mark as verified since we just verified it
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      };

      // Use FirestoreService via locator to set user data
      await locator<UserService>().set(userCredential.user!.uid, userDataMap);
      await userCredential.user!.sendEmailVerification();

      final userData = await _getUserData(userCredential.user!.uid);
      final appUser = _createAppUser(userCredential.user!, userData);

      // Reset phone verification after successful signup
      _resetPhoneAuthState();

      _analytics.logSignUp(method: 'email', role: 'volunteer');
      return appUser;
    } on FirebaseAuthException catch (e) {
      _error.value = _handleAuthError(e);
      throw Exception(_error.value);
    } finally {
      _isLoading.value = false;
      notifyListeners();
    }
  }

  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Use FirestoreService via locator to update last login
      await locator<UserService>().updateLastLogin(userCredential.user!.uid);

      final userData = await _getUserData(userCredential.user!.uid);
      final appUser = _createAppUser(userCredential.user!, userData);

      _analytics.logLogin(method: 'email');
      return appUser;
    } on FirebaseAuthException catch (e) {
      _error.value = _handleAuthError(e);
      throw Exception(_error.value);
    } finally {
      _isLoading.value = false;
      notifyListeners();
    }
  }

  Future<AppUser?> signInWithGoogle() async {
    try {
      _isLoading.value = true;
      _error.value = null;
      notifyListeners();

      // Initialize Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled by user');
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credentials
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Check if user exists in Firestore
      // Use FirestoreService via locator to get the user data map
      final userDataMap =
          await locator<UserService>().get(userCredential.user!.uid);

      // Google sign-in is for the 'user' role only. Volunteers (and admins)
      // must authenticate with their email/password. If an existing account
      // with this identity is not a regular user, reject and sign back out.
      if (userDataMap != null && userDataMap['role'] != 'user') {
        await _auth.signOut();
        await _googleSignIn.signOut();
        _currentUser.value = null;
        _authStatus.value = AuthStatus.unauthenticated;
        _error.value =
            'Google sign-in is only available for user accounts. Please sign in with your email and password.';
        throw Exception(_error.value);
      }

      if (userDataMap == null) {
        // Create new user document
        final newUserData = {
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email ?? googleUser.email,
          'firstName': googleUser.displayName?.split(' ').first ?? 'User',
          'lastName': googleUser.displayName?.split(' ').last ?? '',
          'role': 'user',
          'emailVerified': userCredential.user!.emailVerified,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        };
        // Use FirestoreService via locator to set user data
        await locator<UserService>().set(userCredential.user!.uid, newUserData);
        _analytics.logSignUp(method: 'google', role: 'user');
      } else {
        // Update last login for existing user
        // Use FirestoreService via locator to update last login
        await locator<UserService>().updateLastLogin(userCredential.user!.uid);
      }

      // Get updated user data (if it was just created)
      final userData = await _getUserData(userCredential.user!.uid);
      final appUser = _createAppUser(userCredential.user!, userData);

      _analytics.logLogin(method: 'google');
      return appUser;
    } catch (e) {
      // Preserve a specific message (e.g. the role rejection) if already set.
      _error.value ??= 'Google sign-in failed: $e';
      rethrow;
    } finally {
      _isLoading.value = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      // Remove FCM token from Firestore before logging out to protect privacy
      final user = _currentUser.value;
      if (user != null) {
        try {
          await locator<UserService>().update(user.uid, {
            'fcmToken': FieldValue.delete(),
          });
        } catch (e) {
          AppLog.error('AuthenticationService.signOut.removeFcmToken', e);
        }
      }

      await _auth.signOut();
      await _googleSignIn.signOut();

      // Clear any session-scoped service caches so a different user signing in
      // on the same app session never sees stale data.
      locator<VolunteerService>().clearCache();
      _analytics.logLogout();
      _analytics.clearUser();

      _currentUser.value = null;
      _authStatus.value = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _error.value = 'Sign out failed: $e';
      throw Exception(_error.value);
    }
  }

  Future<void> deleteCurrentAccount() async {
    final user = _currentUser.value;
    final firebaseUser = _auth.currentUser;

    if (user == null || firebaseUser == null) {
      throw Exception('No user is currently signed in.');
    }

    final lastSignInTime = firebaseUser.metadata.lastSignInTime;
    if (lastSignInTime == null || DateTime.now().difference(lastSignInTime) > const Duration(minutes: 5)) {
      throw Exception(
        'For security reasons, this sensitive operation requires a recent login. Please log out and log back in, then try again.',
      );
    }

    try {
      _isLoading.value = true;
      _error.value = null;
      notifyListeners();

      final uid = user.uid;
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // 1. Delete journal subcollection
      final journalDocs = await firestore.collection('users').doc(uid).collection('journal').get();
      for (var doc in journalDocs.docs) {
        batch.delete(doc.reference);
      }

      // 2. Delete notifications subcollection
      final notificationDocs = await firestore.collection('users').doc(uid).collection('notifications').get();
      for (var doc in notificationDocs.docs) {
        batch.delete(doc.reference);
      }

      // 3. If volunteer, delete volunteer_info and its reviews subcollection
      if (user.isVolunteer) {
        final volunteerRef = firestore.collection('volunteer_info').doc(uid);
        final reviews = await volunteerRef.collection('reviews').get();
        for (var doc in reviews.docs) {
          batch.delete(doc.reference);
        }
        batch.delete(volunteerRef);
      }

      // 4. Delete community posts
      final postDocs = await firestore.collection('posts').where('authorId', isEqualTo: uid).get();
      for (var doc in postDocs.docs) {
        batch.delete(doc.reference);
      }

      // 5. Delete user document
      final userRef = firestore.collection('users').doc(uid);
      batch.delete(userRef);

      // Commit batch
      await batch.commit();

      // 6. Delete mood docs in chunked batches (Firestore caps a batch at 500 ops)
      final moodDocs = await firestore.collection('mood').where('userId', isEqualTo: uid).get();
      for (var i = 0; i < moodDocs.docs.length; i += 500) {
        final moodBatch = firestore.batch();
        final end = (i + 500 > moodDocs.docs.length) ? moodDocs.docs.length : i + 500;
        for (var j = i; j < end; j++) {
          moodBatch.delete(moodDocs.docs[j].reference);
        }
        await moodBatch.commit();
      }

      // 7. Delete chats
      try {
        await locator<ChatService>().deleteAllUserChats(uid);
      } catch (e) {
        AppLog.error('AuthenticationService.deleteCurrentAccount.deleteChats', e);
      }

      // 8. Delete FirebaseAuth user
      await firebaseUser.delete();

      _analytics.logAccountDeleted(role: user.role.name);
      _analytics.clearUser();

      // Clear local state
      _currentUser.value = null;
      _authStatus.value = AuthStatus.unauthenticated;
      notifyListeners();

    } catch (e) {
      _error.value = 'Failed to delete account: $e';
      throw Exception(_error.value);
    } finally {
      _isLoading.value = false;
      notifyListeners();
    }
  }

  Future<void> checkEmailVerification() async {
    if (_currentUser.value != null) {
      await _auth.currentUser!.reload();
      final updatedUser = _auth.currentUser;

      if (updatedUser != null && updatedUser.emailVerified) {
        _currentUser.value = _currentUser.value!.copyWith(emailVerified: true);
        notifyListeners();
      }
    }
  }

  // Phone Verification Methods (Unchanged as they use FirebaseAuth only)
  Future<void> sendPhoneVerification(String phoneNumber) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      _isPhoneVerified.value = false;
      notifyListeners();

      // Format phone number (ensure it starts with + and country code)
      String formattedPhone = _formatPhoneNumber(phoneNumber);
      _pendingPhoneNumber.value = phoneNumber;

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: _onVerificationCompleted,
        verificationFailed: _onVerificationFailed,
        codeSent: _onCodeSent,
        codeAutoRetrievalTimeout: _onCodeTimeout,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _forceResendingToken.value,
      );

      _isPhoneVerificationSent.value = true;
      _analytics.logPhoneOtpSent();
    } catch (e) {
      _error.value = 'Failed to send verification code: $e';
      throw Exception(_error.value);
    } finally {
      _isLoading.value = false;
      notifyListeners();
    }
  }

  Future<void> verifyPhoneCode(String smsCode) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      notifyListeners();

      // On real Android devices Firebase often auto-retrieves the SMS and
      // completes verification via _onVerificationCompleted (which clears
      // _verificationId). If that already happened, the manual submit should
      // succeed instead of failing on a null verificationId.
      if (_isPhoneVerified.value) {
        AppLog.info('AuthenticationService.verifyPhoneCode',
            'Already auto-verified; skipping manual credential sign-in.');
        return;
      }

      if (_verificationId.value == null) {
        throw FirebaseAuthException(
          code: 'session-expired',
          message: 'No verification in progress. Please request a new code.',
        );
      }

      // Create credential and sign in
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId.value!,
        smsCode: smsCode,
      );

      // Sign in with phone credential (this creates a temporary authentication)
      await _auth.signInWithCredential(credential);

      // Mark phone as verified
      _isPhoneVerified.value = true;
      _analytics.logPhoneVerified();

      // Reset phone auth state but keep verification status
      _resetPhoneAuthState(keepVerificationStatus: true);
    } on FirebaseAuthException catch (e) {
      // Surface the *real* error instead of masking everything as a bad code.
      AppLog.firebase(
          'AuthenticationService.verifyPhoneCode', '${e.code} - ${e.message}');
      _error.value = _handlePhoneAuthError(e);
      _isPhoneVerified.value = false;
      throw Exception(_error.value);
    } catch (e) {
      AppLog.error('AuthenticationService.verifyPhoneCode', e);
      _error.value = 'Verification failed. Please try again.';
      _isPhoneVerified.value = false;
      throw Exception(_error.value);
    } finally {
      _isLoading.value = false;
      notifyListeners();
    }
  }

  Future<void> resendPhoneVerification() async {
    if (_pendingPhoneNumber.value == null) {
      throw Exception('No phone number to resend verification');
    }
    await sendPhoneVerification(_pendingPhoneNumber.value!);
  }

// Phone Auth Callbacks
  void _onVerificationCompleted(PhoneAuthCredential credential) async {
    try {
      // Auto-sign in when verification is completed automatically (SMS auto-retrieval)
      await _auth.signInWithCredential(credential);
      _isPhoneVerified.value = true;
      _analytics.logPhoneVerified();

      _resetPhoneAuthState(keepVerificationStatus: true);
      notifyListeners();
    } catch (e) {
      _error.value = 'Auto-verification failed: $e';
      notifyListeners();
    }
  }

  void _onVerificationFailed(FirebaseAuthException e) {
    _error.value = _handlePhoneAuthError(e);
    _isPhoneVerificationSent.value = false;
    _isPhoneCodeSent.value = false;
    _isLoading.value = false;
    notifyListeners();
  }

  void _onCodeSent(String verificationId, int? forceResendingToken) {
    _verificationId.value = verificationId;
    _forceResendingToken.value = forceResendingToken;
    _isPhoneCodeSent.value = true;
    _isLoading.value = false;
    notifyListeners();
  }

  void _onCodeTimeout(String verificationId) {
    _error.value = 'Verification code timed out. Please try again.';
    _isPhoneVerificationSent.value = false;
    _isPhoneCodeSent.value = false;
    _isLoading.value = false;
    notifyListeners();
  }

// Helper Methods (Unchanged)
  String _formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Simple formatting: If number doesn't start with '+', assume country code is missing.
    // Given the PhoneNumberField widget usually handles the country code,
    // this formatting needs to be robust. Assuming 'phoneNumber' already includes the
    // country code if it came from a dedicated field.
    if (!digitsOnly.startsWith('+')) {
      // If no plus sign, prepend '+'
      if (digitsOnly.length > 10) {
        // Heuristic: If it looks like a full number (e.g., 923001234567), just add '+'
        return '+$digitsOnly';
      } else {
        // Fallback: If it looks like a local number, might need a default country code (e.g., +1)
        // For production, you must use the country code selected in the UI.
        return '+1$digitsOnly';
      }
    }
    return phoneNumber;
  }

  void _resetPhoneAuthState({bool keepVerificationStatus = false}) {
    _isPhoneVerificationSent.value = false;
    _isPhoneCodeSent.value = false;
    _verificationId.value = null;

    if (!keepVerificationStatus) {
      _isPhoneVerified.value = false;
      _pendingPhoneNumber.value = null;
    }

    notifyListeners();
  }

  void cancelPhoneVerification() {
    _resetPhoneAuthState();
  }

  String _handlePhoneAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'The phone number format is invalid. Please use format: +[country_code][number].';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled. Please contact support.';
      case 'session-expired':
        return 'The verification session has expired. Please try again.';
      case 'invalid-verification-code':
        return 'The verification code is invalid.';
      case 'missing-verification-code':
        return 'Please enter the verification code.';
      default:
        return 'Phone verification failed: ${e.message}';
    }
  }

// Method to get the verified phone number for signup
  String? get verifiedPhoneNumber {
    return _isPhoneVerified.value ? _pendingPhoneNumber.value : null;
  }

// Method to reset phone verification (call this when starting a new signup)
  void resetPhoneVerification() {
    _resetPhoneAuthState();
  }

  // Uses the FirestoreService via locator for the check
  Future<bool> isUsernameAvailable(String username) async {
    return locator<UserService>().checkUsernameAvailability(username);
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'insufficient-permissions':
        return 'You do not have permission to perform this action.';
      case 'expired-action-code':
        return 'The password reset link has expired.';
      case 'invalid-action-code':
        return 'The password reset link is invalid.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  void clearError() {
    _error.value = null;
    notifyListeners();
  }

  void dispose() {
    _authSubscription?.cancel();
  }
}
