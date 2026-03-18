import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/core/services/content_service.dart';
import 'package:ehsan_pathways/shared/widgets/badge_chip.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _contentServiceProvider = Provider<ContentService>((ref) => ContentService());

class _ArabicFilter {
  final int page;
  final String? level;
  const _ArabicFilter({this.page = 1, this.level});
}

final arabicFilterProvider = StateProvider<_ArabicFilter>(
  (ref) => const _ArabicFilter(),
);

final arabicCoursesProvider =
    FutureProvider.family<Map<String, dynamic>, _ArabicFilter>(
        (ref, filter) async {
  final service = ref.watch(_contentServiceProvider);
  return service.fetchArabicCourses(page: filter.page, level: filter.level);
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ArabicScreen extends ConsumerStatefulWidget {
  const ArabicScreen({super.key});

  @override
  ConsumerState<ArabicScreen> createState() => _ArabicScreenState();
}

class _ArabicScreenState extends ConsumerState<ArabicScreen> {
  static const _levels = ['All', 'Beginner', 'Elementary', 'Intermediate'];
  int _selectedIndex = 0;

  String? get _activeLevel =>
      _selectedIndex == 0 ? null : _levels[_selectedIndex];

  Future<void> _onRefresh() async {
    final current = ref.read(arabicFilterProvider);
    ref.invalidate(arabicCoursesProvider(current));
    ref.read(arabicFilterProvider.notifier).state =
        _ArabicFilter(page: 1, level: _activeLevel);
  }

  void _selectLevel(int index) {
    setState(() => _selectedIndex = index);
    ref.read(arabicFilterProvider.notifier).state =
        _ArabicFilter(page: 1, level: index == 0 ? null : _levels[index]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filter = ref.watch(arabicFilterProvider);
    final coursesAsync = ref.watch(arabicCoursesProvider(filter));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Gradient header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppTheme.primaryGreenDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF15803D),
                      Color(0xFF16A34A),
                      Color(0xFF22C55E),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      // Arabic calligraphy icon
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        child: const Center(
                          child: Text(
                            'ع',
                            style: TextStyle(
                              fontSize: 38,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Arabic Learning',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Master the language of the Quran',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Level filter chips ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_levels.length, (i) {
                    final selected = _selectedIndex == i;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _selectLevel(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.primaryGreen
                                : (isDark
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.primaryGreen
                                  : (isDark
                                      ? const Color(0xFF3A3A3A)
                                      : const Color(0xFFE5E7EB)),
                            ),
                          ),
                          child: Text(
                            _levels[i],
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : (isDark
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280)),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),

          // ── Course list ──────────────────────────────────────────────────
          coursesAsync.when(
            loading: () => SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => const _CourseShimmer(),
                childCount: 5,
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: EmptyState(
                icon: Icons.language_rounded,
                title: 'Could not load courses',
                subtitle: 'Please check your connection and try again.',
                actionLabel: 'Retry',
                onAction: _onRefresh,
              ),
            ),
            data: (data) {
              final courses = data['data'] as List<dynamic>? ?? [];
              if (courses.isEmpty) {
                return SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.menu_book_rounded,
                    title: 'No courses found',
                    subtitle: _activeLevel != null
                        ? 'No $_activeLevel courses yet. Try another level.'
                        : 'Arabic courses are being prepared. Check back soon!',
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final course =
                        courses[index] as Map<String, dynamic>;
                    return _CourseCard(
                      course: course,
                      isDark: isDark,
                      onTap: () => context.push(
                        '/arabic/${course['slug']}',
                      ),
                    );
                  },
                  childCount: courses.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Course card
// ---------------------------------------------------------------------------

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.isDark,
    required this.onTap,
  });

  final Map<String, dynamic> course;
  final bool isDark;
  final VoidCallback onTap;

  Color get _levelColor {
    switch ((course['level'] as String? ?? '').toLowerCase()) {
      case 'beginner':
        return const Color(0xFF16A34A);
      case 'elementary':
        return const Color(0xFF2563EB);
      case 'intermediate':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  BadgeVariant get _levelVariant {
    switch ((course['level'] as String? ?? '').toLowerCase()) {
      case 'beginner':
        return BadgeVariant.green;
      case 'elementary':
        return BadgeVariant.blue;
      case 'intermediate':
        return BadgeVariant.amber;
      default:
        return BadgeVariant.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = course['title'] as String? ?? '';
    final description = course['description'] as String? ?? '';
    final level = course['level'] as String? ?? '';
    final lessonCount = course['lesson_count'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon decoration
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _levelColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'ع',
                          style: TextStyle(
                            fontSize: 22,
                            color: _levelColor,
                            fontWeight: FontWeight.bold,
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
                          Row(
                            children: [
                              if (level.isNotEmpty)
                                BadgeChip(
                                  label: level,
                                  variant: _levelVariant,
                                  size: BadgeSize.small,
                                ),
                              const SizedBox(width: 6),
                              BadgeChip(
                                label: '$lessonCount lessons',
                                variant: BadgeVariant.gray,
                                size: BadgeSize.small,
                                icon: Icons.play_lesson_rounded,
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
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer placeholder
// ---------------------------------------------------------------------------

class _CourseShimmer extends StatelessWidget {
  const _CourseShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ShimmerWrap(
        child: Container(
          height: 110,
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
                    ShimmerBox(width: 120, height: 12),
                    SizedBox(height: 8),
                    ShimmerBox(width: double.infinity, height: 11),
                    SizedBox(height: 4),
                    ShimmerBox(width: 200, height: 11),
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
