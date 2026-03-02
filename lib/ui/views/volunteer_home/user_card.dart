import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';

enum UserCardType { activeChat, request }

class UserCard extends StatelessWidget {
  final String username;
  final String lastMessage;
  final String avatarPath;
  // final String category;
  final UserCardType type;
  final String? timeAgo;
  final int? unreadCount;
  final bool? isOnline;

  final VoidCallback? onMessageTap;
  final VoidCallback? onAcceptTap;
  final VoidCallback? onRejectTap;

  const UserCard({
    Key? key,
    required this.username,
    required this.lastMessage,
    required this.avatarPath,
    // required this.category,
    required this.type,
    this.timeAgo,
    this.unreadCount,
    this.isOnline,
    this.onMessageTap,
    this.onAcceptTap,
    this.onRejectTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;

    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.secondaryLight.withAlpha(100),
                  AppColors.primary.withAlpha(70),
                ],
              ),
              border: Border.all(
                  color: AppColors.secondary.withOpacity(0.3), width: 1),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side: Avatar + Info
                Expanded(
                  child: Row(
                    children: [
                      _buildAvatar(width, height),
                      SizedBox(width: width * 0.04),
                      Expanded(
                        child: _buildUserInfo(width, height),
                      ),
                    ],
                  ),
                ),

                // Right side: Actions based on card type
                _buildActions(width, height),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(double width, double height) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(width * 0.015),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.secondaryLight,
                AppColors.primaryLight,
              ],
            ),
          ),
          child: Container(
            padding: EdgeInsets.all(width * 0.01),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              backgroundColor: AppColors.background,
              radius: width * 0.06,
              backgroundImage: AssetImage(avatarPath),
            ),
          ),
        ),
        if (isOnline == true && type == UserCardType.activeChat)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: width * 0.03,
              height: width * 0.03,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserInfo(double width, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          username,
          style: GoogleFonts.crimsonPro(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryVeryDark,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        // SizedBox(height: height * 0.002),
        Text(
          lastMessage,
          style: GoogleFonts.crimsonPro(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.peachDark,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        SizedBox(height: height * 0.002),
        if (timeAgo != null)
          Text(
            timeAgo!,
            style: GoogleFonts.crimsonPro(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.red.withOpacity(0.8),
            ),
          ),
        // SizedBox(height: height * 0.01),
        // _buildCategoryChip(category, width, height),
      ],
    );
  }

  // Widget _buildCategoryChip(String text, double width, double height) {
  //   return Container(
  //     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //     decoration: BoxDecoration(
  //       color: _getCategoryColor(text).withOpacity(0.2),
  //       borderRadius: BorderRadius.circular(16),
  //     ),
  //     child: Text(
  //       text,
  //       style: GoogleFonts.crimsonPro(
  //         fontSize: 12,
  //         fontWeight: FontWeight.w500,
  //         color: _getCategoryColor(text),
  //       ),
  //     ),
  //   );
  // }

  Color _getCategoryColor(String category) {
    // Define colors based on category
    switch (category.toLowerCase()) {
      case 'anxiety':
        return Colors.orange;
      case 'depression':
        return Colors.blue;
      case 'relationships':
        return Colors.pink;
      case 'stress':
        return Colors.red;
      case 'trauma':
        return Colors.purple;
      default:
        return AppColors.secondary;
    }
  }

  Widget _buildActions(double width, double height) {
    if (type == UserCardType.activeChat) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (unreadCount != null && unreadCount! > 0)
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount.toString(),
                style: GoogleFonts.crimsonPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          SizedBox(height: height * 0.01),
          GestureDetector(
            onTap: onMessageTap,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(1, 5),
                  ),
                ],
              ),
              child: Image.asset(
                AppConstants.chat,
                height: height * 0.03,
                width: width * 0.1,
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          GestureDetector(
            onTap: onAcceptTap,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.check,
                color: AppColors.secondary,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: width * 0.03),
          GestureDetector(
            onTap: onRejectTap,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.close,
                color: AppColors.primaryLight,
                size: 20,
              ),
            ),
          ),
        ],
      );
    }
  }
}
