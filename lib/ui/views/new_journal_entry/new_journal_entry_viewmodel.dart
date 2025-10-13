import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/models/journal_model.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/firestore_service.dart';
import 'package:you_app/ui/shared/app_banner.dart';

class NewJournalEntryViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _firestoreService = locator<FirestoreService>();
  final _authenticationService = locator<AuthenticationService>();

  final titleController = TextEditingController();
  final contentController = TextEditingController();

  final JournalEntry? _editingEntry;

  int _currentIndex;
  int get currentIndex => _currentIndex;
  bool get isEditing => _editingEntry != null;

  NewJournalEntryViewModel({JournalEntry? entry})
      : _editingEntry = entry,
        _currentIndex = (entry?.label == JournalLabel.personal) ? 1 : 0;

  void initialize() {
    if (isEditing) {
      titleController.text = _editingEntry!.title;
      contentController.text = _editingEntry!.content;
    }
  }

  Future<void> saveJournalEntry({required JournalLabel label}) async {
    // 1. **Validation**: Check if the fields are empty.
    if (titleController.text.isEmpty || contentController.text.isEmpty) {
      _dialogService.showDialog(
        title: 'Incomplete Entry',
        description:
            'Please make sure to fill out both the title and the content of your entry.',
      );
      return;
    }

    setBusy(true);

    try {
      // 2. **Get User ID**: Safely get the current user's ID.
      final userId = _authenticationService.currentUser?.uid;
      if (userId == null) {
        throw Exception('No user is currently logged in.');
      }

      // 3. **Create Model**: Build the JournalEntry object.
      final newEntry = JournalEntry(
        userId: userId,
        title: titleController.text.trim(),
        content: contentController.text.trim(),
        label: label, // Use the label passed from the view
      );

      // 4. **Call Firestore Service**: Save the entry.
      await _firestoreService.journal.addJournalEntry(newEntry);

      // 5. **Handle Success**: Show a success banner and navigate away.
      // (Using your existing showAppBanner method would go here if you pass the context)
      await _dialogService.showDialog(
        title: 'Saved!',
        description: 'Your journal entry has been successfully saved.',
        buttonTitle: 'Great!',
      );
      _navigationService.back();
    } catch (e) {
      // 6. **Handle Failure**: Show an error dialog.
      _dialogService.showDialog(
        title: 'Error',
        description:
            'We could not save your entry at this time. Please try again.',
      );
    } finally {
      setBusy(false);
    }
  }

  /// Updates an EXISTING journal entry.
  Future<void> updateJournalEntry() async {
    if (!isEditing) return; // Safety check

    setBusy(true);
    try {
      final updatedData = {
        'title': titleController.text.trim(),
        'content': contentController.text.trim(),
      };
      await _firestoreService.journal.updateJournalEntry(
        userId: _editingEntry!.userId,
        entryId: _editingEntry!.id!,
        data: updatedData,
      );
      _navigationService.back(); // Go back on success
    } catch (e) {
      // Handle error
    } finally {
      setBusy(false);
    }
  }

  void setTab(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void showAppBanner(BuildContext context,
      {required String title, required String description}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: AppBanner(title: title, description: description),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Future back() async {
    _navigationService.back();
  }

  Future navigateToJournal() async {
    _navigationService.navigateToJournalView();
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }
}
