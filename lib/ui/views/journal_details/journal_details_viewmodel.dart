import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/models/journal_model.dart';
import 'package:you_app/services/firestore_service.dart';

class JournalDetailsViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _firestoreService = locator<FirestoreService>();
  final _dialogService = locator<DialogService>();

  final JournalEntry entry;

  JournalDetailsViewModel({required this.entry});

  String get category =>
      entry.label.name[0].toUpperCase() + entry.label.name.substring(1);

  /// Returns the entry's timestamp as a formatted string.
  String get date => entry.timestamp != null
      ? DateFormat('d MMMM, yyyy').format(entry.timestamp!)
      : 'Entry Details';

  Future<void> deleteEntry() async {
    final response = await _dialogService.showConfirmationDialog(
      title: 'Delete Entry',
      description:
          'Are you sure you want to delete this journal entry? This action cannot be undone.',
      confirmationTitle: 'Delete',
      cancelTitle: 'Cancel',
    );

    // If the user confirmed the deletion
    if (response?.confirmed == true) {
      setBusy(true);
      try {
        // You'll need to add a `deleteJournalEntry` method to your FirestoreService
        await _firestoreService.journal.deleteJournalEntry(
          userId: entry.userId,
          entryId: entry.id!,
        );
        _navigationService.back(); // Go back after successful deletion
      } catch (e) {
        setBusy(false);
        await _dialogService.showDialog(
          title: 'Error',
          description: 'Could not delete the entry. Please try again.',
        );
      }
    }
  }

  void navigateToNewJournalEntry() {
    _navigationService.navigateToNewJournalEntryView(journalEntry: entry);
  }

  void back() {
    _navigationService.back();
  }
}
