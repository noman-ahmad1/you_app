import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/views/journal/journal_card.dart';
import 'package:you_app/ui/views/journal/journal_details.dart';
import 'package:you_app/ui/views/journal/journal_viewmodel.dart';

class AllEntriesView extends StatelessWidget {
  final VolunteerSignupInfoViewModel viewModel;
  const AllEntriesView({super.key, required this.viewModel});
  @override
  Widget build(BuildContext context) {
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
                    category: "Personal",
                    title: "Calm / Grateful",
                    description:
                        "Something about today felt lighter. I went for a short walk in the evening, and the breeze actually made me smile.....",
                    date: "10, August, 2025",
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
