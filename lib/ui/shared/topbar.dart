import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final String? leadingIconAsset;
  final VoidCallback? onLeadingPressed;
  final List<Widget>? trailingActions;
  final double height;
  final Color? iconColor;
  final Color? titleColor;
  final Color? backgroundColor;

  // NEW: Toggle between Home style (false) and Standard style (true)
  final bool isCenterTitle;
  final bool isDodo;

  const TopBar({
    Key? key,
    this.title,
    this.subtitle,
    this.leadingIconAsset,
    this.onLeadingPressed,
    this.trailingActions,
    this.iconColor,
    this.titleColor,
    this.backgroundColor,
    this.height = kToolbarHeight + 20,
    this.isCenterTitle = true, // Defaults to true for all other screens!
    this.isDodo = true, // Defaults to false for all other screens!
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;

    return Column(
      children: [
        Container(
          height: height + mediaQuery.padding.top,
          padding: EdgeInsets.only(top: mediaQuery.padding.top),
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.primary,
            // boxShadow: [
            //   BoxShadow(
            //     color: AppColors.primaryVeryDark,
            //     blurRadius: 4,
            //     offset: Offset(0, 2),
            //   ),
            // ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: isCenterTitle
                ? _buildCenterTitleLayout(width)
                : _buildLeftTitleLayout(width),
          ),
        ),
        Container(
          height: 2,
          color: AppColors.background,
        ),
      ],
    );
  }

  // ==========================================
  // LAYOUT 1: HOME SCREEN (Left-Aligned + Subtitle)
  // ==========================================
  Widget _buildLeftTitleLayout(double width) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leadingIconAsset != null) ...[
          InkWell(
            onTap: onLeadingPressed,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Matches the darker purple circle in your screenshot
                color: AppColors.secondary.withAlpha(50),
              ),
              child: Image.asset(
                leadingIconAsset!,
                width: width * 0.08,
                height: width * 0.08,
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: GoogleFonts.crimsonPro(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryVeryDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: GoogleFonts.crimsonPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryVeryDark.withAlpha(150)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (trailingActions != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: trailingActions!.map((widget) {
              return Padding(
                padding:
                    const EdgeInsets.only(left: 10.0), // Spacing between icons
                child: widget,
              );
            }).toList(),
          ),
      ],
    );
  }

  // ==========================================
  // LAYOUT 2: OTHER SCREENS (Perfectly Centered)
  // ==========================================
  Widget _buildCenterTitleLayout(double width) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Left Action
        if (leadingIconAsset != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    Border.all(color: AppColors.primaryVeryDark.withAlpha(50)),
              ),
              child: InkWell(
                onTap: onLeadingPressed,
                child: Image.asset(
                  leadingIconAsset!,
                  width: width * 0.1,
                  height: width * 0.1,
                  color: iconColor,
                ),
              ),
            ),
          ),

        // Center Title
        if (title != null && !isDodo)
          Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.crimsonPro(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? AppColors.primaryVeryDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 10),
                Image.asset(
                  AppConstants.dodo,
                  width: width * 0.15,
                  height: width * 0.15,
                ),
              ],
            ),
          )
        else if (title != null)
          Align(
            alignment: Alignment.center,
            child: Text(
              title!,
              textAlign: TextAlign.center,
              style: GoogleFonts.crimsonPro(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: titleColor ?? AppColors.primaryVeryDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        // Right Action(s)
        if (trailingActions != null)
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: trailingActions!.map((widget) {
                return Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: widget,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
