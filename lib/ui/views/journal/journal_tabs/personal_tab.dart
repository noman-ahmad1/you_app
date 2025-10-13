import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/models/journal_model.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/views/journal/journal_card.dart';
import 'package:you_app/ui/views/journal/journal_viewmodel.dart';

class PersonalEntriesView extends ViewModelWidget<JournalViewModel> {
  final List<JournalEntry> entries;
  const PersonalEntriesView({
    Key? key,
    required this.entries,
  }) : super(key: key, reactive: false);
  @override
  Widget build(BuildContext context, JournalViewModel viewModel) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    return Column(
      children: [
        Space.verticalSpaceTiny(context),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    'No journal entries yet.\nStart by swiping above to add your first entry!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.crimsonPro(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondary),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                  itemCount: entries.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 7.0),
                      child: JournalCard(
                        onTap: () {
                          viewModel.navigateToJournalDetails(entry);
                        },
                        category: entry.label.name[0].toUpperCase() +
                            entry.label.name.substring(
                                1), // Capitalizes "personal" or "work"
                        title: entry.title,
                        description: entry.content,
                        date: entry.timestamp != null
                            ? DateFormat('d, MMMM, yyyy')
                                .format(entry.timestamp!)
                            : 'No Date',
                        showEdit: true,
                        onEditTap: () {
                          viewModel.navigateToEditJournalEntry(entry);
                          print("Edit tapped!");
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
