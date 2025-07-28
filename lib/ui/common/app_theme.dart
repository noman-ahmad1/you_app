import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData theme = ThemeData(
    fontFamily: 'CrimsonPro',
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      elevation: 0.0,
      backgroundColor: AppColors.background,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: GoogleFonts.crimsonPro(
        color: AppColors.textPrimary,
        fontSize: 20.0,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: GoogleFonts.crimsonProTextTheme().copyWith(
      headlineMedium: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyMedium: const TextStyle(
        fontSize: 16,
        color: AppColors.textSecondary,
      ),
      labelSmall: const TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
      ),
      bodySmall: const TextStyle(
        fontSize: 13,
        color: AppColors.textSecondary,
      ),
      displaySmall: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryVeryDark,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(27),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: AppColors.secondary,
      surface: AppColors.background,
    ),
  );

  // Custom Button Sizes
  static ButtonStyle smallButton = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
    textStyle: const TextStyle(fontSize: 14),
  );

  static ButtonStyle mediumButton = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    textStyle: const TextStyle(fontSize: 16),
  );

  static ButtonStyle largeButton = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 125),
    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  );
}
