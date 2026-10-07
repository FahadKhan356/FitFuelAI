import 'package:fitfuel_ai/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class AppTheme {
  static ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(AppColors.background),
      primaryColor: const Color(AppColors.primary),
      colorScheme: const ColorScheme.dark(
        primary: Color(AppColors.primary),
        secondary: Color(AppColors.secondary),
        tertiary: Color(AppColors.accent),
        surface: Color(AppColors.surface),
        error: Color(AppColors.error),
        onPrimary: Color(AppColors.textPrimary),
        onSecondary: Color(AppColors.textPrimary),
        onTertiary: Color(AppColors.textPrimary),
        onSurface: Color(AppColors.textPrimary),
        onError: Color(AppColors.textPrimary),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ).copyWith(
        // Display
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: const Color(AppColors.textPrimary),
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: const Color(AppColors.textPrimary),
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(AppColors.textPrimary),
        ),
        // Headline
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: const Color(AppColors.textPrimary),
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(AppColors.textPrimary),
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(AppColors.textPrimary),
        ),
        // Title
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: const Color(AppColors.textPrimary),
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: const Color(AppColors.textPrimary),
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(AppColors.textPrimary),
        ),
        // Body
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: const Color(AppColors.textPrimary),
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(AppColors.textSecondary),
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: const Color(AppColors.textTertiary),
        ),
        // Label
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(AppColors.textPrimary),
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(AppColors.textPrimary),
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: const Color(AppColors.textSecondary),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(AppColors.background),
        foregroundColor: const Color(AppColors.textPrimary),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(AppColors.textPrimary),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppColors.primary),
          foregroundColor: const Color(AppColors.textPrimary),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(AppColors.primary),
          side: const BorderSide(color: Color(AppColors.borderLight)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(AppColors.primary),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(AppColors.card),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(AppColors.borderLight)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(AppColors.primary), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(AppColors.error)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(AppColors.error), width: 2),
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(AppColors.textSecondary),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(AppColors.textPrimary),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(AppColors.card),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(AppColors.surface),
        selectedItemColor: Color(AppColors.primary),
        unselectedItemColor: Color(AppColors.textSecondary),
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
    );
}
