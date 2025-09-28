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

class VolunteerSignupInfoViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  DateTime? _selectedDate;
  File? _selectedImage;
  String? _selectedGender;
  String? _selectedLevel;
  String? _selectedCategory;
  int _currentPage = 0;
  bool _agreementAccepted = false;
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

  File? get selectedImage => _selectedImage;
  DateTime? get selectedDate => _selectedDate;
  String? get selectedGender => _selectedGender;
  String? get selectedLevel => _selectedLevel;
  String? get selectedCategory => _selectedCategory;
  int get currentPage => _currentPage;
  bool get agreementAccepted => _agreementAccepted;
  List<String> get genders => _genders;
  List<String> get levels => _levels;
  List<String> get categories => _categories;

  final firstNameController = TextEditingController();
  final secondNameController = TextEditingController();
  final dateOfBirthController = TextEditingController();
  final educationController = TextEditingController();
  final institutionController = TextEditingController();
  final graduationYearController = TextEditingController();
  final skillsController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

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
            colorScheme: ColorScheme.light(
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
        _selectedImage = File(pickedFile.path);
        notifyListeners();
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void submitForm() {
    navigateToVolunteerHome();
    notifyListeners();
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
