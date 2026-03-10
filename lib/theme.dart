import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Color constants matching globals.css HSL values ---
class AppColors {
  // Light theme
  static const Color background = Color(0xFFF5F8FF);      // HSL 210 40% 98%
  static const Color foreground = Color(0xFF1F2937);      // HSL 215 25% 15%
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF1F2937);
  static const Color primary = Color(0xFF4F8EF7);         // HSL 217 91% 60%
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF33C17A);       // HSL 152 69% 47%
  static const Color secondaryForeground = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFEBF2FF);           // HSL 210 30% 95%
  static const Color mutedForeground = Color(0xFF6B7280); // HSL 215 16% 47%
  static const Color destructive = Color(0xFFEF4444);     // HSL 0 84% 60%
  static const Color border = Color(0xFFD9E4F0);          // HSL 214 20% 90%
  static const Color chartAmber = Color(0xFFF5A623);      // HSL 38 92% 50%
  static const Color chartPurple = Color(0xFF8B5CF6);     // HSL 262 83% 58%
  static const Color chartBlue = Color(0xFF0EA5E9);       // HSL 200 80% 50%

  // Dark theme
  static const Color darkBackground = Color(0xFF0F172A);  // HSL 222 47% 8%
  static const Color darkForeground = Color(0xFFE2E8F0);
  static const Color darkCard = Color(0xFF1A2744);        // HSL 222 47% 11%
  static const Color darkMuted = Color(0xFF1E3258);       // HSL 223 47% 16%
  static const Color darkMutedForeground = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF243352);

  static List<Color> chartColors = [
    primary,
    secondary,
    chartAmber,
    destructive,
    chartPurple,
    chartBlue,
  ];
}

ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.primaryForeground,
      secondary: AppColors.secondary,
      onSecondary: AppColors.secondaryForeground,
      error: AppColors.destructive,
      surface: AppColors.card,
      onSurface: AppColors.foreground,
      outline: AppColors.border,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      headlineSmall: GoogleFonts.dmSans(
        fontWeight: FontWeight.w700,
        color: AppColors.foreground,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontWeight: FontWeight.w600,
        color: AppColors.foreground,
      ),
      bodyMedium: GoogleFonts.inter(
        color: AppColors.foreground,
      ),
      bodySmall: GoogleFonts.inter(
        color: AppColors.mutedForeground,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.card,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.mutedForeground,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.primaryForeground,
      secondary: AppColors.secondary,
      onSecondary: AppColors.secondaryForeground,
      error: AppColors.destructive,
      surface: AppColors.darkCard,
      onSurface: AppColors.darkForeground,
      outline: AppColors.darkBorder,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineSmall: GoogleFonts.dmSans(
        fontWeight: FontWeight.w700,
        color: AppColors.darkForeground,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontWeight: FontWeight.w600,
        color: AppColors.darkForeground,
      ),
      bodyMedium: GoogleFonts.inter(color: AppColors.darkForeground),
      bodySmall: GoogleFonts.inter(color: AppColors.darkMutedForeground),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.darkBorder, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkCard,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.darkMutedForeground,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
