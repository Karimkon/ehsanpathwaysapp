import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart' show Share;

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/core/services/content_service.dart';
import 'package:ehsan_pathways/shared/widgets/badge_chip.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final _contentServiceProvider =
    Provider<ContentService>((ref) => ContentService());

final khutbahDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, slug) async {
  final service = ref.watch(_contentServiceProvider);
  return service.fetchKhutbahDetail(slug);
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class KhutbahDetailScreen extends ConsumerWidget {
  const KhutbahDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final khutbahAsync = ref.watch(khutbahDetailProvider(slug));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return khutbahAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(backgroundColor: AppTheme.primaryGreenDark),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(
            5,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ShimmerWrap(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Khutbah')),
        body: EmptyState(
          icon: Icons.mic_off_rounded,
          title: 'Could not load khutbah',
          subtitle: 'Please check your connection and try again.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(khutbahDetailProvider(slug)),
        ),
      ),
      data: (khutbah) => _KhutbahDetailBody(
        khutbah: khutbah,
        slug: slug,
        isDark: isDark,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _KhutbahDetailBody extends StatelessWidget {
  const _KhutbahDetailBody({
    required this.khutbah,
    required this.slug,
    required this.isDark,
  });

  final Map<String, dynamic> khutbah;
  final String slug;
  final bool isDark;

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  void _onShare(BuildContext context, String title) {
    Share.share(
      'Listen to "$title" on Ehsan Pathways\nhttps://ehsanpathways.com',
      subject: title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = khutbah['title'] as String? ?? '';
    final description = khutbah['description'] as String? ?? '';
    final mosqueName = khutbah['mosque_name'] as String? ?? '';
    final city = khutbah['city'] as String? ?? '';
    final deliveredAt = khutbah['delivered_at'] as String?;
    final isJumuah = khutbah['is_jumuah'] as bool? ?? false;
    final videoUuid = khutbah['video_uuid'] as String?;
    final keyPoints = khutbah['key_points'] as List<dynamic>? ?? [];
    final scholar = khutbah['scholar'] as Map<String, dynamic>?;
    final scholarName = scholar?['name'] as String? ?? '';
    final scholarSlug = scholar?['slug'] as String?;
    final scholarBio = scholar?['bio'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreenDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Khutbah',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: () => _onShare(context, title),
            tooltip: 'Share',
          ),
        ],
      ),
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Top banner ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF15803D), Color(0xFF16A34A)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (isJumuah)
                      const BadgeChip(
                        label: "Jumu'ah",
                        variant: BadgeVariant.green,
                        size: BadgeSize.small,
                        filled: true,
                      ),
                    if (deliveredAt != null)
                      BadgeChip(
                        label: _formatDate(deliveredAt),
                        variant: BadgeVariant.gray,
                        size: BadgeSize.small,
                        icon: Icons.calendar_today_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                if (scholarName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        child: Center(
                          child: Text(
                            scholarName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        scholarName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Location / date info ───────────────────────────────────────
          if (mosqueName.isNotEmpty || city.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.primaryGreen,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (mosqueName.isNotEmpty)
                            Text(
                              mosqueName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                              ),
                            ),
                          if (city.isNotEmpty)
                            Text(
                              city,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // ── Watch button if video available ────────────────────────────
          if (videoUuid != null && videoUuid.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                onPressed: () => context.push('/videos/$videoUuid'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: Text(
                  'Watch Khutbah',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // ── Description ────────────────────────────────────────────────
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SectionCard(
                title: 'About this Khutbah',
                isDark: isDark,
                child: Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.7,
                    color: isDark
                        ? const Color(0xFFD1D5DB)
                        : const Color(0xFF374151),
                  ),
                ),
              ),
            ),

          // ── Key Points ─────────────────────────────────────────────────
          if (keyPoints.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SectionCard(
                title: 'Key Points',
                isDark: isDark,
                child: Column(
                  children: keyPoints.map((point) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 7, right: 10),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              point.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                height: 1.6,
                                color: isDark
                                    ? const Color(0xFFD1D5DB)
                                    : const Color(0xFF374151),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],

          // ── Scholar info card ──────────────────────────────────────────
          if (scholar != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ScholarCard(
                scholar: scholar,
                scholarSlug: scholarSlug,
                isDark: isDark,
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section card
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.isDark,
    required this.child,
  });

  final String title;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scholar card
// ---------------------------------------------------------------------------

class _ScholarCard extends StatelessWidget {
  const _ScholarCard({
    required this.scholar,
    required this.scholarSlug,
    required this.isDark,
  });

  final Map<String, dynamic> scholar;
  final String? scholarSlug;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final name = scholar['name'] as String? ?? '';
    final bio = scholar['bio'] as String? ?? '';
    final title = scholar['title'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withValues(alpha: isDark ? 0.15 : 0.08),
            AppTheme.primaryGreenDark.withValues(alpha: isDark ? 0.1 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About the Scholar',
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              bio,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.6,
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
          if (scholarSlug != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => context.push('/scholars/$scholarSlug'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: AppTheme.primaryGreen,
              ),
              icon: const Icon(Icons.person_rounded, size: 16),
              label: Text(
                'View Scholar Profile',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
