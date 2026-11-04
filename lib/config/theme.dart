import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ehsan Pathways design system.
///
/// Four colours carry the identity:
///   Deep Emerald  #0B3B26  the brand, hero surfaces and primary actions
///   Warm Cream    #FAF8F5  the light ground, like the paper of a mushaf
///   Metallic Gold #D4AF37  ornament, highlights and the dark-mode accent
///   Dark Slate    #1A202C  the dark ground and the light-mode ink
///
/// Every text/ground pair below has a measured WCAG contrast ratio. Body text
/// meets AAA (7:1) in both themes; secondary text meets at least AA (4.5:1).
/// Metallic gold is 2:1 on cream, so on light grounds it is decoration only and
/// gold-coloured text uses [AppColors.goldDeep] (5.4:1) instead.
///
/// Typefaces, one job each:
///   Amiri Quran        Qur'anic text (a naskh cut designed for the mushaf)
///   Amiri              other Arabic: hadith, du'a, titles
///   Lora               long-form English: translations, articles, headings
///   Plus Jakarta Sans  interface: labels, buttons, navigation
class AppColors {
  AppColors._();

  // -- Emerald --------------------------------------------------------------
  static const Color emerald950 = Color(0xFF06251A);
  static const Color emerald900 = Color(0xFF0B3B26); // brand
  static const Color emerald800 = Color(0xFF0E4A30);
  static const Color emerald700 = Color(0xFF135E3E); // primary on light (7.7:1)
  static const Color emerald600 = Color(0xFF18734C);
  static const Color emerald500 = Color(0xFF23905F);
  static const Color emerald400 = Color(0xFF4DB585); // primary on dark (6.4:1)
  static const Color emerald300 = Color(0xFF86D3AE);
  static const Color emerald100 = Color(0xFFD8EEE2);
  static const Color emerald50 = Color(0xFFEDF6F1);

  // -- Gold -----------------------------------------------------------------
  static const Color goldDarkest = Color(0xFF5A460C);
  static const Color goldDeep = Color(0xFF7F6311); // gold text on light (5.4:1)
  static const Color gold = Color(0xFFD4AF37); // metallic
  static const Color goldLight = Color(0xFFE6CB6E);
  static const Color goldPale = Color(0xFFF3E5B5);
  static const Color goldTint = Color(0xFFFAF3DC);

  // -- Light grounds --------------------------------------------------------
  static const Color cream = Color(0xFFFAF8F5);
  static const Color creamDeep = Color(0xFFF3EFE8);
  static const Color sand = Color(0xFFE7E1D6); // hairlines
  static const Color sandDeep = Color(0xFFD6CEC0); // borders, disabled
  static const Color card = Color(0xFFFFFFFF);

  // -- Light text -----------------------------------------------------------
  static const Color ink = Color(0xFF1A202C); // 15.4:1 on cream
  static const Color ink2 = Color(0xFF2D3748); // 11.3:1
  static const Color muted = Color(0xFF4A5568); // 7.1:1
  static const Color subtle = Color(0xFF5E6878); // 5.3:1

  // -- Dark grounds ---------------------------------------------------------
  static const Color slate = Color(0xFF1A202C); // dark ground
  static const Color slateDeep = Color(0xFF131821);
  static const Color slateCard = Color(0xFF222A38);
  static const Color slateRaised = Color(0xFF2B3546);
  static const Color slateLine = Color(0xFF364154);

  // -- Dark text ------------------------------------------------------------
  static const Color onDark = Color(0xFFF5F2EA); // 14.6:1 on slate
  static const Color onDarkMuted = Color(0xFFB4BDCB); // 8.6:1
  static const Color onDarkSubtle = Color(0xFF97A2B4); // 6.3:1

  // -- Semantic -------------------------------------------------------------
  static const Color danger = Color(0xFFB42318);
  static const Color dangerOnDark = Color(0xFFF97066);
  static const Color dangerTint = Color(0xFFFEE4E2);
  static const Color dangerDeep = Color(0xFF55160C);

  // Jewel tones for content categories, muted to sit beside emerald and gold.
  static const Color sapphire = Color(0xFF2C5F8A);
  static const Color sapphireLight = Color(0xFF7FAAD0);
  static const Color sapphireTint = Color(0xFFE3EDF6);
  static const Color sapphireDeep = Color(0xFF162F45);
  static const Color amethyst = Color(0xFF5B4B8A);
  static const Color amethystLight = Color(0xFFA99BD3);
  static const Color amethystTint = Color(0xFFECE8F5);
  static const Color amethystDeep = Color(0xFF2B2342);
  static const Color teal = Color(0xFF1F6F78);
  static const Color ruby = Color(0xFF9F2D44);
  static const Color rubyDeep = Color(0xFF4F1622);
}

/// Shared gradients.
class AppGradients {
  AppGradients._();

  /// Hero surfaces: headers, the prayer card, the Qibla dial.
  static const LinearGradient emerald = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.emerald950, AppColors.emerald900, AppColors.emerald700],
    stops: [0, 0.55, 1],
  );

  /// Metallic gold: a light band across the middle reads as burnished metal.
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFB8922A),
      AppColors.goldLight,
      AppColors.gold,
      Color(0xFFA9862A),
    ],
    stops: [0, 0.38, 0.62, 1],
  );

  /// Thin gold rule used under hero headings.
  static const LinearGradient goldRule = LinearGradient(
    colors: [Color(0x00D4AF37), AppColors.gold, Color(0x00D4AF37)],
  );
}

/// Motion tokens. Durations stay short so the app never feels slow, and
/// [AppMotion.of] drops them to zero when the user asks for reduced motion.
class AppMotion {
  AppMotion._();

  static const Duration quick = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration emphasized = Duration(milliseconds: 420);
  static const Curve curve = Curves.easeOutCubic;

  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : d;
}

/// Layout breakpoints. 600 dp is where an iPad mini in portrait begins; 1024
/// covers iPad Air/Pro landscape.
class Breakpoints {
  Breakpoints._();

  static const double medium = 600;
  static const double expanded = 1024;

  /// Max width for a column of reading text or a form.
  static const double readable = 720;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= medium;

  /// Grid columns for card lists at the current width.
  static int columns(BuildContext context, {double minTileWidth = 320}) {
    final width = MediaQuery.sizeOf(context).width;
    return math.max(1, (width / minTileWidth).floor()).clamp(1, 4);
  }
}

/// A frosted card: blurred backdrop, translucent fill and a hairline edge.
/// Falls back to an opaque fill when the user enables Increase Contrast.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.onDark = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// True when the card sits on an emerald or slate hero surface.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final isDark = onDark || Theme.of(context).brightness == Brightness.dark;
    final highContrast = MediaQuery.highContrastOf(context);
    final fill = highContrast
        ? (isDark ? AppColors.slateCard : AppColors.card)
        : (isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.72));
    final edge = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : AppColors.sand.withValues(alpha: 0.9);

    final body = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: edge),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (highContrast) return body;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: body,
      ),
    );
  }
}

/// Hero-header content that always fits: it keeps the full width (so text
/// wraps normally) and scales down only if it is taller than the space a
/// collapsing app bar gives it, e.g. under a notch with large Dynamic Type.
class FitHeader extends StatelessWidget {
  const FitHeader({
    super.key,
    required this.child,
    this.alignment = Alignment.center,
  });
  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: SizedBox(width: c.maxWidth, child: child),
    ),
  );
}

/// Soft elevated card shadow. Shadows vanish on slate, so dark mode relies on
/// the card's hairline border instead.
List<BoxShadow> softShadow(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const []
    : [
        BoxShadow(
          color: AppColors.emerald950.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColors.emerald950.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------
  // Legacy names. Existing screens refer to these; they now resolve to the
  // new palette so the whole app moves together.
  // ---------------------------------------------------------------
  static const Color primaryGreen = AppColors.emerald700;
  static const Color primaryGreenLight = AppColors.emerald400;
  static const Color primaryGreenDark = AppColors.emerald900;
  static const Color accentGold = AppColors.gold;
  static const Color accentGoldLight = AppColors.goldLight;
  static const Color accentGoldDark = AppColors.goldDeep;
  static const Color parchment = AppColors.cream;
  static const Color parchmentDeep = AppColors.creamDeep;
  static const Color sand = AppColors.sand;
  static const Color ink = AppColors.slate;
  static const Color inkSoft = AppColors.slateCard;
  static const Color inkLine = AppColors.slateLine;
  static const Color surfaceLight = AppColors.cream;
  static const Color surfaceDark = AppColors.slate;
  static const Color cardDark = AppColors.slateCard;
  static const Color textOnLight = AppColors.ink;
  static const Color textMutedLight = AppColors.muted;
  static const Color textOnDark = AppColors.onDark;
  static const Color textMutedDark = AppColors.onDarkMuted;

  /// Shelf colours, one per library category, from the same jewel family.
  static const Map<String, Color> shelfColors = {
    'hadith': AppColors.emerald800,
    'matn': AppColors.goldDarkest,
    'quran-sciences': AppColors.sapphire,
    'adab': AppColors.amethyst,
  };

  static Color shelfColor(String? category) =>
      shelfColors[category] ?? AppColors.emerald800;

  // ---------------------------------------------------------------
  // Type roles
  // ---------------------------------------------------------------

  /// Qur'anic text.
  static TextStyle quran({
    double size = 28,
    Color? color,
    double height = 2.1,
  }) => GoogleFonts.amiriQuran(fontSize: size, color: color, height: height);

  /// Font family names for code that builds its own TextStyle. Reading them
  /// through google_fonts registers and loads the font; a bare 'Amiri'
  /// string does not, and silently falls back to the system font.
  static String get arabicFamily => GoogleFonts.amiri().fontFamily!;
  static String get quranFamily => GoogleFonts.amiriQuran().fontFamily!;

  /// Other Arabic: hadith matn, du'a, Arabic titles.
  static TextStyle arabic({
    double size = 24,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.9,
  }) => GoogleFonts.amiri(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );

  /// Long-form English.
  static TextStyle reading({
    double size = 16,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.72,
  }) => GoogleFonts.lora(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );

  /// Display headings.
  static TextStyle display({
    double size = 28,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double height = 1.2,
  }) => GoogleFonts.lora(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: -0.2,
  );

  /// Interface chrome.
  static TextStyle ui({
    double size = 14,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double height = 1.3,
    double? letterSpacing,
  }) => GoogleFonts.plusJakartaSans(
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
  // Themes
  // ---------------------------------------------------------------

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.emerald900,
    onPrimary: Colors.white,
    primaryContainer: AppColors.emerald100,
    onPrimaryContainer: AppColors.emerald950,
    secondary: AppColors.goldDeep,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.goldTint,
    onSecondaryContainer: AppColors.goldDarkest,
    tertiary: AppColors.sapphire,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.sapphireTint,
    onTertiaryContainer: AppColors.sapphireDeep,
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: AppColors.dangerTint,
    onErrorContainer: AppColors.dangerDeep,
    surface: AppColors.cream,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.muted,
    surfaceContainerLowest: AppColors.card,
    surfaceContainerLow: AppColors.card,
    surfaceContainer: AppColors.creamDeep,
    surfaceContainerHigh: AppColors.creamDeep,
    surfaceContainerHighest: AppColors.sand,
    outline: AppColors.sandDeep,
    outlineVariant: AppColors.sand,
    shadow: AppColors.emerald950,
    scrim: Colors.black,
    inverseSurface: AppColors.slate,
    onInverseSurface: AppColors.onDark,
    inversePrimary: AppColors.emerald400,
    surfaceTint: Colors.transparent,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.emerald400,
    onPrimary: AppColors.emerald950,
    primaryContainer: AppColors.emerald800,
    onPrimaryContainer: AppColors.emerald100,
    secondary: AppColors.gold,
    onSecondary: AppColors.emerald950,
    secondaryContainer: AppColors.goldDarkest,
    onSecondaryContainer: AppColors.goldPale,
    tertiary: AppColors.sapphireLight,
    onTertiary: AppColors.sapphireDeep,
    tertiaryContainer: AppColors.sapphireDeep,
    onTertiaryContainer: AppColors.sapphireTint,
    error: AppColors.dangerOnDark,
    onError: AppColors.dangerDeep,
    errorContainer: AppColors.dangerDeep,
    onErrorContainer: AppColors.dangerTint,
    surface: AppColors.slate,
    onSurface: AppColors.onDark,
    onSurfaceVariant: AppColors.onDarkMuted,
    surfaceContainerLowest: AppColors.slateDeep,
    surfaceContainerLow: AppColors.slateCard,
    surfaceContainer: AppColors.slateCard,
    surfaceContainerHigh: AppColors.slateRaised,
    surfaceContainerHighest: AppColors.slateRaised,
    outline: AppColors.slateLine,
    outlineVariant: AppColors.slateRaised,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.cream,
    onInverseSurface: AppColors.ink,
    inversePrimary: AppColors.emerald700,
    surfaceTint: Colors.transparent,
  );

  static ThemeData get light => _build(_lightScheme);
  static ThemeData get dark => _build(_darkScheme);

  static ThemeData _build(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.slateCard : AppColors.card;
    final line = isDark ? AppColors.slateLine : AppColors.sand;
    final text = scheme.onSurface;
    final mutedText = scheme.onSurfaceVariant;
    final accent = isDark ? AppColors.goldLight : AppColors.emerald900;
    final link = isDark ? AppColors.emerald300 : AppColors.emerald700;

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: text, displayColor: text)
        .copyWith(
          displaySmall: display(size: 32, color: text),
          headlineMedium: display(size: 26, color: text),
          headlineSmall: display(size: 22, color: text),
          titleLarge: ui(size: 18, weight: FontWeight.w800, color: text),
        );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 22, vertical: 15);
    final buttonText = ui(size: 15, weight: FontWeight.w700);
    OutlineInputBorder field(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: w),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      textTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        // No titleTextStyle: AppBar then styles its title from
        // textTheme.titleLarge in its foregroundColor, so white-on-emerald
        // headers stay legible.
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: line),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: isDark ? AppColors.slateCard : AppColors.creamDeep,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: line),
        labelStyle: ui(size: 13, color: text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(64, 50),
          padding: buttonPadding,
          shape: shape,
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(64, 50),
          padding: buttonPadding,
          shape: shape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: link,
          side: BorderSide(
            color: isDark ? AppColors.slateLine : AppColors.sandDeep,
          ),
          minimumSize: const Size(64, 50),
          padding: buttonPadding,
          shape: shape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: link,
          textStyle: ui(size: 14, weight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? AppColors.gold : AppColors.emerald900,
        foregroundColor: isDark ? AppColors.emerald950 : Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: isDark ? AppColors.slateDeep : AppColors.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: isDark ? AppColors.emerald800 : AppColors.emerald100,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => ui(
            size: 11.5,
            weight: s.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: s.contains(WidgetState.selected) ? text : mutedText,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected) ? accent : mutedText,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? AppColors.slateDeep : AppColors.card,
        indicatorColor: isDark ? AppColors.emerald800 : AppColors.emerald100,
        selectedIconTheme: IconThemeData(color: accent),
        unselectedIconTheme: IconThemeData(color: mutedText),
        selectedLabelTextStyle: ui(
          size: 12,
          weight: FontWeight.w800,
          color: text,
        ),
        unselectedLabelTextStyle: ui(size: 12, color: mutedText),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.slateDeep : AppColors.card,
        selectedItemColor: accent,
        unselectedItemColor: mutedText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: mutedText,
        indicatorColor: isDark ? AppColors.gold : AppColors.emerald900,
        dividerColor: line,
        labelStyle: ui(size: 14, weight: FontWeight.w800),
        unselectedLabelStyle: ui(size: 14),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: link,
        textColor: text,
        titleTextStyle: ui(size: 15, color: text),
        subtitleTextStyle: ui(
          size: 13,
          weight: FontWeight.w500,
          color: mutedText,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? (isDark ? AppColors.emerald500 : AppColors.emerald700)
              : null,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: isDark ? AppColors.gold : AppColors.emerald700,
        thumbColor: accent,
        inactiveTrackColor: line,
        overlayColor: AppColors.gold.withValues(alpha: 0.16),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? AppColors.gold : AppColors.emerald700,
        linearTrackColor: line,
        circularTrackColor: line,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.cream : AppColors.slate,
        contentTextStyle: ui(
          size: 14,
          color: isDark ? AppColors.ink : AppColors.onDark,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: ui(size: 18, weight: FontWeight.w800, color: text),
        contentTextStyle: ui(
          size: 14,
          weight: FontWeight.w500,
          color: mutedText,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        // A sensible width on iPad instead of edge to edge.
        constraints: const BoxConstraints(maxWidth: 640),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        hintStyle: ui(size: 14, weight: FontWeight.w500, color: mutedText),
        labelStyle: ui(size: 14, weight: FontWeight.w500, color: mutedText),
        prefixIconColor: mutedText,
        suffixIconColor: mutedText,
        border: field(line),
        enabledBorder: field(line),
        focusedBorder: field(
          isDark ? AppColors.gold : AppColors.emerald700,
          1.6,
        ),
        errorBorder: field(scheme.error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
    );
  }
}
