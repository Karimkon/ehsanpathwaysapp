import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ehsan_pathways/features/pathways/pathway_provider.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';

const Color _green = Color(0xFF16A34A);
const Color _gold = Color(0xFFF59E0B);

class PathwayDetailScreen extends ConsumerWidget {
  const PathwayDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(pathwayDetailProvider(slug));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Failed to load pathway',
          subtitle: error.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(pathwayDetailProvider(slug)),
        ),
        data: (detail) => _PathwayDetailBody(detail: detail, isDark: isDark),
      ),
    );
  }
}

class _PathwayDetailBody extends StatelessWidget {
  const _PathwayDetailBody({required this.detail, required this.isDark});

  final PathwayDetail detail;
  final bool isDark;

  Color get _levelColor {
    switch (detail.pathway.difficultyLevel?.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF10B981);
      case 'intermediate':
        return const Color(0xFF3B82F6);
      case 'advanced':
        return const Color(0xFF8B5CF6);
      default:
        return _green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pathway = detail.pathway;

    return CustomScrollView(
      slivers: [
        // -- Hero header --
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          leading: IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.35),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _levelColor.withValues(alpha: 0.9),
                    _levelColor.withValues(alpha: 0.6),
                    const Color(0xFF052E16),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Level badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          pathway.levelLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        pathway.title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Stats row
                      Row(
                        children: [
                          _HeaderStat(
                            icon: Icons.layers_rounded,
                            label: '${pathway.totalItems} items',
                          ),
                          const SizedBox(width: 16),
                          if (pathway.estimatedHours != null)
                            _HeaderStat(
                              icon: Icons.schedule_rounded,
                              label: '~${pathway.estimatedHours}h',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // -- Progress bar --
        if (detail.isEnrolled)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up_rounded,
                            size: 18, color: _green),
                        const SizedBox(width: 8),
                        Text(
                          'Your Progress',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${detail.progressPercentage.toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: detail.progressPercentage / 100,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE5E7EB),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_green),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${detail.completedItems} of ${pathway.totalItems} completed',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // -- Description --
        if (pathway.description != null && pathway.description!.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color:
                          isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pathway.description!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFFD1D5DB)
                          : const Color(0xFF4B5563),
                      height: 1.65,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // -- Stages --
        if (detail.stages.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Stages',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList.builder(
              itemCount: detail.stages.length,
              itemBuilder: (context, index) {
                final stage = detail.stages[index];
                final isCompleted =
                    index < detail.completedItems;
                final isCurrent = index == detail.completedItems;

                return _StageItem(
                  stage: stage,
                  index: index,
                  isLast: index == detail.stages.length - 1,
                  isCompleted: isCompleted,
                  isCurrent: isCurrent,
                  isDark: isDark,
                  levelColor: _levelColor,
                );
              },
            ),
          ),
        ],

        if (detail.stages.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: EmptyState(
                icon: Icons.layers_outlined,
                title: 'No stages defined',
                subtitle: 'This pathway is still being set up.',
                compact: true,
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header stat chip
// ---------------------------------------------------------------------------

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
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stage timeline item
// ---------------------------------------------------------------------------

class _StageItem extends StatelessWidget {
  const _StageItem({
    required this.stage,
    required this.index,
    required this.isLast,
    required this.isCompleted,
    required this.isCurrent,
    required this.isDark,
    required this.levelColor,
  });

  final PathwayStage stage;
  final int index;
  final bool isLast;
  final bool isCompleted;
  final bool isCurrent;
  final bool isDark;
  final Color levelColor;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? _green
                        : isCurrent
                            ? levelColor
                            : isDark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFE5E7EB),
                    border: isCurrent
                        ? Border.all(color: levelColor, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check_rounded,
                            size: 16, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isCurrent
                                  ? Colors.white
                                  : isDark
                                      ? Colors.white38
                                      : const Color(0xFF9CA3AF),
                            ),
                          ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isCompleted
                          ? _green.withValues(alpha: 0.3)
                          : isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFE5E7EB),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCurrent
                    ? levelColor.withValues(alpha: isDark ? 0.1 : 0.05)
                    : isDark
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: isCurrent
                    ? Border.all(
                        color: levelColor.withValues(alpha: 0.3))
                    : null,
                boxShadow: isCurrent
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.15 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stage.title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (stage.contentType.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: levelColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            stage.contentType,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: levelColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (stage.description != null &&
                      stage.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      stage.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
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
          ),
        ],
      ),
    );
  }
}
