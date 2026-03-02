import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String imageAssetPath; // For the leading icon (back/logo)
  final VoidCallback? onBackPressed; // Callback for the leading icon
  final VoidCallback? onMenuPressed; // Callback for the *default* trailing icon
  final Widget? trailingAction; // Optional custom trailing widget
  final double height;
  final Color? color; // Renamed for clarity

  const TopBar({
    Key? key,
    required this.title,
    required this.imageAssetPath,
    this.onBackPressed,
    this.onMenuPressed,
    this.trailingAction,
    this.color,
    this.height = kToolbarHeight, // Default AppBar height
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    return Container(
      height: mediaQuery.size.height * 0.09,
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
        padding: const EdgeInsets.fromLTRB(
            16, kToolbarHeight / 4, 16, 0), // Adjust top padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // --- Leading Icon (Back/Logo) ---
            InkWell(
              onTap: onBackPressed,
              child: Image.asset(
                imageAssetPath,
                width: width * 0.11, // Adjusted size slightly
                height: width * 0.11,
                color: color,
                // Add semantic label for accessibility
                semanticLabel: onBackPressed != null ? 'Back' : 'App Logo',
              ),
            ),

            // --- Title ---
            Expanded(
              // Allow title to take available space
              child: Text(
                title,
                textAlign: TextAlign.center, // Center title
                style: GoogleFonts.crimsonPro(
                    fontSize: 27, // Slightly smaller for better fit
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryVeryDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // --- Trailing Action ---
            _buildTrailingAction(context, width),
          ],
        ),
      ),
    );
  }

  /// Builds the trailing widget based on provided parameters.
  Widget _buildTrailingAction(BuildContext context, double screenWidth) {
    // 1. If a custom trailingAction is provided, use it.
    if (trailingAction != null) {
      return trailingAction!;
    }
    // 2. If no custom action, but onMenuPressed is provided, show the default menu icon.
    else if (onMenuPressed != null) {
      return InkWell(
        onTap: onMenuPressed,
        child: Image.asset(
          AppConstants.menu,
          width: screenWidth * 0.07,
          height: screenWidth * 0.07,
          color: AppColors.secondary,
          semanticLabel: 'Menu', // Accessibility label
        ),
      );
    }
    // 3. Otherwise, show an empty SizedBox to maintain layout balance.
    else {
      // Ensure the SizedBox has the same width as the default menu icon
      // to keep the title centered correctly.
      return SizedBox(width: screenWidth * 0.07);
    }
  }

  @override
  // Use the calculated height for preferredSize
  Size get preferredSize =>
      Size.fromHeight(height > 0 ? height : AppBar().preferredSize.height);
}
