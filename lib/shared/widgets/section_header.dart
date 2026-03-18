import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A section title row with an optional subtitle and a trailing "See All"
/// action button. Provides consistent, beautiful spacing across every
/// content section in the app.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.trailingText = 'See All',
    this.onTrailingTap,
    this.padding = const EdgeInsets.fromLTRB(16, 24, 16, 12),
  });

  /// Bold section title.
  final String title;

  /// Optional lighter subtitle shown below the title.
  final String? subtitle;

  /// Completely custom trailing widget (overrides [trailingText]).
  final Widget? trailing;

  /// Text for the default trailing button (ignored if [trailing] is set).
  final String trailingText;

  /// Called when the default trailing button is tapped.
  final VoidCallback? onTrailingTap;

  /// Outer padding around the entire header row.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Titles -------------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    letterSpacing: -0.3,
                    height: 1.25,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // -- Action button ------------------------------------------------
          if (trailing != null)
            trailing!
          else if (onTrailingTap != null)
            _SeeAllButton(
              text: trailingText,
              onTap: onTrailingTap!,
              isDark: isDark,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal – the "See All" button
// ---------------------------------------------------------------------------

class _SeeAllButton extends StatelessWidget {
  const _SeeAllButton({
    required this.text,
    required this.onTap,
    required this.isDark,
  });

  final String text;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF16A34A);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: primaryGreen.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: primaryGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
