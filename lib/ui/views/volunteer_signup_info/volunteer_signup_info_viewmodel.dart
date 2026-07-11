import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/validators.dart';
// Import the VolunteerInfo model
import 'package:you_app/services/base/app_log.dart';
import 'package:you_app/services/storage_service.dart';
// import 'package:you_app/models/volunteer_info.dart';
import 'package:you_app/services/user_service.dart';
import 'package:you_app/services/volunteer_service.dart';
import 'package:you_app/ui/common/app_constants.dart'; // UNCOMMENTED
import 'package:you_app/utils/image_compressor_helper.dart';

class VolunteerSignupInfoViewModel extends BaseViewModel {
  final String uid;

  // --- Services ---
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _storageService = locator<StorageService>();

  // --- Image States ---
  File? _selectedProfileImage;
  File? _selectedIdCardImage;
  File? _selectedIdCardBackImage;
  File? _selectedStudentIdImage;
  File? _selectedStudentIdBackImage;

  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedLevel;
  List<String> _selectedTags = [];
  int _currentPage = 0;
  bool _agreementAccepted = false;
  String? _validationError;

  final List<String> _genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say'
  ];
  // Eligibility: only final-year Bachelor's or higher may volunteer.
  final List<String> _levels = [
    "Final-Year Bachelor's Student",
    "Master's Student",
    'PhD Candidate',
    'Post-Doctorate',
  ];
  final List<String> _categories = AppConstants.volunteerTags;

  // --- Getters ---
  File? get selectedProfileImage => _selectedProfileImage;
  File? get selectedIdCardImage => _selectedIdCardImage;
  File? get selectedIdCardBackImage => _selectedIdCardBackImage;
  File? get selectedStudentIdImage => _selectedStudentIdImage;
  File? get selectedStudentIdBackImage => _selectedStudentIdBackImage;

  DateTime? get selectedDate => _selectedDate;
  String? get selectedGender => _selectedGender;
  String? get selectedLevel => _selectedLevel;
  List<String> get selectedTags => _selectedTags;
  int get currentPage => _currentPage;
  bool get agreementAccepted => _agreementAccepted;
  List<String> get genders => _genders;
  List<String> get levels => _levels;
  List<String> get categories => _categories;
  String? get validationError => _validationError;

  final firstNameController = TextEditingController();
  final secondNameController = TextEditingController();
  final dateOfBirthController = TextEditingController();
  final educationController = TextEditingController();
  final institutionController = TextEditingController();
  final graduationYearController = TextEditingController();
  final skillsController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  VolunteerSignupInfoViewModel({
    required this.uid,
  });

  // --- Form Logic (omitted for brevity) ---
  void updateSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setGender(String? gender) {
    _selectedGender = gender;
    notifyListeners();
  }

  void setLevel(String? level) {
    _selectedLevel = level;
    notifyListeners();
  }

  void toggleTag(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    notifyListeners();
  }

  void toggleAgreement(bool? value) {
    _agreementAccepted = value ?? false;
    notifyListeners();
  }

  void nextPage() {
    // Validate the current step before advancing; show a dialog if incomplete.
    final error = _errorForStep(_currentPage);
    if (error != null) {
      _showError('Incomplete step', error);
      return;
    }
    if (_currentPage < 2) {
      _currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
    }
  }

  bool get isFirstPage => _currentPage == 0;
  bool get isLastPage => _currentPage == 2;

  /// Returns the first validation problem on [page], or null if the step is OK.
  String? _errorForStep(int page) {
    switch (page) {
      case 0: // Personal
        if (_selectedProfileImage == null) {
          return 'Please upload a profile photo.';
        }
        if (firstNameController.text.trim().isEmpty) {
          return 'Please enter your first name.';
        }
        if (secondNameController.text.trim().isEmpty) {
          return 'Please enter your last name.';
        }
        if (_selectedDate == null || dateOfBirthController.text.trim().isEmpty) {
          return 'Please select your date of birth.';
        }
        if (_selectedGender == null) {
          return 'Please select your gender.';
        }
        if (_selectedIdCardImage == null) {
          return 'Please upload the front of your Government ID.';
        }
        if (_selectedIdCardBackImage == null) {
          return 'Please upload the back of your Government ID.';
        }
        return null;
      case 1: // Academic
        if (_selectedLevel == null) {
          return 'Please select your current level of study.';
        }
        if (institutionController.text.trim().isEmpty) {
          return 'Please enter your institution name.';
        }
        final yearError = Validators.graduationYear(graduationYearController.text);
        if (yearError != null) return yearError;
        if (_selectedTags.isEmpty) {
          return 'Please select at least one specialization tag.';
        }
        if (_selectedStudentIdImage == null) {
          return 'Please upload the front of your Student ID.';
        }
        if (_selectedStudentIdBackImage == null) {
          return 'Please upload the back of your Student ID.';
        }
        return null;
      case 2: // Agreement
        if (!_agreementAccepted) {
          return 'Please read and accept the volunteer agreement to continue.';
        }
        return null;
    }
    return null;
  }

  /// Sets the inline error and shows an explanatory dialog.
  void _showError(String title, String message) {
    _validationError = message;
    notifyListeners();
    _dialogService.showDialog(title: title, description: message);
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(2000),
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
      dateOfBirthController.text = "${picked.day.toString().padLeft(2, '0')}/"
          "${picked.month.toString().padLeft(2, '0')}/"
          "${picked.year}";
    }
  }

  // --- Image Picking Logic (Omitted for brevity, kept for context) ---

  // Refactored pickImage to handle all three image destinations using imageType
  Future<void> pickImage(ImageSource source, BuildContext context,
      {required String imageType}) async {
    try {
      // Only the camera needs a runtime permission. Gallery picks (incl. the
      // gov-ID and student-ID card images) go through Android's system Photo
      // Picker, which requires NO permission — asking for Permission.photos
      // would re-introduce READ_MEDIA_IMAGES and breach Google Play's Photo and
      // Video Permissions policy.
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
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
        final compressedFile = await ImageCompressorHelper.compressImage(originalFile);

        // Updated logic to set the correct state variable
        if (imageType == 'profile') {
          _selectedProfileImage = compressedFile;
        } else if (imageType == 'gov_id') {
          _selectedIdCardImage = compressedFile;
        } else if (imageType == 'gov_id_back') {
          _selectedIdCardBackImage = compressedFile;
        } else if (imageType == 'student_id') {
          _selectedStudentIdImage = compressedFile;
        } else if (imageType == 'student_id_back') {
          _selectedStudentIdBackImage = compressedFile;
        }

        notifyListeners();
        // Only pop if the modal bottom sheet is active (used for profile/ID card)
        if (imageType == 'profile' || imageType == 'gov_id') {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      AppLog.error('VolunteerSignupInfoViewModel.pickImage', e);
      await _dialogService.showDialog(
          title: 'Error', description: 'Failed to pick image: $e');
    }
  }

  // Helper Widget for Image Picker Options (Omitted for brevity)
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
            child: Icon(
              icon,
              color: AppColors.background,
              size: 30,
            ),
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

  // --- Public Image Picker Option Display Methods (Omitted for brevity) ---

  // 1. Profile Photo Picker (uses modal bottom sheet)
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
                    () => pickImage(ImageSource.camera, context,
                        imageType: 'profile'),
                  ),
                  _buildImagePickerOption(
                    context,
                    Icons.photo_library,
                    'Gallery',
                    () => pickImage(ImageSource.gallery, context,
                        imageType: 'profile'),
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

  // 2. Government ID Card Picker (Front)
  void showIdCardImagePickerOptions(BuildContext context) {
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
                'Upload Government ID Card (Front)',
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
                    () => pickImage(ImageSource.camera, context,
                        imageType: 'gov_id'),
                  ),
                  _buildImagePickerOption(
                    context,
                    Icons.photo_library,
                    'Gallery',
                    () => pickImage(ImageSource.gallery, context,
                        imageType: 'gov_id'),
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

  // Government ID Card Picker (Back)
  void showIdCardBackImagePickerOptions(BuildContext context) {
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
                'Upload Government ID Card (Back)',
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
                    () => pickImage(ImageSource.camera, context,
                        imageType: 'gov_id_back'),
                  ),
                  _buildImagePickerOption(
                    context,
                    Icons.photo_library,
                    'Gallery',
                    () => pickImage(ImageSource.gallery, context,
                        imageType: 'gov_id_back'),
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

  // 3. Student ID Card Picker (Front)
  void showStudentIdImagePickerOptions(BuildContext context) {
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
                'Upload Student ID Card (Front)',
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
                    () => pickImage(ImageSource.camera, context,
                        imageType: 'student_id'),
                  ),
                  _buildImagePickerOption(
                    context,
                    Icons.photo_library,
                    'Gallery',
                    () => pickImage(ImageSource.gallery, context,
                        imageType: 'student_id'),
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

  // Student ID Card Picker (Back)
  void showStudentIdBackImagePickerOptions(BuildContext context) {
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
                'Upload Student ID Card (Back)',
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
                    () => pickImage(ImageSource.camera, context,
                        imageType: 'student_id_back'),
                  ),
                  _buildImagePickerOption(
                    context,
                    Icons.photo_library,
                    'Gallery',
                    () => pickImage(ImageSource.gallery, context,
                        imageType: 'student_id_back'),
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

  // --- Firebase Storage and Firestore ---

  Future<String?> _uploadImage(File image, String folderName) async {
    if (image.existsSync()) {
      final storagePath =
          '$folderName/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final downloadUrl = await _storageService.uploadFile(image, storagePath);
      return downloadUrl;
    }
    return null;
  }

  // UPDATED: Now uses firestoreService.user.update
  Future<void> _updateAppUser(Map<String, dynamic> userData) async {
    await locator<UserService>().update(uid, userData);
  }

  // UPDATED: Now uses firestoreService.volunteer_info.saveInfo
  Future<void> _saveVolunteerInfo(Map<String, dynamic> volunteerData) async {
    await locator<VolunteerService>().saveInfo(uid, volunteerData);
  }

  void submitForm() async {
    _validationError = null;
    notifyListeners();

    // Re-validate every step; on the first problem, jump to that step and
    // show a dialog so the user knows exactly what to fix.
    for (var page = 0; page <= 2; page++) {
      final error = _errorForStep(page);
      if (error != null) {
        _currentPage = page;
        _showError('Incomplete step', error);
        return;
      }
    }

    setBusy(true);
    _validationError = null;

    try {
      // 1. Validate images
      if (_selectedProfileImage == null ||
          _selectedIdCardImage == null ||
          _selectedIdCardBackImage == null ||
          _selectedStudentIdImage == null ||
          _selectedStudentIdBackImage == null) {
        throw Exception('Please select all required images before submitting.');
      }

      // 2. Upload ALL Images to Storage in Parallel
      // Future.wait executes all these uploads at the exact same time!
      final uploadResults = await Future.wait([
        _uploadImage(_selectedProfileImage!, 'volunteer_profiles'),
        _uploadImage(_selectedIdCardImage!, 'volunteer_id_cards'),
        _uploadImage(_selectedIdCardBackImage!, 'volunteer_id_cards_back'),
        _uploadImage(_selectedStudentIdImage!, 'volunteer_student_ids'),
        _uploadImage(
            _selectedStudentIdBackImage!, 'volunteer_student_ids_back'),
      ]);

      // Map the results back to their variables
      final profileUrl = uploadResults[0];
      final idCardUrl = uploadResults[1];
      final idCardBackUrl = uploadResults[2];
      final studentIdUrl = uploadResults[3];
      final studentIdBackUrl = uploadResults[4];

      if (profileUrl == null ||
          idCardUrl == null ||
          idCardBackUrl == null ||
          studentIdUrl == null ||
          studentIdBackUrl == null) {
        throw Exception(
            'Image upload failed. Please check your connection or Firebase Storage rules.');
      }

      // 3. Save Personal Info to core User Table (AppUser)
      final appUserData = {
        'firstName': firstNameController.text.trim(),
        'lastName': secondNameController.text.trim(),
        'dateOfBirth': _selectedDate,
        'gender': _selectedGender,
        'profilePictureUrl': profileUrl,
        'status': 'pending_verification',
      };
      await _updateAppUser(appUserData);

      // 4. Create/Set Volunteer Info to separate table (VolunteerInfo)

      final volunteerInfoData = {
        'uid': uid,
        'idCardUrl': idCardUrl,
        'idCardBackUrl': idCardBackUrl,
        'studentIdUrl': studentIdUrl,
        'studentIdBackUrl': studentIdBackUrl,
        'currentLevelOfStudy': _selectedLevel,
        'institutionName': institutionController.text.trim(),
        'graduationYear': graduationYearController.text.trim(),
        'tags': _selectedTags,
        'agreementAccepted': _agreementAccepted,
        'status': 'pending_verification',
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _saveVolunteerInfo(volunteerInfoData);

      // 5. Navigate to success/home view
      await _dialogService.showDialog(
          title: 'Success',
          description: 'Volunteer profile submitted for verification!');
      navigateToVolunteerHome();
    } catch (e) {
      _validationError = 'Submission failed: ${e.toString()}';
      await _dialogService.showDialog(
          title: 'Submission Error', description: e.toString());
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  Future navigateToVolunteerHome() async {
    _navigationService
        .clearStackAndShow(Routes.volunteerPendingVerificationView);
  }

  @override
  void dispose() {
    firstNameController.dispose();
    secondNameController.dispose();
    dateOfBirthController.dispose();
    educationController.dispose();
    institutionController.dispose();
    graduationYearController.dispose();
    skillsController.dispose();
    super.dispose();
  }
}
