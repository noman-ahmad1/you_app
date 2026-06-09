import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/models/app_user.dart';
import 'package:you_app/services/auth_service.dart';

class ProfileViewModel extends ReactiveViewModel {
  final _navigationService = locator<NavigationService>();
  final _authService = locator<AuthenticationService>();

  @override
  List<ListenableServiceMixin> get listenableServices => [_authService];

  AppUser? get currentUser => _authService.currentUser;

  void goBack() {
    _navigationService.back();
  }

  String get formattedDateOfBirth {
    final dob = currentUser?.dateOfBirth;
    if (dob == null) return 'Not specified';
    return '${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}';
  }

  String get displayRole {
    final role = currentUser?.role;
    if (role == null) return 'User';
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.volunteer:
        return 'Volunteer';
      case UserRole.user:
        return 'Member';
    }
  }

  double get completionPercentage {
    if (currentUser == null) return 0.0;

    int completedFields = 0;
    int totalFields = 8; // Including profilePictureUrl

    if (currentUser!.firstName.isNotEmpty) completedFields++;
    if (currentUser!.lastName.isNotEmpty) completedFields++;
    if (currentUser!.username != null && currentUser!.username!.isNotEmpty)
      completedFields++;
    if (currentUser!.email.isNotEmpty) completedFields++;
    if (currentUser!.phoneNumber != null &&
        currentUser!.phoneNumber!.isNotEmpty) completedFields++;
    if (currentUser!.dateOfBirth != null) completedFields++;
    if (currentUser!.gender != null && currentUser!.gender!.isNotEmpty)
      completedFields++;
    if (currentUser!.profilePictureUrl != null &&
        currentUser!.profilePictureUrl!.isNotEmpty) completedFields++;

    return completedFields / totalFields;
  }

  void navigateToEditProfile() {
    _navigationService.navigateToEditProfileView();
  }

  Future<void> deleteAccount() async {
    final dialogService = locator<DialogService>();
    final response = await dialogService.showConfirmationDialog(
      title: 'Delete Account',
      description:
          'Are you sure you want to completely delete your account? This action cannot be undone and all your data will be permanently removed.',
      confirmationTitle: 'Delete',
      cancelTitle: 'Cancel',
    );

    if (response?.confirmed == true) {
      setBusy(true);
      try {
        await _authService.deleteCurrentAccount();
        _navigationService.clearStackAndShow(Routes.welcomeView);
      } catch (e) {
        dialogService.showDialog(
          title: 'Error',
          description: 'Failed to delete account: $e',
        );
      } finally {
        setBusy(false);
      }
    }
  }
}
