import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ehsan_pathways/core/services/api_service.dart';
import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/core/services/content_service.dart';
import 'package:ehsan_pathways/shared/widgets/badge_chip.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';
import 'package:ehsan_pathways/core/json_read.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final _contentServiceProvider =
    Provider<ContentService>((ref) => ContentService(dio: ref.watch(apiProvider)));

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
        appBar: AppBar(backgroundColor: AppColors.emerald900),
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
                    color: isDark ? AppColors.slateCard : Colors.white,
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
    final title = jStr(guide['title']) ?? '';
    final guideType = jStr(guide['guide_type']) ?? '';
    final sections = guide['sections'] as List<dynamic>? ?? [];
    final intro = jStr(guide['description']) ?? '';
    final checklists = (guide['checklists'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final isHajj = guideType.toLowerCase() == 'hajj';
    final accentColor =
        isHajj ? AppTheme.primaryGreen : AppColors.gold;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.slate : AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.emerald900,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isHajj
                        ? const [AppColors.emerald900, AppColors.emerald700]
                        : const [AppColors.goldDarkest, AppColors.gold],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                          style: GoogleFonts.lora(
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
          ),

          if (intro.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                child: Text(
                  intro,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    height: 1.65,
                    color: isDark ? AppColors.onDarkMuted : AppColors.ink2,
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

          if (checklists.isNotEmpty)
            SliverToBoxAdapter(
              child: _Checklists(lists: checklists, isDark: isDark),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

/// Preparation checklists, from the guide. Ticks are kept for this session.
class _Checklists extends StatefulWidget {
  const _Checklists({required this.lists, required this.isDark});

  final List<Map<String, dynamic>> lists;
  final bool isDark;

  @override
  State<_Checklists> createState() => _ChecklistsState();
}

class _ChecklistsState extends State<_Checklists> {
  final Set<String> _ticked = {};

  @override
  Widget build(BuildContext context) {
    final d = widget.isDark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Checklists',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w800, color: d ? Colors.white : AppColors.ink)),
          ),
          ...widget.lists.map((list) {
            final title = jStr(list['title']) ?? jStr(list['type']) ?? '';
            final items = (list['items'] as List<dynamic>? ?? const []).map((e) => jStr(e) ?? '').where((e) => e.isNotEmpty).toList();
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: d ? AppColors.slateCard : Colors.white,
              child: ExpansionTile(
                title: Text(title,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: d ? Colors.white : AppColors.ink)),
                subtitle: Text('${items.where((i) => _ticked.contains('$title|$i')).length} of ${items.length} done',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: d ? AppColors.onDarkMuted : AppColors.muted)),
                children: items
                    .map((item) => CheckboxListTile(
                          dense: true,
                          value: _ticked.contains('$title|$item'),
                          onChanged: (v) => setState(() => v == true ? _ticked.add('$title|$item') : _ticked.remove('$title|$item')),
                          title: Text(item,
                              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: d ? AppColors.onDarkMuted : AppColors.ink2)),
                          controlAffinity: ListTileControlAffinity.leading,
                        ))
                    .toList(),
              ),
            );
          }),
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
        jStr(widget.section['title']) ?? 'Section ${widget.index + 1}';
    final content = jStr(widget.section['content']) ?? '';
    final sortOrder =
        jInt(widget.section['sort_order']) ?? (widget.index + 1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.slateCard : Colors.white,
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
                  style: GoogleFonts.plusJakartaSans(
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
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: widget.isDark ? Colors.white : AppColors.ink,
              ),
            ),
            trailing: AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: widget.isDark
                    ? AppColors.onDarkMuted
                    : AppColors.muted,
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
                            ? AppColors.slateRaised
                            : AppColors.creamDeep,
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
    // Guides are written as HTML on the website; render them as such.
    if (content.contains('<')) {
      final body = isDark ? AppColors.onDarkMuted : AppColors.ink2;
      return Html(
        data: content,
        style: {
          'body': Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            fontSize: FontSize(14),
            lineHeight: LineHeight(1.65),
            color: body,
            fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
          ),
          'h3': Style(
            fontSize: FontSize(15),
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryGreen,
            margin: Margins.only(top: 12, bottom: 4),
          ),
          'p': Style(margin: Margins.only(bottom: 8)),
          'li': Style(margin: Margins.only(bottom: 4)),
          'p[dir=rtl]': Style(
            fontSize: FontSize(22),
            lineHeight: LineHeight(2),
            textAlign: TextAlign.right,
            direction: TextDirection.rtl,
            color: isDark ? Colors.white : AppColors.ink,
          ),
        },
      );
    }

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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.6,
                      color: isDark
                          ? AppColors.onDarkMuted
                          : AppColors.ink2,
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
              style: GoogleFonts.plusJakartaSans(
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.6,
                      color: isDark
                          ? AppColors.onDarkMuted
                          : AppColors.ink2,
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
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.7,
              color:
                  isDark ? AppColors.onDarkMuted : AppColors.ink2,
            ),
          ),
        );
      }).toList(),
    );
  }
}
