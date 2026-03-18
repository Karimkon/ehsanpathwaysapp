import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shown on screens that require authentication when the user is not signed in.
class LoginPrompt extends StatelessWidget {
  const LoginPrompt({super.key, required this.feature});

  /// Short noun for what the feature is, e.g. "notes", "bookmarks", "history".
  final String feature;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const green = Color(0xFF16A34A);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: green.withValues(alpha: isDark ? 0.12 : 0.08),
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 44,
                color: green.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sign in to view your $feature',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF111827),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Create a free account to save and access your $feature across all your devices.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.push('/login'),
              style: FilledButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('Sign In'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push('/register'),
              child: Text(
                'Create a free account',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A beautiful, centred empty-state widget shown when a list or section
/// has no data. Features a large icon, title, subtitle, and an optional
/// call-to-action button.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconSize = 72,
    this.compact = false,
  });

  /// Large decorative icon.
  final IconData icon;

  /// Primary message.
  final String title;

  /// Optional supporting message.
  final String? subtitle;

  /// Text for the optional action button.
  final String? actionLabel;

  /// Called when the action button is tapped.
  final VoidCallback? onAction;

  /// Override colour for the icon circle.
  final Color? iconColor;

  /// Diameter of the icon.
  final double iconSize;

  /// If true, uses tighter spacing (e.g. inside a smaller container).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primaryGreen = Color(0xFF16A34A);
    final Color accent = iconColor ?? primaryGreen;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 32,
          vertical: compact ? 24 : 48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // -- Decorated icon circle ------------------------------------
            Container(
              width: iconSize + 32,
              height: iconSize + 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: isDark ? 0.12 : 0.08),
                    accent.withValues(alpha: isDark ? 0.06 : 0.03),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: iconSize + 8,
                  height: iconSize + 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
                  ),
                  child: Icon(
                    icon,
                    size: iconSize * 0.55,
                    color: accent.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),

            SizedBox(height: compact ? 20 : 28),

            // -- Title ------------------------------------------------------
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: compact ? 17 : 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF111827),
                letterSpacing: -0.3,
                height: 1.3,
              ),
            ),

            // -- Subtitle ---------------------------------------------------
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ],

            // -- Action button ----------------------------------------------
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? 20 : 28),
              FilledButton.icon(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  textStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
