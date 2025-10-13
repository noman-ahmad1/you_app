import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/models/journal_model.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/views/journal/journal_card.dart';
import 'package:you_app/ui/views/journal/journal_viewmodel.dart';

class AllEntriesView extends ViewModelWidget<JournalViewModel> {
  final List<JournalEntry> entries;
  const AllEntriesView({
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
        ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              width: width * 0.9,
              height: height * 0.19,
              decoration: BoxDecoration(
                color: AppColors.secondaryVeryLight.withAlpha(102),
                border: Border.all(color: AppColors.secondary, width: 2),
                borderRadius: BorderRadius.circular(23),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Your feelings deserve a place.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.crimsonPro(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary),
                  ),
                  Space.verticalSpaceVTiny(context),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        color: AppColors.primaryVeryDark,
                        AppConstants.edit,
                        width: width * 0.07,
                        height: height * 0.025,
                        fit: BoxFit.contain,
                      ),
                      Space.horizontalSpaceVTiny(context),
                      Text(
                        'Start writing a new thought...',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.crimsonPro(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryVeryDark),
                      ),
                    ],
                  ),
                  Space.verticalSpaceTiny(context),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
                      child: Container(
                        padding: EdgeInsets.all(width * 0.007),
                        width: width * 0.8,
                        height: height * 0.065,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryVeryLight.withAlpha(102),
                          border:
                              Border.all(color: AppColors.secondary, width: 2),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(25),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SwipeButton.expand(
                          thumb: ClipRRect(
                            borderRadius: BorderRadius.circular(35),
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 200, sigmaY: 200),
                              child: Container(
                                width: width * 0.115,
                                height: height * 0.05,
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryVeryLight
                                      .withAlpha(102),
                                  border: Border.all(
                                      color: AppColors.secondary, width: 2),
                                  borderRadius: BorderRadius.circular(35),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(25),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Image.asset(
                                    color: AppColors.secondary,
                                    AppConstants.add,
                                    width: width * 0.09,
                                    height: height * 0.035,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          activeThumbColor: Colors.transparent,
                          activeTrackColor: Colors.transparent,
                          onSwipeStart: () async {
                            HapticFeedback.lightImpact();
                            // Play a gentle "swipe start" sound
                            await viewModel.playSwipeSound(isComplete: false);
                          },
                          onSwipe: () async {
                            // While swiping, you could loop a soft whoosh sound
                            await viewModel.playSwipeSound(isComplete: false);
                          },
                          onSwipeEnd: () async {
                            HapticFeedback.mediumImpact();
                            // Stop swipe loop and play "completion chime"
                            viewModel.playSwipeSound(isComplete: true);
                            viewModel.navigateToNewJournalEntry();
                          },
                          child: Row(
                            children: [
                              SizedBox(width: width * 0.14),
                              Text(
                                "Swipe to express",
                                style: GoogleFonts.crimsonPro(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        Space.verticalSpaceTiny(context),
        Text(
          'Previous Entries',
          textAlign: TextAlign.center,
          style: GoogleFonts.crimsonPro(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary),
        ),
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
        // Column(
        //   children: [
        //     Space.verticalSpaceTiny(context),
        //     JournalCard(
        //       onTap: () {
        //         Navigator.push(
        //             context,
        //             MaterialPageRoute(
        //                 builder: (context) => JournalDetails(
        //                       viewModel: JournalViewModel(),
        //                     )));
        //         // viewModel.navigateToJournalDetailsView();
        //       },
        //       category: "Personal",
        //       title: "Calm / Grateful",
        //       description:
        //           "Something about today felt lighter. I went for a short walk in the evening, and the breeze actually made me smile.....",
        //       date: "10, August, 2025",
        //       showEdit: true,
        //       onEditTap: () {
        //         print("Edit tapped!");
        //       },
        //     ),
        //     Space.verticalSpaceTiny(context),
        //     JournalCard(
        //       onTap: () {
        //         Navigator.push(
        //             context,
        //             MaterialPageRoute(
        //                 builder: (context) => JournalDetails(
        //                       viewModel: JournalViewModel(),
        //                     )));
        //       },
        //       category: "Work",
        //       title: "Anxious / Low",
        //       description:
        //           "Today started with a weird heaviness in my chest. I kept thinking about all the things I have not done yet, and it spiraled quickly.....",
        //       date: "8, August, 2025",
        //       showEdit: true,
        //       onEditTap: () {
        //         print("Edit tapped!");
        //       },
        //     ),
        //   ],
        // )
      ],
    );
  }
}
