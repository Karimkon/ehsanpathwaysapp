import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// EhsanPathways application theme.
///
/// Primary: Emerald green (#16A34A) - growth, Islam, knowledge
/// Accent:  Warm gold (#F59E0B) - excellence, illumination
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------
  // Brand Colours
  // ---------------------------------------------------------------
  static const Color primaryGreen = Color(0xFF16A34A);
  static const Color primaryGreenLight = Color(0xFF22C55E);
  static const Color primaryGreenDark = Color(0xFF15803D);

  static const Color accentGold = Color(0xFFF59E0B);
  static const Color accentGoldLight = Color(0xFFFBBF24);
  static const Color accentGoldDark = Color(0xFFD97706);

  static const Color surfaceLight = Color(0xFFF8FAF8);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);

  // ---------------------------------------------------------------
  // Light Theme
  // ---------------------------------------------------------------
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: primaryGreen,
    );

    return base.copyWith(
      scaffoldBackgroundColor: surfaceLight,
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Dark Theme
  // ---------------------------------------------------------------
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: primaryGreen,
    );

    return base.copyWith(
      scaffoldBackgroundColor: surfaceDark,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        color: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),
    );
  }
}
