import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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

final hajjGuideDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, slug) async {
  final service = ref.watch(_contentServiceProvider);
  return service.fetchHajjGuideDetail(slug);
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class HajjGuideDetailScreen extends ConsumerWidget {
  const HajjGuideDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideAsync = ref.watch(hajjGuideDetailProvider(slug));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return guideAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(backgroundColor: const Color(0xFF14532D)),
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
        appBar: AppBar(title: const Text('Guide')),
        body: EmptyState(
          icon: Icons.home_work_rounded,
          title: 'Could not load guide',
          subtitle: 'Please check your connection and try again.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(hajjGuideDetailProvider(slug)),
        ),
      ),
      data: (guide) => _GuideDetailBody(
        guide: guide,
        isDark: isDark,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _GuideDetailBody extends StatelessWidget {
  const _GuideDetailBody({
    required this.guide,
    required this.isDark,
  });

  final Map<String, dynamic> guide;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final title = guide['title'] as String? ?? '';
    final guideType = guide['guide_type'] as String? ?? '';
    final sections = guide['sections'] as List<dynamic>? ?? [];
    final isHajj = guideType.toLowerCase() == 'hajj';
    final accentColor =
        isHajj ? AppTheme.primaryGreen : const Color(0xFFF59E0B);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF14532D),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isHajj
                        ? const [Color(0xFF14532D), Color(0xFF16A34A)]
                        : const [Color(0xFF78350F), Color(0xFFF59E0B)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BadgeChip(
                          label: isHajj ? 'Hajj Guide' : 'Umrah Guide',
                          variant: isHajj
                              ? BadgeVariant.green
                              : BadgeVariant.amber,
                          size: BadgeSize.small,
                          filled: true,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        BadgeChip(
                          label: '${sections.length} sections',
                          variant: BadgeVariant.gray,
                          size: BadgeSize.small,
                          icon: Icons.list_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Sections list ────────────────────────────────────────────────
          if (sections.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.list_alt_rounded,
                title: 'No sections yet',
                subtitle: 'Content is being added to this guide.',
                compact: true,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final section =
                      sections[index] as Map<String, dynamic>;
                  return _SectionExpansionTile(
                    section: section,
                    index: index,
                    isDark: isDark,
                    accentColor: accentColor,
                  );
                },
                childCount: sections.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section expansion tile
// ---------------------------------------------------------------------------

class _SectionExpansionTile extends StatefulWidget {
  const _SectionExpansionTile({
    required this.section,
    required this.index,
    required this.isDark,
    required this.accentColor,
  });

  final Map<String, dynamic> section;
  final int index;
  final bool isDark;
  final Color accentColor;

  @override
  State<_SectionExpansionTile> createState() => _SectionExpansionTileState();
}

class _SectionExpansionTileState extends State<_SectionExpansionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final sectionTitle =
        widget.section['title'] as String? ?? 'Section ${widget.index + 1}';
    final content = widget.section['content'] as String? ?? '';
    final sortOrder =
        widget.section['sort_order'] as int? ?? (widget.index + 1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: widget.isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
          ),
          child: ExpansionTile(
            initiallyExpanded: false,
            onExpansionChanged: (v) => setState(() => _expanded = v),
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            childrenPadding: EdgeInsets.zero,
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _expanded
                    ? widget.accentColor
                    : widget.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$sortOrder',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _expanded
                        ? Colors.white
                        : widget.accentColor,
                  ),
                ),
              ),
            ),
            title: Text(
              sectionTitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: widget.isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            trailing: AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: widget.isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
              ),
            ),
            children: [
              if (content.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(
                        color: widget.isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFF3F4F6),
                      ),
                      const SizedBox(height: 4),
                      _SectionContent(
                          content: content, isDark: widget.isDark),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section content renderer (step-by-step aware)
// ---------------------------------------------------------------------------

class _SectionContent extends StatelessWidget {
  const _SectionContent({required this.content, required this.isDark});

  final String content;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    int stepCounter = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        // Numbered step: lines starting with "1." "2." etc
        final stepMatch = RegExp(r'^(\d+)\.\s+(.+)').firstMatch(line);
        if (stepMatch != null) {
          stepCounter++;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 2, right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryGreen,
                  ),
                  child: Center(
                    child: Text(
                      '$stepCounter',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    stepMatch.group(2) ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
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
        }

        // Heading
        if (line.startsWith('## ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Text(
              line.substring(3),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryGreen,
              ),
            ),
          );
        }

        // Bullet
        if (line.startsWith('- ') || line.startsWith('• ')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7, right: 8),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentGold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    line.startsWith('• ')
                        ? line.substring(2)
                        : line.substring(2),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
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
        }

        if (line.trim().isEmpty) return const SizedBox(height: 6);

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            line,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.7,
              color:
                  isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
            ),
          ),
        );
      }).toList(),
    );
  }
}
