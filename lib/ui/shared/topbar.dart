import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String imageAssetPath;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onBackPressed;
  final double height;
  final bool showMenuIcon;
  final Color? color;

  const TopBar({
    Key? key,
    required this.title,
    required this.imageAssetPath,
    this.onMenuPressed,
    this.onBackPressed,
    this.showMenuIcon = true,
    this.color,
    this.height = kToolbarHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    return Container(
      height: height * 0.09,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryVeryDark,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo/image that scales with screen width
            InkWell(
              onTap: onBackPressed,
              child: Image.asset(
                imageAssetPath,
                width: width * 0.12,
                height: width * 0.12,
                color: color,
              ),
            ),
            // SizedBox(
            //   width: MediaQuery.of(context).size.width * 0.12,
            //   child: Image.asset(
            //     imageAssetPath,
            //     fit: BoxFit.contain,
            //   ),
            // ),

            // Title with responsive font size
            Text(
              title,
              style: GoogleFonts.crimsonPro(
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryVeryDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Menu icon (only shown if callback is provided)
            if (showMenuIcon && onMenuPressed != null)
              InkWell(
                onTap: onMenuPressed,
                child: Image.asset(
                  AppConstants.menu,
                  width: width * 0.07,
                  height: width * 0.07,
                  color: AppColors.secondary,
                ),
              ),
            if (!showMenuIcon || onMenuPressed == null)
              SizedBox(width: width * 0.07),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
