import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/views/journal/journal_viewmodel.dart';

class JournalDetails extends StatelessWidget {
  final VolunteerSignupInfoViewModel viewModel;
  const JournalDetails({super.key, required this.viewModel});
  @override
  Widget build(BuildContext context) {
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
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Entry',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Previously shared thoughts.',
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
                              filter:
                                  ImageFilter.blur(sigmaX: 200, sigmaY: 200),
                              child: Container(
                                padding: EdgeInsets.all(width * 0.007),
                                width: width * 0.8,
                                height: height * 0.065,
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryVeryLight
                                      .withAlpha(102),
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
                                child: Center(
                                  child: Text(
                                    'Calm / Grateful',
                                    style: GoogleFonts.crimsonPro(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.secondary),
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
                                filter:
                                    ImageFilter.blur(sigmaX: 200, sigmaY: 200),
                                child: Container(
                                  padding: EdgeInsets.all(width * 0.007),
                                  width: width * 0.8,
                                  // height: height * 0.45,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryVeryLight
                                        .withAlpha(102),
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
                                    child: Text(
                                      'Something about today felt lighter. I went for a short walk in the evening, and the breeze actually made me smile.....',
                                      style: GoogleFonts.crimsonPro(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryVeryDark),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Space.verticalSpaceVTiny(context),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(35),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 200, sigmaY: 200),
                                    child: Container(
                                      padding: EdgeInsets.all(width * 0.007),
                                      width: width * 0.25,
                                      height: height * 0.065,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withAlpha(102),
                                        border: Border.all(
                                            color: AppColors.primaryVeryDark,
                                            width: 2),
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
                                          'Personal',
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
                                InkWell(
                                  onTap: () {
                                    viewModel.navigateToNewJournalEntry();
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(35),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 200, sigmaY: 200),
                                      child: Container(
                                        padding: EdgeInsets.all(width * 0.007),
                                        width: width * 0.53,
                                        height: height * 0.065,
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryVeryLight
                                              .withAlpha(102),
                                          border: Border.all(
                                              color: AppColors.secondary,
                                              width: 2),
                                          borderRadius:
                                              BorderRadius.circular(35),
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
                                            'Edit',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.crimsonPro(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.secondary),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )));
  }
}
