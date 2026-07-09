import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/services/user_service.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/ui/common/app_colors.dart'; // Needed for the date picker theme
import 'package:you_app/ui/common/validators.dart';

class UserInfoViewModel extends BaseViewModel {
  final String uid;

  // --- Dependencies restored ---
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _authenticationService = locator<AuthenticationService>();

  // --- State ---
  final List<String> _genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say'
  ];
  String? _selectedGender;
  DateTime? _selectedDate;
  String? _validationError;

  // --- Controllers ---
  final userNameController = TextEditingController();
  final dateOfBirthController = TextEditingController();

  // --- Getters ---
  String? get selectedGender => _selectedGender;
  DateTime? get selectedDate => _selectedDate;
  List<String> get genders => _genders;
  String? get validationError => _validationError; // Restored

  UserInfoViewModel({
    required this.uid,
  });

  @override
  void dispose() {
    userNameController.dispose();
    dateOfBirthController.dispose();
    super.dispose();
  }

  // --- Logic Methods ---

  void updateSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setGender(String? gender) {
    _selectedGender = gender;
    notifyListeners();
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ??
          DateTime.now().subtract(
              const Duration(days: 365 * 18)), // Default to 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      updateSelectedDate(picked);
      // Format the date for the TextEditingController (dd/MM/yyyy)
      dateOfBirthController.text = "${picked.day.toString().padLeft(2, '0')}/"
          "${picked.month.toString().padLeft(2, '0')}/"
          "${picked.year}";
    }
  }

  // --- Validation updated to be async for uniqueness check ---
  Future<bool> _validateInputs() async {
    _validationError = null;
    final username = userNameController.text.trim();

    // 1. Required fields
    if (username.isEmpty || _selectedDate == null || _selectedGender == null) {
      _validationError =
          'Please provide your username, date of birth, and gender.';
      notifyListeners();
      return false;
    }

    // 2. Username format (letters, numbers, underscores; 3–20 chars)
    final usernameError = Validators.username(username);
    if (usernameError != null) {
      _validationError = usernameError;
      notifyListeners();
      return false;
    }

    // 3. Date of birth: not in the future, and at least 16 years old
    if (_selectedDate!.isAfter(DateTime.now())) {
      _validationError = 'Your date of birth cannot be in the future.';
      notifyListeners();
      return false;
    }
    if (Validators.ageFrom(_selectedDate!) < 16) {
      _validationError = 'You must be at least 16 years old to use You.';
      notifyListeners();
      return false;
    }

    // 4. Asynchronous uniqueness check (service lowercases for the query).
    // Bounded by a timeout so a slow/unreachable Firestore query can't freeze
    // the button for minutes — on timeout we ask the user to retry.
    try {
      final isAvailable = await locator<UserService>()
          .checkUsernameAvailability(username)
          .timeout(const Duration(seconds: 12));
      if (!isAvailable) {
        _validationError =
            'This username is already taken. Please choose another one.';
      }
    } on TimeoutException {
      _validationError =
          "We couldn't check that username just now. Please check your "
          'connection and try again.';
    }

    notifyListeners();
    return _validationError == null;
  }

  // --- Core Sign Up Logic restored ---
  Future<void> completeSignUp() async {
    // Await the asynchronous validation
    if (!await _validateInputs()) {
      _dialogService.showDialog(
        title: 'Validation Error',
        description: _validationError!,
      );
      return;
    }

    setBusy(true);

    try {
      final updateData = {
        // Ensure the username is saved in lowercase for consistency and easy querying
        'username': userNameController.text.trim().toLowerCase(),
        'dateOfBirth':
            _selectedDate, // Store as DateTime for Firestore Timestamp
        'gender': _selectedGender,
        'status': 'active', // Mark user profile as complete
        'profileCompletedAt': FieldValue.serverTimestamp(),
      };

      // 1. Update the existing user document using the passed UID
      await locator<UserService>().update(uid, updateData);

      // 2. Reflect the new data in the in-memory user instantly. We deliberately
      // do NOT call checkCurrentUserStatus() here — its firebaseUser.reload()
      // and full re-init are redundant (the live user-doc listener already syncs
      // this write) and can stall for a long time on a poor connection, which
      // was making "Complete sign up" hang for minutes.
      _authenticationService.applyLocalProfileUpdate(
        username: userNameController.text.trim().toLowerCase(),
        gender: _selectedGender,
        dateOfBirth: _selectedDate,
        status: 'active',
      );

      // 3. Navigate to the main application view
      _navigationService.clearStackAndShow(Routes.homeView);
    } catch (e) {
      _dialogService.showDialog(
        title: 'Profile Update Failed',
        description:
            'Could not save your information. Please try again. Error: $e',
      );
    } finally {
      setBusy(false);
    }
  }
}
