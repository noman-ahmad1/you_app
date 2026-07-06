import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';

/// A full-width primary button that shows an inline spinner + [busyLabel] while
/// an async action runs (disabling itself), then returns to [label]. Keeps
/// action feedback consistent across the app.
class BusyButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onPressed;
  final String label;
  final String busyLabel;
  final Color backgroundColor;
  final Color foregroundColor;
  final double borderRadius;
  final double fontSize;

  const BusyButton({
    super.key,
    required this.busy,
    required this.onPressed,
    required this.label,
    this.busyLabel = 'Please wait…',
    this.backgroundColor = AppColors.secondary,
    this.foregroundColor = Colors.white,
    this.borderRadius = 25,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: busy ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        disabledBackgroundColor: backgroundColor.withAlpha(150),
        disabledForegroundColor: foregroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: busy
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  busyLabel,
                  style: GoogleFonts.crimsonPro(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
                ),
              ],
            )
          : Text(
              label,
              style: GoogleFonts.crimsonPro(
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
    );
  }
}
