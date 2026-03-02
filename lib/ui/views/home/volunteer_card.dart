import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';

// Define the enum here or import it if it's in a separate file
enum VolunteerCardType {
  availableChat,
  pendingRequest,
  activeChat,
}

class VolunteerCard extends StatelessWidget {
  final String username;
  final String avatarPath;
  final int rating; // number of stars (0–5)
  final List<String> categories;
  final VoidCallback? onActionTap; // Renamed for clarity
  final VolunteerCardType type; // Use the enum

  const VolunteerCard({
    Key? key,
    required this.username,
    required this.avatarPath,
    required this.rating,
    required this.categories,
    required this.type,
    this.onActionTap, // Renamed parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;

    // --- Determine Icon and Action based on Type ---
    String iconAssetPath;
    switch (type) {
      case VolunteerCardType.availableChat:
        iconAssetPath =
            AppConstants.smsRequest; // Icon to initiate chat/request
        break;
      case VolunteerCardType.pendingRequest:
        iconAssetPath = AppConstants
            .pending; // Icon showing pending status (replace with your asset)
        break;
      case VolunteerCardType.activeChat:
        iconAssetPath = AppConstants
            .activeChat; // Icon showing an active chat (replace with your asset)
        break;
    }
    // ---------------------------------------------

    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
        child: Container(
          padding: const EdgeInsets.fromLTRB(2, 2, 5, 2),
          width: width * 0.9,
          height: height * 0.085,
          decoration: BoxDecoration(
            color: AppColors.secondaryVeryLight.withAlpha(70),
            border: Border.all(color: AppColors.secondary, width: 2),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side (Avatar and User Info - unchanged)
              Row(
                children: [
                  _buildAvatar(width, height),
                  SizedBox(width: width * 0.02),
                  _buildUserInfo(width, height),
                ],
              ),

              // Right side action button
              GestureDetector(
                onTap: onActionTap, // Use the renamed callback
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
                    child: Container(
                      padding: EdgeInsets.all(width * 0.025),
                      width: width * 0.135,
                      height: height * 0.06,
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
                      child: Image.asset(
                        iconAssetPath, // Use the dynamically determined icon
                        color: AppColors.secondary,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets (_buildAvatar, _buildUserInfo, _buildCategoryChip) ---
  // These remain unchanged. Paste your existing helper widget code here.
  Widget _buildAvatar(double width, double height) {
    // ... your existing code ...
    return ClipRRect(
      borderRadius: BorderRadius.circular(35),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
        child: Container(
          padding: EdgeInsets.all(width * 0.01),
          width: width * 0.16,
          height: height * 0.075,
          decoration: BoxDecoration(
            color: AppColors.secondaryVeryLight.withAlpha(102),
            border: Border.all(color: AppColors.secondary, width: 2),
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            avatarPath,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(double width, double height) {
    // ... your existing code ...
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          username,
          style: GoogleFonts.crimsonPro(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryVeryDark,
          ),
        ),
        Row(
          children: [
            Text(
              'Rating:',
              style: GoogleFonts.crimsonPro(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryVeryDark,
              ),
            ),
            SizedBox(width: width * 0.01),
            ...List.generate(5, (index) {
              return Image.asset(
                index < rating ? AppConstants.starFill : AppConstants.star,
                width: width * 0.042,
                color: AppColors.secondary,
              );
            }),
          ],
        ),
        Row(
          children: categories
              .map((category) => Padding(
                    padding: EdgeInsets.only(right: width * 0.01),
                    child: _buildCategoryChip(category, width, height),
                  ))
              .toList(),
        )
      ],
    );
  }

  Widget _buildCategoryChip(String text, double width, double height) {
    // ... your existing code ...
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: width * 0.02),
          height: height * 0.025,
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
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
