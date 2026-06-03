import 'dart:io';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/models/app_user.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/user_service.dart';
import 'package:you_app/services/storage_service.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/utils/image_compressor_helper.dart';

class EditProfileViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _authService = locator<AuthenticationService>();
  final _userService = locator<UserService>();
  final _storageService = locator<StorageService>();
  final _dialogService = locator<DialogService>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  DateTime? _selectedDate;
  String? _selectedGender;
  File? _selectedProfileImage;
  String _fullPhoneNumber = '';
  
  final List<String> genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

  AppUser? get currentUser => _authService.currentUser;
  DateTime? get selectedDate => _selectedDate;
  String? get selectedGender => _selectedGender;
  File? get selectedProfileImage => _selectedProfileImage;

  void initialize() {
    if (currentUser != null) {
      firstNameController.text = currentUser!.firstName;
      lastNameController.text = currentUser!.lastName;
      usernameController.text = currentUser!.username ?? '';
      
      String phone = currentUser!.phoneNumber ?? '';
      _fullPhoneNumber = phone;
      if (phone.startsWith('+92')) {
        phoneController.text = phone.substring(3);
      } else {
        phoneController.text = phone;
      }
      
      _selectedDate = currentUser!.dateOfBirth;
      _selectedGender = currentUser!.gender;
      notifyListeners();
    }
  }

  void updateSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setGender(String? gender) {
    _selectedGender = gender;
    notifyListeners();
  }

  void setPhoneNumber(String phone) {
    _fullPhoneNumber = phone;
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
        // Compress the image before setting it
        final compressedFile = await ImageCompressorHelper.compressImage(originalFile);
        
        _selectedProfileImage = compressedFile;
        notifyListeners();
        Navigator.of(context).pop(); // Close the modal
      }
    } catch (e) {
      print('Error picking image: $e');
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
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Profile Picture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryVeryDark,
          ),
        ),
      ],
    );
  }

  Future<void> saveProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    if (firstNameController.text.trim().isEmpty || lastNameController.text.trim().isEmpty) {
      _dialogService.showDialog(title: 'Error', description: 'First and last name cannot be empty.');
      return;
    }

    setBusy(true);

    try {
      String? newProfilePictureUrl = currentUser!.profilePictureUrl;

      // Handle profile picture update
      if (_selectedProfileImage != null) {
        // Delete old profile picture if exists
        if (newProfilePictureUrl != null && newProfilePictureUrl.isNotEmpty) {
          await _storageService.deleteFileByUrl(newProfilePictureUrl);
        }

        // Upload new profile picture
        final path = 'user_profiles/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
        newProfilePictureUrl = await _storageService.uploadFile(_selectedProfileImage!, path);
      }

      final updateData = {
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'username': usernameController.text.trim(),
        'phoneNumber': phoneController.text.trim().isEmpty ? '' : _fullPhoneNumber.trim(),
        'dateOfBirth': _selectedDate,
        'gender': _selectedGender,
        'profilePictureUrl': newProfilePictureUrl,
      };

      await _userService.update(uid, updateData);
      await _authService.checkCurrentUserStatus(); // Refresh local user data
      
      _navigationService.back();
    } catch (e) {
      _dialogService.showDialog(title: 'Update Failed', description: e.toString());
    } finally {
      setBusy(false);
    }
  }

  void goBack() {
    _navigationService.back();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
