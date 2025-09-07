import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';

class JournalCard extends StatelessWidget {
  final String category;
  final String title;
  final String description;
  final String date;
  final bool showEdit;
  final VoidCallback? onEditTap;
  final VoidCallback onTap;

  const JournalCard({
    super.key,
    required this.category,
    required this.title,
    required this.description,
    required this.date,
    this.showEdit = true,
    this.onEditTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return InkWell(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
          child: Container(
            padding: const EdgeInsets.all(7),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row with Category + Edit button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _blurChip(
                      text: category,
                      width: width * 0.2,
                      height: height * 0.03,
                    ),
                    if (showEdit)
                      GestureDetector(
                        onTap: onEditTap,
                        child: _blurIcon(
                          width: width * 0.07,
                          height: height * 0.03,
                          child: Image.asset(
                            AppConstants.edit,
                            width: width * 0.05,
                            height: height * 0.018,
                            fit: BoxFit.contain,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                  ],
                ),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.crimsonPro(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),

                // Description
                Text(
                  description,
                  textAlign: TextAlign.left,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.crimsonPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryVeryDark,
                  ),
                ),

                // Date chip
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: _blurChip(
                      text: date,
                      width: width * 0.35,
                      height: height * 0.03,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _blurChip({
    required String text,
    required double width,
    required double height,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(35),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.secondaryVeryLight.withAlpha(102),
            border: Border.all(color: AppColors.secondary, width: 2),
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
              text,
              style: GoogleFonts.crimsonPro(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _blurIcon({
    required double width,
    required double height,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.secondaryVeryLight.withAlpha(102),
            border: Border.all(color: AppColors.secondary, width: 2),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
