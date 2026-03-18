import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

final hajjGuidesProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(_contentServiceProvider);
  return service.fetchHajjGuides();
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class HajjUmrahScreen extends ConsumerStatefulWidget {
  const HajjUmrahScreen({super.key});

  @override
  ConsumerState<HajjUmrahScreen> createState() => _HajjUmrahScreenState();
}

class _HajjUmrahScreenState extends ConsumerState<HajjUmrahScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0; // 0 = Hajj, 1 = Umrah

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _selectedTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(hajjGuidesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final guidesAsync = ref.watch(hajjGuidesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── Gradient header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF14532D),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF14532D),
                      Color(0xFF15803D),
                      Color(0xFF16A34A),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Kaaba SVG-like icon using overlapping shapes
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(Icons.home_work_rounded,
                                size: 36, color: Colors.white),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Hajj & Umrah',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete guides for your pilgrimage',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFF59E0B),
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
              labelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Hajj'),
                Tab(text: 'Umrah'),
              ],
            ),
          ),
        ],
        body: guidesAsync.when(
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (_, __) => const _GuideShimmer(),
          ),
          error: (e, _) => EmptyState(
            icon: Icons.home_work_rounded,
            title: 'Could not load guides',
            subtitle: 'Please check your connection and try again.',
            actionLabel: 'Retry',
            onAction: _onRefresh,
          ),
          data: (data) {
            final allGuides = (data['data'] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>();
            final filtered = allGuides.where((g) {
              final type = (g['guide_type'] as String? ?? '').toLowerCase();
              return _selectedTab == 0
                  ? type == 'hajj'
                  : type == 'umrah';
            }).toList();

            if (filtered.isEmpty) {
              return EmptyState(
                icon: Icons.home_work_rounded,
                title:
                    'No ${_selectedTab == 0 ? 'Hajj' : 'Umrah'} guides yet',
                subtitle: 'Guides are being prepared. Check back soon!',
              );
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppTheme.primaryGreen,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: filtered.length,
                itemBuilder: (context, index) => _GuideCard(
                  guide: filtered[index],
                  isDark: isDark,
                  onTap: () =>
                      context.push('/hajj-umrah/${filtered[index]['slug']}'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Guide card
// ---------------------------------------------------------------------------

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.guide,
    required this.isDark,
    required this.onTap,
  });

  final Map<String, dynamic> guide;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = guide['title'] as String? ?? '';
    final description = guide['description'] as String? ?? '';
    final guideType = guide['guide_type'] as String? ?? '';
    final sectionCount = guide['section_count'] as int? ?? 0;
    final year = guide['year'] as int?;

    final isHajj = guideType.toLowerCase() == 'hajj';
    final accentColor =
        isHajj ? AppTheme.primaryGreen : const Color(0xFFF59E0B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colour accent top bar
                Container(
                  height: 4,
                  color: accentColor,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isHajj
                                  ? Icons.home_work_rounded
                                  : Icons.mosque_rounded,
                              color: accentColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    BadgeChip(
                                      label: isHajj ? 'Hajj' : 'Umrah',
                                      variant: isHajj
                                          ? BadgeVariant.green
                                          : BadgeVariant.amber,
                                      size: BadgeSize.small,
                                    ),
                                    BadgeChip(
                                      label: '$sectionCount sections',
                                      variant: BadgeVariant.gray,
                                      size: BadgeSize.small,
                                      icon: Icons.list_rounded,
                                    ),
                                    if (year != null)
                                      BadgeChip(
                                        label: '$year',
                                        variant: BadgeVariant.blue,
                                        size: BadgeSize.small,
                                        icon: Icons.calendar_today_rounded,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: isDark
                                ? const Color(0xFF6B7280)
                                : const Color(0xFF9CA3AF),
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer
// ---------------------------------------------------------------------------

class _GuideShimmer extends StatelessWidget {
  const _GuideShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShimmerWrap(
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const ShimmerBox(width: 44, height: 44, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    ShimmerBox(width: double.infinity, height: 14),
                    SizedBox(height: 8),
                    ShimmerBox(width: 160, height: 12),
                    SizedBox(height: 8),
                    ShimmerBox(width: double.infinity, height: 11),
                    SizedBox(height: 4),
                    ShimmerBox(width: 220, height: 11),
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
