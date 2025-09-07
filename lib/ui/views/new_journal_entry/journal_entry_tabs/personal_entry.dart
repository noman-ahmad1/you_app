import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/views/journal/journal_card.dart';
import 'package:you_app/ui/views/journal/journal_details.dart';
import 'package:you_app/ui/views/journal/journal_viewmodel.dart';
import 'package:you_app/ui/views/new_journal_entry/new_journal_entry_viewmodel.dart';

// WorkEntriesView
class NewPersonalEntryView extends StatelessWidget {
  final NewJournalEntryViewModel viewModel;
  const NewPersonalEntryView({super.key, required this.viewModel});
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'New Entry',
          textAlign: TextAlign.center,
          style: GoogleFonts.crimsonPro(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary),
        ),
        Space.verticalSpaceTiny(context),
        ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              width: width * 0.9,
              height: height * 0.7,
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(23),
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
                          borderRadius: BorderRadius.circular(23),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(25),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          cursorColor: AppColors.secondary,
                          onChanged: (value) {},
                          maxLines: 1,
                          expands: false,
                          textAlignVertical: TextAlignVertical.top,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: 'Title',
                            hintStyle: GoogleFonts.crimsonPro(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary.withAlpha(150)),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Space.verticalSpaceVTiny(context),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(23),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
                        child: Container(
                          padding: EdgeInsets.all(width * 0.007),
                          width: width * 0.8,
                          // height: height * 0.45,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryVeryLight.withAlpha(102),
                            border: Border.all(
                                color: AppColors.secondary, width: 2),
                            borderRadius: BorderRadius.circular(23),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(25),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(7.0),
                            child: TextField(
                              cursorColor: AppColors.secondary,
                              onChanged: (value) {},
                              maxLines: 15,
                              expands: false,
                              textAlignVertical: TextAlignVertical.top,
                              // textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText:
                                    'Today started with a weird heaviness in my chest. I kept thinking about all the things I haven’t done yet, and it spiraled quickly.....',
                                hintStyle: GoogleFonts.crimsonPro(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primaryVeryDark
                                        .withAlpha(150)),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Space.verticalSpaceVTiny(context),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: InkWell(
                      onTap: () {
                        viewModel.showAppBanner(context,
                            title: 'Saved',
                            description: 'Your journal entry has been saved.');
                        viewModel.navigateToJournal();
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(35),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
                          child: Container(
                            padding: EdgeInsets.all(width * 0.007),
                            width: width * 0.8,
                            height: height * 0.065,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withAlpha(102),
                              border: Border.all(
                                  color: AppColors.primaryVeryDark, width: 2),
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
                              child: Text(
                                'Save',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.crimsonPro(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryVeryDark),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
