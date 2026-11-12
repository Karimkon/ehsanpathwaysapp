import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/core/providers/auth_provider.dart';
import 'package:ehsan_pathways/core/services/guided_share.dart';
import 'package:ehsan_pathways/features/pathways/pathway_provider.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';

const Color _green = AppColors.emerald700;

/// A pathway: its stages, each stage's lessons, and the user's progress.
///
/// Lessons open the real video, article or podcast. A signed-in user starts
/// the pathway and marks lessons done; progress is stored on the server, so
/// it is the same on the website and survives a reinstall.
class PathwayDetailScreen extends ConsumerWidget {
  const PathwayDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(pathwayDetailProvider(slug));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.slate : AppColors.cream,
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => SafeArea(
          child: EmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Could not open this pathway',
            subtitle: 'Please check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(pathwayDetailProvider(slug)),
          ),
        ),
        data: (detail) => _Body(slug: slug, detail: detail, isDark: isDark),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.slug, required this.detail, required this.isDark});

  final String slug;
  final PathwayDetail detail;
  final bool isDark;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;
  int? _completing;

  Color get _levelColor => switch (widget.detail.pathway.difficultyLevel?.toLowerCase()) {
        'intermediate' => AppColors.sapphire,
        'advanced' => AppColors.amethyst,
        _ => AppColors.emerald500,
      };

  bool get _signedIn => ref.read(authProvider).status == AuthStatus.authenticated;

  Future<void> _start() async {
    if (!_signedIn) {
      context.push('/login');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(pathwayActionsProvider).enroll(widget.slug);
    } catch (_) {
      _toast('Could not start the pathway. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _complete(PathwayLesson lesson) async {
    setState(() => _completing = lesson.id);
    try {
      await ref.read(pathwayActionsProvider).complete(widget.slug, lesson.id);
    } catch (_) {
      _toast('Could not save. Please try again.');
    } finally {
      if (mounted) setState(() => _completing = null);
    }
  }

  void _open(PathwayLesson lesson) {
    final route = lesson.route;
    if (route != null) {
      context.push(route);
    } else {
      _toast('Open this reading on ehsanpathways.com.');
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final pathway = detail.pathway;
    final d = widget.isDark;
    final ink = d ? Colors.white : AppColors.ink;
    final muted = d ? AppColors.onDarkMuted : AppColors.muted;
    final lessonCount = detail.stages.fold<int>(0, (n, s) => n + s.lessons.length);
    final hours = pathway.estimatedHours;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 230,
          pinned: true,
          backgroundColor: d ? AppColors.slate : Colors.white,
          leading: IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.35)),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              tooltip: 'Share this pathway',
              icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
              onPressed: () => GuidedShare.share(
                context,
                type: 'pathway',
                key: widget.slug,
                fallbackPath: '/pathways/${widget.slug}',
                subject: pathway.title,
                text: (url) => 'Learn "${pathway.title}" with me on Ehsan Pathways\n$url',
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_levelColor.withValues(alpha: 0.9), _levelColor.withValues(alpha: 0.6), AppColors.emerald950],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(pathway.levelLabel,
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          pathway.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lora(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          runSpacing: 4,
                          children: [
                            _HeaderStat(icon: Icons.layers_rounded, label: '${detail.stages.length} ${detail.stages.length == 1 ? 'stage' : 'stages'}'),
                            _HeaderStat(icon: Icons.play_lesson_rounded, label: '$lessonCount ${lessonCount == 1 ? 'lesson' : 'lessons'}'),
                            if (hours != null && hours > 0)
                              _HeaderStat(icon: Icons.schedule_rounded, label: '~${hours == hours.roundToDouble() ? hours.toInt() : hours}h'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Start, or progress.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: detail.isEnrolled
                ? _ProgressCard(detail: detail, total: lessonCount, isDark: d)
                : SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy || lessonCount == 0 ? null : _start,
                      icon: _busy
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.play_arrow_rounded),
                      label: Text(lessonCount == 0 ? 'Lessons coming soon' : 'Start this pathway'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
          ),
        ),

        if (pathway.description != null && pathway.description!.trim().isNotEmpty && pathway.description != pathway.title)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
                  const SizedBox(height: 8),
                  Text(pathway.description!, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: muted, height: 1.65)),
                ],
              ),
            ),
          ),

        if (detail.stages.isEmpty || lessonCount == 0)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: EmptyState(
                icon: Icons.layers_outlined,
                title: 'Lessons are being prepared',
                subtitle: 'This pathway has no lessons yet. Check back soon, in sha Allah.',
                compact: true,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            sliver: SliverList.builder(
              itemCount: detail.stages.length,
              itemBuilder: (context, i) {
                final stage = detail.stages[i];
                return _StageCard(
                  stage: stage,
                  number: i + 1,
                  isDark: d,
                  accent: _levelColor,
                  enrolled: detail.isEnrolled,
                  completing: _completing,
                  onOpen: _open,
                  onComplete: _complete,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.detail, required this.total, required this.isDark});

  final PathwayDetail detail;
  final int total;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final pct = detail.progressPercentage.clamp(0, 100).toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, size: 18, color: _green),
              const SizedBox(width: 8),
              Text(pct >= 100 ? 'Completed, alhamdulillah' : 'Your progress',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.ink)),
              const Spacer(),
              Text('${pct.toStringAsFixed(0)}%',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? AppColors.emerald400 : _green)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.sand,
              valueColor: const AlwaysStoppedAnimation<Color>(_green),
            ),
          ),
          const SizedBox(height: 6),
          Text('${detail.completedItems} of $total lessons done',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? AppColors.onDarkSubtle : AppColors.subtle)),
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stage,
    required this.number,
    required this.isDark,
    required this.accent,
    required this.enrolled,
    required this.completing,
    required this.onOpen,
    required this.onComplete,
  });

  final PathwayStage stage;
  final int number;
  final bool isDark;
  final Color accent;
  final bool enrolled;
  final int? completing;
  final void Function(PathwayLesson) onOpen;
  final void Function(PathwayLesson) onComplete;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? Colors.white : AppColors.ink;
    final muted = isDark ? AppColors.onDarkMuted : AppColors.muted;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slateCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stage.isComplete ? _green.withValues(alpha: 0.4) : (isDark ? AppColors.slateLine : AppColors.sand)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: stage.isComplete ? _green : accent.withValues(alpha: 0.15),
                  child: stage.isComplete
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                      : Text('$number', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: accent)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stage.title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: ink)),
                      if (stage.description != null && stage.description!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(stage.description!, style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4, color: muted)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (stage.lessons.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(54, 4, 14, 14),
              child: Text('Lessons for this stage are coming soon.', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: muted)),
            )
          else
            ...stage.lessons.map((lesson) => _LessonRow(
                  lesson: lesson,
                  isDark: isDark,
                  enrolled: enrolled,
                  saving: completing == lesson.id,
                  onOpen: () => onOpen(lesson),
                  onComplete: () => onComplete(lesson),
                )),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.lesson,
    required this.isDark,
    required this.enrolled,
    required this.saving,
    required this.onOpen,
    required this.onComplete,
  });

  final PathwayLesson lesson;
  final bool isDark;
  final bool enrolled;
  final bool saving;
  final VoidCallback onOpen;
  final VoidCallback onComplete;

  IconData get _icon => switch (lesson.type) {
        'video' => Icons.play_circle_outline_rounded,
        'article' => Icons.article_outlined,
        'podcast' => Icons.headphones_rounded,
        'khutbah' => Icons.mic_none_rounded,
        _ => Icons.menu_book_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? Colors.white : AppColors.ink;
    final muted = isDark ? AppColors.onDarkMuted : AppColors.muted;

    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(54, 8, 6, 8),
        child: Row(
          children: [
            Icon(_icon, size: 20, color: muted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesson.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: lesson.completed ? muted : ink,
                      )),
                  Text(
                    [lesson.typeLabel, if (lesson.minutes != null) '${lesson.minutes} min'].join(' · '),
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: muted),
                  ),
                ],
              ),
            ),
            if (enrolled)
              saving
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : IconButton(
                      tooltip: lesson.completed ? 'Done' : 'Mark as done',
                      onPressed: lesson.completed ? null : onComplete,
                      icon: Icon(
                        lesson.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: lesson.completed ? _green : muted,
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85))),
      ],
    );
  }
}
