import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/views/journal/journal_card.dart';
import 'package:you_app/ui/views/journal/journal_details.dart';
import 'package:you_app/ui/views/journal/journal_viewmodel.dart';

// WorkEntriesView
class WorkEntriesView extends StatelessWidget {
  final VolunteerSignupInfoViewModel viewModel;
  const WorkEntriesView({super.key, required this.viewModel});
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    return Column(
      children: [
        Space.verticalSpaceTiny(context),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.05),
            child: ListView.builder(
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7.0),
                  child: JournalCard(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => JournalDetails(
                                    viewModel: VolunteerSignupInfoViewModel(),
                                  )));
                    },
                    category: "Work",
                    title: "Anxious / Low",
                    description:
                        "Today started with a weird heaviness in my chest. I kept thinking about all the things I have not done yet, and it spiraled quickly.....",
                    date: "8, August, 2025",
                    showEdit: true,
                    onEditTap: () {
                      print("Edit tapped!");
                    },
                  ),
                );
              },
              itemCount: 10,
              shrinkWrap: true,
            ),
          ),
        ),
      ],
    );
  }
}
