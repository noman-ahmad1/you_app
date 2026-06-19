import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:you_app/ui/common/app_colors.dart';

/// Centralised, modern styling for the first-run feature tour so the user and
/// volunteer showcases look identical and sleek.
///
/// Usage:
///  * Wrap the screen in [ShowCaseWidget] passing [AppShowcase.blur],
///    [AppShowcase.globalActions] and [AppShowcase.globalActionConfig].
///  * Wrap each highlighted widget with [AppShowcase.step].
class AppShowcase {
  const AppShowcase._();

  /// Subtle frosted blur applied behind the spotlight (set on ShowCaseWidget).
  static const double blur = 2.5;

  /// Brand-tinted dimming overlay around the highlighted target.
  static const Color _overlay = AppColors.primaryVeryDark;

  /// A single styled step in the tour.
  static Showcase step({
    required GlobalKey key,
    required String title,
    required String description,
    required Widget child,
  }) {
    return Showcase(
      key: key,
      title: title,
      description: description,
      // --- Spotlight ---
      targetBorderRadius: BorderRadius.circular(20),
      targetPadding: const EdgeInsets.all(6),
      overlayColor: _overlay,
      overlayOpacity: 0.82,
      // --- Tooltip card ---
      tooltipBackgroundColor: Colors.white,
      tooltipBorderRadius: BorderRadius.circular(20),
      tooltipPadding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      titlePadding: const EdgeInsets.only(bottom: 6),
      showArrow: true,
      // --- Typography (modern sans-serif) ---
      titleTextStyle: GoogleFonts.inter(
        fontSize: 16.5,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.primaryVeryDark,
      ),
      descTextStyle: GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.primaryVeryDark.withAlpha(185),
      ),
      child: child,
    );
  }

  /// Global Skip / Next controls shown on every step.
  static List<TooltipActionButton> get globalActions => [
        TooltipActionButton(
          type: TooltipDefaultActionType.skip,
          name: 'Skip',
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          textStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryVeryDark.withAlpha(140),
          ),
        ),
        TooltipActionButton(
          type: TooltipDefaultActionType.next,
          name: 'Next',
          backgroundColor: AppColors.secondary,
          borderRadius: BorderRadius.circular(30),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          textStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          tailIcon: const ActionButtonIcon(
            icon: Icon(Icons.arrow_forward_rounded,
                size: 15, color: Colors.white),
          ),
        ),
      ];

  static TooltipActionConfig get globalActionConfig => const TooltipActionConfig(
        alignment: MainAxisAlignment.spaceBetween,
        position: TooltipActionPosition.inside,
        gapBetweenContentAndAction: 16,
      );
}
