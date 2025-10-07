import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/ui/common/app_colors.dart';
// Import the VolunteerInfo model
// import 'package:you_app/models/volunteer_info.dart';
// Added missing service imports for storage and database
// import 'package:you_app/services/storage_service.dart'; // UNCOMMENTED
import 'package:you_app/services/firestore_service.dart'; // UNCOMMENTED

class VolunteerSignupInfoViewModel extends BaseViewModel {
  final String uid;

  // --- Services ---
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  // final _storageService =
  //     locator<StorageService>(); // UNCOMMENTED: Added for Firebase Storage
  final _firestoreService =
      locator<FirestoreService>(); // UNCOMMENTED: Added for Firestore

  // --- Image States ---
  File? _selectedProfileImage;
  File? _selectedIdCardImage;
  File? _selectedStudentIdImage;

  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedLevel;
  String? _selectedCategory;
  int _currentPage = 0;
  bool _agreementAccepted = false;
  String? _validationError;

  final List<String> _genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say'
  ];
  final List<String> _levels = [
    'Undergraduate Student',
    'Graduate Student',
    'PhD Candidate',
    'Post Doc'
  ];
  final List<String> _categories = [
    'Clinical Psychology',
    'Counseling Psychology',
    'School Psychology',
    'Social Work',
    'Psychiatry',
    'Other'
  ];

  // --- Getters ---
  File? get selectedProfileImage => _selectedProfileImage;
  File? get selectedIdCardImage => _selectedIdCardImage;
  // NEW Getter
  File? get selectedStudentIdImage => _selectedStudentIdImage;

  DateTime? get selectedDate => _selectedDate;
  String? get selectedGender => _selectedGender;
  String? get selectedLevel => _selectedLevel;
  String? get selectedCategory => _selectedCategory;
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

  void setCategory(String? category) {
    _selectedCategory = category;
  }

  void toggleAgreement(bool? value) {
    _agreementAccepted = value ?? false;
    notifyListeners();
  }

  void nextPage() {
    // NOTE: This check should include validation logic before moving pages
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
        final imageFile = File(pickedFile.path);

        // Updated logic to set the correct state variable
        if (imageType == 'profile') {
          _selectedProfileImage = imageFile;
        } else if (imageType == 'gov_id') {
          _selectedIdCardImage = imageFile;
        } else if (imageType == 'student_id') {
          _selectedStudentIdImage = imageFile;
        }

        notifyListeners();
        // Only pop if the modal bottom sheet is active (used for profile/ID card)
        if (imageType == 'profile' || imageType == 'gov_id') {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      print('Error picking image: $e');
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

  // 2. Government ID Card Picker (NEW implementation using modal sheet)
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
                'Upload Government ID Card',
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
                        imageType: 'gov_id'), // Correct type
                  ),
                  _buildImagePickerOption(
                    context,
                    Icons.photo_library,
                    'Gallery',
                    () => pickImage(ImageSource.gallery, context,
                        imageType: 'gov_id'), // Correct type
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

  // 3. Student ID Card Picker (Kept as single pick for now, but easily updatable)
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
                'Upload Student ID Card',
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
                        imageType: 'student_id'), // Correct type
                  ),
                  _buildImagePickerOption(
                    context,
                    Icons.photo_library,
                    'Gallery',
                    () => pickImage(ImageSource.gallery, context,
                        imageType: 'student_id'), // Correct type
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

  // REAL upload function using _storageService
  Future<String?> _uploadImage(File image, String folderName) async {
    if (image.existsSync()) {
      final storagePath =
          '$folderName/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Changed to use the actual storage service (assuming it has a uploadFile method)
      // final downloadUrl = await _storageService.uploadFile(image, storagePath);

      // return downloadUrl;
    }
    return null;
  }

  // UPDATED: Now uses firestoreService.user.update
  Future<void> _updateAppUser(Map<String, dynamic> userData) async {
    await _firestoreService.user.update(uid, userData);
  }

  // UPDATED: Now uses firestoreService.volunteer_info.saveInfo
  Future<void> _saveVolunteerInfo(Map<String, dynamic> volunteerData) async {
    await _firestoreService.volunteer_info.saveInfo(uid, volunteerData);
  }

  void submitForm() async {
    _validationError = null;
    notifyListeners();

    // 1. Validation (omitted internal content for brevity)
    // if (_selectedProfileImage == null) {
    //   _validationError = 'Please upload a Profile Photo.';
    //   notifyListeners();
    //   return;
    // }

    // if (_selectedIdCardImage == null) {
    //   _validationError =
    //       'Please upload your Government ID Card for verification.';
    //   notifyListeners();
    //   return;
    // }

    // if (_selectedStudentIdImage == null) {
    //   _validationError =
    //       'Please upload your Student ID Card for academic verification.';
    //   notifyListeners();
    //   return;
    // }

    if (firstNameController.text.isEmpty ||
        secondNameController.text.isEmpty ||
        dateOfBirthController.text.isEmpty ||
        _selectedGender == null) {
      _validationError = 'All personal fields must be completed.';
      notifyListeners();
      return;
    }

    // Check if academic fields are filled (assuming they are set on page 2/3)
    if (institutionController.text.isEmpty ||
        graduationYearController.text.isEmpty ||
        _selectedLevel == null ||
        _selectedCategory == null) {
      _validationError = 'All academic fields must be completed.';
      notifyListeners();
      return;
    }

    // Final page and agreement check
    if (_currentPage != 2 || !_agreementAccepted) {
      _validationError = 'Please complete all steps and accept the agreement.';
      notifyListeners();
      return;
    }

    setBusy(true);

    try {
      // 2. Upload ALL Images to Storage
      final profileUrl = "profileDemoUrl";
      // await _uploadImage(_selectedProfileImage!, 'volunteer_profiles');
      final idCardUrl = "idDemoUrl";
      // await _uploadImage(_selectedIdCardImage!, 'volunteer_id_cards');
      final studentIdUrl = "studentIdDemoUrl";
      // await _uploadImage(_selectedStudentIdImage!, 'volunteer_student_ids');

      if (profileUrl == null || idCardUrl == null || studentIdUrl == null) {
        throw Exception('Failed to upload one or more required images.');
      }

      // 3. Save Personal Info to core User Table (AppUser)
      final appUserData = {
        'firstName': firstNameController.text.trim(),
        'lastName': secondNameController.text.trim(),
        'dateOfBirth': _selectedDate,
        'gender': _selectedGender,
        'profilePictureUrl': profileUrl,
      };
      print('User ID before update: ${appUserData['uid']}');
      await _updateAppUser(appUserData);

      // 4. Create/Set Volunteer Info to separate table (VolunteerInfo)

      final volunteerInfoData = {
        'uid': uid,
        'idCardUrl': idCardUrl,
        'studentIdUrl': studentIdUrl,
        'currentLevelOfStudy': _selectedLevel,
        'institutionName': institutionController.text.trim(),
        'graduationYear': graduationYearController.text.trim(),
        'specializationCategory': _selectedCategory,
        'agreementAccepted': _agreementAccepted,
        'status': 'pending_verification',
        'createdAt': DateTime.now(),
      };
      await _saveVolunteerInfo(volunteerInfoData);

      // 5. Navigate to success/home view
      await _dialogService.showDialog(
          title: 'Success',
          description: 'Volunteer profile submitted for verification!');
      navigateToVolunteerHome();
    } catch (e) {
      _validationError =
          'Submission failed: Please check your connection and try again.';
      await _dialogService.showDialog(
          title: 'Submission Error', description: e.toString());
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  Future navigateToVolunteerHome() async {
    _navigationService.navigateToVolunteerHomeView();
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
