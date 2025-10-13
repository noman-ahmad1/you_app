import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/models/journal_model.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/dialogs/info_alert/info_alert_dialog.dart';
import 'package:you_app/ui/views/journal/filter_bar.dart';
import 'package:you_app/ui/views/new_journal_entry/journal_entry_bar.dart';
import 'package:you_app/ui/views/new_journal_entry/journal_entry_tabs/personal_entry.dart';
import 'package:you_app/ui/views/new_journal_entry/journal_entry_tabs/work_entry.dart';

import 'new_journal_entry_viewmodel.dart';

class NewJournalEntryView extends StackedView<NewJournalEntryViewModel> {
  final JournalEntry? journalEntry;
  const NewJournalEntryView({
    Key? key,
    this.journalEntry,
  }) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    NewJournalEntryViewModel viewModel,
    Widget? child,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    return Scaffold(
        appBar: TopBar(
          title: 'Journal',
          imageAssetPath: AppConstants.back,
          color: AppColors.secondary,
          onBackPressed: () {
            viewModel.back();
          },
        ),
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
                Space.verticalSpaceTiny(context),
                JournalEntryBar(
                    currentIndex: viewModel.currentIndex,
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
        return NewWorkEntryView(viewModel: viewModel, key: ValueKey('Work'));
      case 1:
        return NewPersonalEntryView(
            viewModel: viewModel, key: ValueKey('Personal'));
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
