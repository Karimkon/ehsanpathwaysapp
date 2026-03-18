import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/core/services/content_service.dart';
import 'package:ehsan_pathways/shared/widgets/badge_chip.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _contentServiceProvider =
    Provider<ContentService>((ref) => ContentService());

final arabicCourseDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, slug) async {
  final service = ref.watch(_contentServiceProvider);
  return service.fetchArabicCourseDetail(slug);
});

final arabicLessonProvider =
    FutureProvider.family<Map<String, dynamic>, ({String courseSlug, int lessonId})>(
        (ref, args) async {
  final service = ref.watch(_contentServiceProvider);
  return service.fetchArabicLesson(args.courseSlug, args.lessonId);
});

// Tracks completed lesson IDs (in-memory, per session)
final _completedLessonsProvider =
    StateProvider.family<Set<int>, String>((ref, courseSlug) => {});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ArabicCourseDetailScreen extends ConsumerWidget {
  const ArabicCourseDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(arabicCourseDetailProvider(slug));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
      body: courseAsync.when(
        loading: () => const _CourseDetailShimmer(),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Course')),
          body: EmptyState(
            icon: Icons.language_rounded,
            title: 'Could not load course',
            subtitle: 'Please check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(arabicCourseDetailProvider(slug)),
          ),
        ),
        data: (course) => _CourseDetailBody(
          course: course,
          courseSlug: slug,
          isDark: isDark,
          ref: ref,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _CourseDetailBody extends StatelessWidget {
  const _CourseDetailBody({
    required this.course,
    required this.courseSlug,
    required this.isDark,
    required this.ref,
  });

  final Map<String, dynamic> course;
  final String courseSlug;
  final bool isDark;
  final WidgetRef ref;

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
    final lessons = course['lessons'] as List<dynamic>? ?? [];
    final completedLessons = ref.watch(_completedLessonsProvider(courseSlug));

    return CustomScrollView(
      slivers: [
        // ── Header ────────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: AppTheme.primaryGreenDark,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF15803D), Color(0xFF16A34A)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (level.isNotEmpty)
                        BadgeChip(
                          label: level,
                          variant: _levelVariant,
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
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Progress indicator ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: lessons.isEmpty
                          ? 0
                          : completedLessons.length / lessons.length,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFE5E7EB),
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${completedLessons.length}/${lessons.length} done',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Section header ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Lessons',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ),
        ),

        // ── Lessons list ──────────────────────────────────────────────────
        if (lessons.isEmpty)
          SliverFillRemaining(
            child: EmptyState(
              icon: Icons.menu_book_rounded,
              title: 'No lessons yet',
              subtitle: 'Lessons are being added to this course.',
              compact: true,
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final lesson = lessons[index] as Map<String, dynamic>;
                final lessonId = lesson['id'] as int? ?? index;
                final lessonTitle =
                    lesson['title'] as String? ?? 'Lesson ${index + 1}';
                final sortOrder =
                    lesson['sort_order'] as int? ?? (index + 1);
                final isComplete = completedLessons.contains(lessonId);

                return _LessonTile(
                  number: sortOrder,
                  title: lessonTitle,
                  isComplete: isComplete,
                  isDark: isDark,
                  onTap: () => _showLessonSheet(
                    context,
                    courseSlug: courseSlug,
                    lessonId: lessonId,
                    lessonTitle: lessonTitle,
                    lessonNumber: sortOrder,
                    isDark: isDark,
                    ref: ref,
                  ),
                  onMarkComplete: () {
                    final current =
                        ref.read(_completedLessonsProvider(courseSlug));
                    if (isComplete) {
                      final updated = Set<int>.from(current)..remove(lessonId);
                      ref
                          .read(_completedLessonsProvider(courseSlug).notifier)
                          .state = updated;
                    } else {
                      ref
                          .read(_completedLessonsProvider(courseSlug).notifier)
                          .state = <int>{...current, lessonId};
                    }
                  },
                );
              },
              childCount: lessons.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  void _showLessonSheet(
    BuildContext context, {
    required String courseSlug,
    required int lessonId,
    required String lessonTitle,
    required int lessonNumber,
    required bool isDark,
    required WidgetRef ref,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LessonBottomSheet(
        courseSlug: courseSlug,
        lessonId: lessonId,
        lessonTitle: lessonTitle,
        lessonNumber: lessonNumber,
        isDark: isDark,
        ref: ref,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lesson tile
// ---------------------------------------------------------------------------

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.number,
    required this.title,
    required this.isComplete,
    required this.isDark,
    required this.onTap,
    required this.onMarkComplete,
  });

  final int number;
  final String title;
  final bool isComplete;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onMarkComplete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isComplete
              ? Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                  width: 1.5,
                )
              : null,
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
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          onTap: onTap,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isComplete
                  ? AppTheme.primaryGreen
                  : (isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFF3F4F6)),
            ),
            child: Center(
              child: isComplete
                  ? const Icon(Icons.check_rounded,
                      size: 18, color: Colors.white)
                  : Text(
                      '$number',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF374151),
                      ),
                    ),
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF111827),
              decoration:
                  isComplete ? TextDecoration.lineThrough : TextDecoration.none,
              decorationColor: AppTheme.primaryGreen,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onMarkComplete,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isComplete
                        ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                        : (isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFF3F4F6)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isComplete ? 'Done' : 'Mark',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isComplete
                          ? AppTheme.primaryGreen
                          : (isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lesson content bottom sheet
// ---------------------------------------------------------------------------

class _LessonBottomSheet extends ConsumerWidget {
  const _LessonBottomSheet({
    required this.courseSlug,
    required this.lessonId,
    required this.lessonTitle,
    required this.lessonNumber,
    required this.isDark,
    required this.ref,
  });

  final String courseSlug;
  final int lessonId;
  final String lessonTitle;
  final int lessonNumber;
  final bool isDark;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final lessonAsync = widgetRef.watch(
      arabicLessonProvider((courseSlug: courseSlug, lessonId: lessonId)),
    );
    final sheetColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3A3A3A)
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          AppTheme.primaryGreen.withValues(alpha: 0.12),
                    ),
                    child: Center(
                      child: Text(
                        '$lessonNumber',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lessonTitle,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Divider(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF3F4F6)),

            // Content
            Expanded(
              child: lessonAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                    strokeWidth: 2.5,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Could not load lesson content.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
                data: (lesson) {
                  final content =
                      lesson['content'] as String? ?? '';
                  final exercises =
                      lesson['exercises'] as List<dynamic>? ?? [];

                  return ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      if (content.isNotEmpty)
                        _LessonContentText(
                            content: content, isDark: isDark),
                      if (exercises.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Exercises',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...exercises.map((e) {
                          final ex = e as Map<String, dynamic>;
                          return _ExerciseCard(
                              exercise: ex, isDark: isDark);
                        }),
                      ],

                      // Mark complete button
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () {
                          final current = ref.read(
                            _completedLessonsProvider(courseSlug),
                          );
                          ref
                              .read(_completedLessonsProvider(courseSlug)
                                  .notifier)
                              .state = {...current, lessonId};
                          Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: Text(
                          'Mark as Complete',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lesson content text (simple markdown-like rendering)
// ---------------------------------------------------------------------------

class _LessonContentText extends StatelessWidget {
  const _LessonContentText({required this.content, required this.isDark});

  final String content;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.startsWith('# ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              line.substring(2),
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          );
        }
        if (line.startsWith('## ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Text(
              line.substring(3),
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryGreen,
              ),
            ),
          );
        }
        if (line.startsWith('- ') || line.startsWith('* ')) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 8),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    line.substring(2),
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
        }
        if (line.trim().isEmpty) return const SizedBox(height: 8);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            line,
            style: GoogleFonts.poppins(
              fontSize: 14,
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

// ---------------------------------------------------------------------------
// Exercise card
// ---------------------------------------------------------------------------

class _ExerciseCard extends StatefulWidget {
  const _ExerciseCard({required this.exercise, required this.isDark});

  final Map<String, dynamic> exercise;
  final bool isDark;

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    final question = widget.exercise['question_data'] as String? ?? '';
    final answer = widget.exercise['answer_data'] as String? ?? '';
    final explanation = widget.exercise['explanation'] as String? ?? '';
    final type = widget.exercise['exercise_type'] as String? ?? 'exercise';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark
              ? const Color(0xFF3A3A3A)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BadgeChip(
                label: type,
                variant: BadgeVariant.blue,
                size: BadgeSize.small,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showAnswer = !_showAnswer),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _showAnswer
                    ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                    : (widget.isDark
                        ? const Color(0xFF3A3A3A)
                        : const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showAnswer ? Icons.visibility_off : Icons.visibility,
                    size: 14,
                    color: _showAnswer
                        ? AppTheme.primaryGreen
                        : (widget.isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _showAnswer ? 'Hide Answer' : 'Show Answer',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _showAnswer
                          ? AppTheme.primaryGreen
                          : (widget.isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showAnswer && answer.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                answer,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (_showAnswer && explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              explanation,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: widget.isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer for course detail
// ---------------------------------------------------------------------------

class _CourseDetailShimmer extends StatelessWidget {
  const _CourseDetailShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: AppTheme.primaryGreenDark,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF15803D), Color(0xFF16A34A)],
                ),
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ShimmerWrap(
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            childCount: 6,
          ),
        ),
      ],
    );
  }
}
