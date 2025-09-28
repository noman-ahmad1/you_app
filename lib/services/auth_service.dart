import 'dart:async';
import 'package:stacked/stacked.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/models/app_user.dart';

class AuthenticationService with ListenableServiceMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

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

  AuthenticationService() {
    listenToReactiveValues(
        [_currentUser, _allUsers, _authStatus, _isLoading, _error]);
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isLoading.value = true;

    try {
      await _googleSignIn.initialize(
          // You can specify scopes here, or wherever you call signIn()
          );
    } catch (e) {
      print('GoogleSignIn initialization failed: $e');
    }

    // Set up auth state listener
    _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      try {
        final userData = await _getUserData(firebaseUser.uid);
        final appUser = _createAppUser(firebaseUser, userData);

        _currentUser.value = appUser;

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

  Future<Map<String, dynamic>?> _getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
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

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
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
      });

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

      final querySnapshot = await _firestore.collection('users').get();

      final users = querySnapshot.docs.map((doc) {
        final data = doc.data();
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
      await _firestore.collection('users').doc(userId).update({
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
      await _firestore.collection('users').doc(volunteerId).update({
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

      await _firestore.collection('users').doc(userId).update({
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

  // Authentication Methods
  Future<AppUser?> signUpUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
    required DateTime dateOfBirth,
    required String gender,
  }) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      notifyListeners();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': 'user',
        'emailVerified': false,
        'status': 'active',
        'username': username
            .toLowerCase(), // Save lowercased for case-insensitive search
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      await userCredential.user!.sendEmailVerification();

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

  Future<AppUser?> signUpVolunteer({
    required String email,
    required String password,
    required String phoneNumber,
    required String firstName, // Added for completeness, usually required
    required String lastName, // Added for completeness
    required String
        profilePictureUrl, // Profile Picture URL (assuming upload is done elsewhere)
    required DateTime dateOfBirth,
    required String gender,
  }) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      notifyListeners();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'phoneNumber': phoneNumber,
        'role': 'volunteer',
        'status': 'pending_verification',
        'emailVerified': false,
        'phoneVerified': false,
        'profilePictureUrl': profilePictureUrl,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      await userCredential.user!.sendEmailVerification();
      await _sendPhoneVerification(phoneNumber);

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

  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

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

  Future<AppUser?> signInWithGoogle() async {
    try {
      _isLoading.value = true;
      _error.value = null;
      notifyListeners();

      // Initialize Google Sign-In
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.authenticate();
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled by user');
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        // accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credentials
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Check if user exists in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // Create new user document
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email ?? googleUser.email,
          'firstName': googleUser.displayName?.split(' ').first ?? 'User',
          'lastName': googleUser.displayName?.split(' ').last ?? '',
          'role': 'user',
          'emailVerified': userCredential.user!.emailVerified,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        // Update last login for existing user
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      // Get updated user data
      final userData = await _getUserData(userCredential.user!.uid);
      final appUser = _createAppUser(userCredential.user!, userData);

      return appUser;
    } catch (e) {
      _error.value = 'Google sign-in failed: $e';
      rethrow;
    } finally {
      _isLoading.value = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();

      _currentUser.value = null;
      _authStatus.value = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      _error.value = 'Sign out failed: $e';
      throw Exception(_error.value);
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

  Future<void> _sendPhoneVerification(String phoneNumber) async {
    // Implement phone verification logic
    print('Phone verification would be sent to: $phoneNumber');
    // You'll implement actual phone verification using Firebase Phone Auth
  }

  Future<bool> isUsernameAvailable(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    return query.docs.isEmpty;
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
        return 'You do not have permission to perform this action.'; // New case
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
