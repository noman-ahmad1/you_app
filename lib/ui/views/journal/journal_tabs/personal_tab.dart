import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/models/journal_model.dart';
import 'package:you_app/ui/common/animation_decoder.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Space.verticalSpaceTiny(context),
        if (entries.isEmpty)
          SizedBox(
            height: height * 0.45,
            child: Center(
              child: Lottie.asset(
                AppConstants.empty,
                decoder: customDecoder,
                width: 200,
                height: 200,
              ),
            ),
          )
        else
          ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: width * 0.05),
            itemCount: entries.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 7.0),
                child: JournalCard(
                  onTap: () {
                    viewModel.navigateToJournalDetails(entry);
                  },
                  category: entry.label.name[0].toUpperCase() +
                      entry.label.name.substring(1),
                  title: entry.title,
                  description: entry.content,
                  date: entry.timestamp != null
                      ? DateFormat('d, MMMM, yyyy').format(entry.timestamp!)
                      : 'No Date',
                  showEdit: true,
                  onEditTap: () {
                    viewModel.navigateToEditJournalEntry(entry);
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}
