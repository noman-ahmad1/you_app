import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/models/journal_model.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/views/new_journal_entry/journal_entry_bar.dart';
import 'package:you_app/ui/views/new_journal_entry/journal_entry_tabs/text_entry.dart';
import 'package:you_app/ui/views/new_journal_entry/journal_entry_tabs/voice_entry.dart';

import 'new_journal_entry_viewmodel.dart';

class NewJournalEntryView extends StackedView<NewJournalEntryViewModel> {
  final JournalEntry? journalEntry;
  const NewJournalEntryView({
    super.key,
    this.journalEntry,
  });

  @override
  Widget builder(
    BuildContext context,
    NewJournalEntryViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
        body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppConstants.background),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              children: [
                TopBar(
                  leadingIconAsset: AppConstants.back, // Your 'Y' logo asset
                  title: journalEntry == null ? 'New Entry' : 'Edit Entry',
                  onLeadingPressed: () {
                    Navigator.pop(context);
                  },
                  trailingActions: [],
                ),
                Space.verticalSpaceTiny(context),
                JournalEntryBar(
                    currentIndex: viewModel.currentIndex,
                    isPremium: viewModel.isPremium,
                    onTap: (viewModel.setTab)),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildTabContent(viewModel),
                  ),
                ),
              ],
            )));
  }

  Widget _buildTabContent(NewJournalEntryViewModel viewModel) {
    switch (viewModel.currentIndex) {
      case 0:
        return TextJournalEntryView(
            viewModel: viewModel, key: const ValueKey('Text'));
      case 1:
        return VoiceJournalEntryView(
            viewModel: viewModel, key: const ValueKey('Voice'));
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  NewJournalEntryViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      NewJournalEntryViewModel(entry: journalEntry);

  @override
  void onViewModelReady(NewJournalEntryViewModel viewModel) {
    // This will pre-fill the form if we are in "Edit Mode"
    viewModel.initialize();
  }
}
