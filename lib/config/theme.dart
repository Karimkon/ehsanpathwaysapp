import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// EhsanPathways design system.
///
/// The palette is taken from the material the app is actually made of: the
/// cream of a scanned page, the deep green of a printed board cover, and the
/// burnished gold of its tooling. Nothing here is a neon UI green — the app is
/// a library, and it should feel like one in the hand.
///
/// Three typefaces, each with one job:
///   Amiri              — Arabic scripture and Arabic titles (classical naskh)
///   Lora               — long-form reading: translations, article bodies
///   Plus Jakarta Sans  — interface chrome: labels, buttons, navigation
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------
  // Brand colours
  // ---------------------------------------------------------------

  /// Primary. A printed-board green rather than a screen green.
  static const Color primaryGreen = Color(0xFF0E7C5A);
  static const Color primaryGreenLight = Color(0xFF14A87A);
  static const Color primaryGreenDark = Color(0xFF08543C);

  /// Accent. Burnished, the colour of tooling on a spine — not amber.
  static const Color accentGold = Color(0xFFC08A2E);
  static const Color accentGoldLight = Color(0xFFDCA94A);
  static const Color accentGoldDark = Color(0xFF8F6620);

  // ---------------------------------------------------------------
  // Grounds
  // ---------------------------------------------------------------

  /// Light ground: the cream of the paper in the scans themselves.
  static const Color parchment = Color(0xFFFAF6EC);
  static const Color parchmentDeep = Color(0xFFF2EBDB);
  static const Color sand = Color(0xFFE6DCC6);

  /// Dark ground: ink, biased green so the accent sits naturally on it.
  static const Color ink = Color(0xFF0A1A16);
  static const Color inkSoft = Color(0xFF12241E);
  static const Color inkLine = Color(0xFF1E332B);

  // Retained names so existing screens keep compiling.
  static const Color surfaceLight = parchment;
  static const Color surfaceDark = ink;
  static const Color cardDark = inkSoft;

  // ---------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------
  static const Color textOnLight = Color(0xFF16241F);
  static const Color textMutedLight = Color(0xFF5C6B64);
  static const Color textOnDark = Color(0xFFF3EFE4);
  static const Color textMutedDark = Color(0xFF9AAAA2);

  /// Shelf colours, one per library category, all drawn from the same family
  /// so a grid of covers reads as one collection.
  static const Map<String, Color> shelfColors = {
    'hadith': Color(0xFF0E7C5A),
    'matn': Color(0xFF8F6620),
    'quran-sciences': Color(0xFF1F5C7A),
    'adab': Color(0xFF6B3F6E),
  };

  static Color shelfColor(String? category) =>
      shelfColors[category] ?? primaryGreen;

  // ---------------------------------------------------------------
  // Type roles
  // ---------------------------------------------------------------

  /// Arabic scripture and Arabic titles. Amiri carries harakat properly,
  /// which Inter and friends do not.
  static TextStyle arabic({
    double size = 24,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.9,
  }) =>
      GoogleFonts.amiri(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  /// Long-form English: hadith translations, article bodies.
  static TextStyle reading({
    double size = 16,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.72,
  }) =>
      GoogleFonts.lora(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  /// Interface chrome.
  static TextStyle ui({
    double size = 14,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double height = 1.3,
    double? letterSpacing,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Small uppercase section label.
  static TextStyle eyebrow(Color color) => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.1,
      );

  // ---------------------------------------------------------------
  // Light theme
  // ---------------------------------------------------------------
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.light,
    ).copyWith(
      primary: primaryGreen,
      secondary: accentGold,
      surface: parchment,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: parchment,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: textOnLight,
        displayColor: textOnLight,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: parchment,
        foregroundColor: textOnLight,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: ui(size: 18, weight: FontWeight.w800, color: textOnLight),
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: const DividerThemeData(color: sand, thickness: 1, space: 1),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: parchmentDeep,
        side: BorderSide.none,
        labelStyle: ui(size: 13, color: textOnLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: ui(size: 14, weight: FontWeight.w500, color: textMutedLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: sand),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGreen, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Dark theme
  // ---------------------------------------------------------------
  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primaryGreenLight,
      secondary: accentGoldLight,
      surface: ink,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: ink,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: textOnDark,
        displayColor: textOnDark,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: ink,
        foregroundColor: textOnDark,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: ui(size: 18, weight: FontWeight.w800, color: textOnDark),
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        color: inkSoft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: const DividerThemeData(color: inkLine, thickness: 1, space: 1),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: inkSoft,
        side: BorderSide.none,
        labelStyle: ui(size: 13, color: textOnDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inkSoft,
        hintStyle: ui(size: 14, weight: FontWeight.w500, color: textMutedDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: inkLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGreenLight, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
