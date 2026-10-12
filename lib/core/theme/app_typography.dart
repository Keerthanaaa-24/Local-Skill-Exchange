import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextTheme getTextTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final Color textSecondaryColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    const fallback = [
      'Roboto',
      'Segoe UI',
      '-apple-system',
      'BlinkMacSystemFont',
      'Noto Sans',
      'Arial',
      'sans-serif',
      'Noto Color Emoji',
      'Segoe UI Emoji',
      'Apple Color Emoji',
    ];

    return TextTheme(
      displayLarge: GoogleFonts.outfit(fontSize: 57, fontWeight: FontWeight.bold, color: textColor),
      displayMedium: GoogleFonts.outfit(fontSize: 45, fontWeight: FontWeight.bold, color: textColor),
      displaySmall: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: textColor),
      headlineLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w600, color: textColor),
      headlineMedium: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w600, color: textColor),
      headlineSmall: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: textColor),
      titleLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: textColor),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, color: textColor),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: textSecondaryColor),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.normal, color: textSecondaryColor),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondaryColor),
    ).apply(fontFamilyFallback: fallback);
  }
}
