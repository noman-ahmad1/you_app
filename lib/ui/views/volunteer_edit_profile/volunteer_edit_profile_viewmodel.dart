import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/models/app_user.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/storage_service.dart';
import 'package:you_app/services/user_service.dart';
import 'package:you_app/services/volunteer_service.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/utils/image_compressor_helper.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';

class VolunteerEditProfileViewModel extends BaseViewModel {
  final _userService = locator<UserService>();
  final _authenticationService = locator<AuthenticationService>();
  final _volunteerService = locator<VolunteerService>();
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _storageService = locator<StorageService>();
  final ImagePicker _imagePicker = ImagePicker();

  // Personal Info Controllers
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final dobController = TextEditingController();

  // Academic Info Controllers
  final institutionController = TextEditingController();
  final graduationYearController = TextEditingController();

  // State Variables
  File? _selectedProfileImage;
  String? _currentProfileImageUrl;
  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedLevel;
  List<String> _selectedTags = [];
  String _fullPhoneNumber = '';

  // Options
  final List<String> genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> levels = [
    'Undergraduate Student',
    'Graduate Student',
    'PhD Candidate',
    'Post Doc'
  ];
  final List<String> categories = AppConstants.volunteerTags;

  // Getters
  File? get selectedProfileImage => _selectedProfileImage;
  String? get currentProfileImageUrl => _currentProfileImageUrl;
  String? get selectedGender => _selectedGender;
  String? get selectedLevel => _selectedLevel;
  List<String> get selectedTags => _selectedTags;
  AppUser? get currentUser => _authenticationService.currentUser;

  Future<void> initialize() async {
    setBusy(true);
    try {
      final appUser = _authenticationService.currentUser;
      if (appUser == null) {
        throw Exception("User not logged in");
      }

      final volunteerInfo = await _volunteerService.get(appUser.uid);

      // Pre-fill Personal Info
      firstNameController.text = appUser.firstName ?? '';
      lastNameController.text = appUser.lastName ?? '';

      String phone = appUser.phoneNumber ?? '';
      _fullPhoneNumber = phone;
      if (phone.startsWith('+92')) {
        phoneController.text = phone.substring(3);
      } else {
        phoneController.text = phone;
      }

      _selectedGender = appUser.gender;
      _currentProfileImageUrl = appUser.profilePictureUrl;

      if (appUser.dateOfBirth != null) {
        _selectedDate = appUser.dateOfBirth;
        dobController.text = "${_selectedDate!.day.toString().padLeft(2, '0')}/"
            "${_selectedDate!.month.toString().padLeft(2, '0')}/"
            "${_selectedDate!.year}";
      }

      // Pre-fill Volunteer/Academic Info
      if (volunteerInfo != null) {
        institutionController.text = volunteerInfo.institutionName ?? '';
        graduationYearController.text = volunteerInfo.graduationYear ?? '';
        _selectedLevel = volunteerInfo.currentLevelOfStudy;
        if (volunteerInfo.tags != null) {
          _selectedTags = List<String>.from(volunteerInfo.tags!);
        }
      }
    } catch (e) {
      _dialogService.showDialog(
          title: 'Error', description: 'Failed to load profile data: $e');
    }
    setBusy(false);
  }

  void setGender(String? gender) {
    _selectedGender = gender;
    notifyListeners();
  }

  void setLevel(String? level) {
    _selectedLevel = level;
    notifyListeners();
  }

  void setPhoneNumber(String phone) {
    _fullPhoneNumber = phone;
  }

  void toggleTag(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    notifyListeners();
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
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
      _selectedDate = picked;
      dobController.text = "${picked.day.toString().padLeft(2, '0')}/"
          "${picked.month.toString().padLeft(2, '0')}/"
          "${picked.year}";
      notifyListeners();
    }
  }

  Future<void> pickImage(ImageSource source, BuildContext context) async {
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) return;
      } else {
        final status = await Permission.photos.request();
        if (!status.isGranted) return;
      }

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        final originalFile = File(pickedFile.path);
        final compressedFile =
            await ImageCompressorHelper.compressImage(originalFile);

        _selectedProfileImage = compressedFile;
        notifyListeners();
        Navigator.of(context).pop();
      }
    } catch (e) {
      await _dialogService.showDialog(
          title: 'Error', description: 'Failed to pick image: $e');
    }
  }

  void showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose Profile Photo',
                style: GoogleFonts.crimsonPro(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryVeryDark,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImagePickerOption(
                    context,
                    Icons.camera_alt,
                    'Camera',
                    () => pickImage(ImageSource.camera, context),
                  ),
                  _buildImagePickerOption(
                    context,
                    Icons.photo_library,
                    'Gallery',
                    () => pickImage(ImageSource.gallery, context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePickerOption(
    BuildContext context,
    IconData icon,
    String text,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.peachDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.background, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: GoogleFonts.crimsonPro(
            color: AppColors.primaryVeryDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> saveProfile() async {
    final appUser = _authenticationService.currentUser;
    if (appUser == null) return;

    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty) {
      _dialogService.showDialog(
          title: 'Error', description: 'First and Last name are required.');
      return;
    }

    setBusy(true);
    try {
      String? profileUrl = _currentProfileImageUrl;
      if (_selectedProfileImage != null) {
        if (profileUrl != null && profileUrl.isNotEmpty) {
          try {
            await _storageService.deleteFileByUrl(profileUrl);
          } catch (e) {
            print('Failed to delete old profile image: $e');
          }
        }
        final storagePath =
            'volunteer_profiles/${appUser.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final uploadedUrl = await _storageService.uploadFile(
            _selectedProfileImage!, storagePath);
        if (uploadedUrl != null) {
          profileUrl = uploadedUrl;
        }
      }

      // Update AppUser
      final appUserData = {
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'dateOfBirth': _selectedDate,
        'gender': _selectedGender,
        'phoneNumber':
            phoneController.text.trim().isEmpty ? '' : _fullPhoneNumber.trim(),
        'profilePictureUrl': profileUrl,
      };
      await _userService.update(appUser.uid, appUserData);
      await _authenticationService.checkCurrentUserStatus();

      // Update VolunteerInfo
      final volunteerInfoData = {
        'currentLevelOfStudy': _selectedLevel,
        'institutionName': institutionController.text.trim(),
        'graduationYear': graduationYearController.text.trim(),
        'tags': _selectedTags,
      };

      // We check if it exists, if so update, else create
      final existingInfo = await _volunteerService.get(appUser.uid);
      if (existingInfo != null) {
        await _volunteerService.update(appUser.uid, volunteerInfoData);
      } else {
        // Fallback if they somehow didn't have info yet
        volunteerInfoData['uid'] = appUser.uid;
        volunteerInfoData['agreementAccepted'] = true;
        volunteerInfoData['status'] = 'approved';
        await _volunteerService.saveInfo(appUser.uid, volunteerInfoData);
      }

      await _dialogService.showDialog(
          title: 'Success', description: 'Profile updated successfully.');
      _navigationService.back();
    } catch (e) {
      _dialogService.showDialog(
          title: 'Error', description: 'Failed to update profile: $e');
    } finally {
      setBusy(false);
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    dobController.dispose();
    institutionController.dispose();
    graduationYearController.dispose();
    super.dispose();
  }
}
