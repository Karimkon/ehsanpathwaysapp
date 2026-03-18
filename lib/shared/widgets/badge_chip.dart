import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pre-defined colour variants for [BadgeChip].
enum BadgeVariant {
  green,
  blue,
  purple,
  red,
  amber,
  gray,
}

/// Size variants for [BadgeChip].
enum BadgeSize {
  small,
  regular,
}

/// A colourful pill-shaped chip / badge for content types, categories,
/// or status indicators.
///
/// Supports six colour variants, two sizes, and an optional leading icon.
class BadgeChip extends StatelessWidget {
  const BadgeChip({
    super.key,
    required this.label,
    this.variant = BadgeVariant.green,
    this.size = BadgeSize.regular,
    this.icon,
    this.onTap,
    this.filled = false,
  });

  /// The text shown inside the chip.
  final String label;

  /// Colour variant.
  final BadgeVariant variant;

  /// Small or regular.
  final BadgeSize size;

  /// Optional leading icon.
  final IconData? icon;

  /// Called when the chip is tapped.
  final VoidCallback? onTap;

  /// If true the chip has a solid background; otherwise a tinted surface.
  final bool filled;

  // -----------------------------------------------------------------------
  // Colour map
  // -----------------------------------------------------------------------

  static const Map<BadgeVariant, Color> _foregroundColors = {
    BadgeVariant.green: Color(0xFF16A34A),
    BadgeVariant.blue: Color(0xFF2563EB),
    BadgeVariant.purple: Color(0xFF7C3AED),
    BadgeVariant.red: Color(0xFFDC2626),
    BadgeVariant.amber: Color(0xFFD97706),
    BadgeVariant.gray: Color(0xFF6B7280),
  };

  static const Map<BadgeVariant, Color> _backgroundColors = {
    BadgeVariant.green: Color(0xFFDCFCE7),
    BadgeVariant.blue: Color(0xFFDBEAFE),
    BadgeVariant.purple: Color(0xFFEDE9FE),
    BadgeVariant.red: Color(0xFFFEE2E2),
    BadgeVariant.amber: Color(0xFFFEF3C7),
    BadgeVariant.gray: Color(0xFFF3F4F6),
  };

  static const Map<BadgeVariant, Color> _darkBackgroundColors = {
    BadgeVariant.green: Color(0xFF052E16),
    BadgeVariant.blue: Color(0xFF172554),
    BadgeVariant.purple: Color(0xFF2E1065),
    BadgeVariant.red: Color(0xFF450A0A),
    BadgeVariant.amber: Color(0xFF451A03),
    BadgeVariant.gray: Color(0xFF1F2937),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = _foregroundColors[variant]!;
    final bg = filled
        ? fg
        : (isDark ? _darkBackgroundColors[variant]! : _backgroundColors[variant]!);
    final textColor = filled ? Colors.white : fg;

    final bool isSmall = size == BadgeSize.small;
    final double hPad = isSmall ? 8 : 12;
    final double vPad = isSmall ? 3 : 5;
    final double fontSize = isSmall ? 10 : 12;
    final double iconSize = isSmall ? 12 : 14;

    final child = Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: filled
            ? null
            : Border.all(
                color: fg.withValues(alpha: isDark ? 0.25 : 0.15),
                width: 1,
              ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: textColor),
            SizedBox(width: isSmall ? 3 : 5),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.2,
              height: 1.3,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: child);
    }

    return child;
  }
}
