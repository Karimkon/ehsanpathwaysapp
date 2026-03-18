import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ehsan_pathways/core/providers/auth_provider.dart';
import 'package:ehsan_pathways/features/history/history_provider.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';

// ─── Colours ──────────────────────────────────────────────────────────────────
const _green = Color(0xFF16A34A);
const _greenDeep = Color(0xFF052E16);
const _greenMid = Color(0xFF14532D);
const _gold = Color(0xFFF59E0B);

// =============================================================================
// HistoryScreen
// =============================================================================

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authProvider);

    // Guard: show login prompt if not authenticated
    if (auth.status != AuthStatus.authenticated) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
        appBar: AppBar(
          title: Text('Watch History',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
          backgroundColor:
              isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: const LoginPrompt(feature: 'watch history'),
      );
    }

    final history = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
      body: CustomScrollView(
        slivers: [
          // ── Gradient header ──────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader(context, history, isDark)),

          if (history.isLoading)
            SliverToBoxAdapter(child: _buildShimmer())
          else if (history.error != null)
            SliverToBoxAdapter(child: _buildError(history.error!))
          else if (history.items.isEmpty)
            SliverFillRemaining(child: _buildEmpty(isDark))
          else ...[
            // ── Continue Watching ────────────────────────────────────
            if (history.continueWatching.isNotEmpty)
              SliverToBoxAdapter(
                child: _ContinueWatchingSection(
                  items: history.continueWatching,
                  isDark: isDark,
                ),
              ),

            // ── All History ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Text(
                  'All History',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = history.items[index];
                  return _HistoryListItem(
                    item: item,
                    isDark: isDark,
                    onDelete: () =>
                        ref.read(historyProvider.notifier).remove(item.id),
                  );
                },
                childCount: history.items.length,
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                  height: MediaQuery.paddingOf(context).bottom + 32),
            ),
          ],
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(
      BuildContext context, HistoryState history, bool isDark) {
    return Stack(
      children: [
        // Gradient background with Islamic geometric pattern
        Container(
          height: 160,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_greenDeep, _greenMid, _green],
            ),
          ),
          child: CustomPaint(
            painter: _GeometricPatternPainter(),
            child: const SizedBox.expand(),
          ),
        ),

        // Content
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + Clear All row
                Row(
                  children: [
                    _CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => context.pop(),
                    ),
                    const Spacer(),
                    if (history.items.isNotEmpty)
                      _ClearAllButton(
                        isClearing: history.isClearing,
                        onTap: () => _confirmClearAll(context),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_rounded,
                              size: 13, color: _gold),
                          const SizedBox(width: 5),
                          Text(
                            'Watch History',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (history.items.isNotEmpty)
                      Text(
                        '${history.items.length} videos',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white60,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  'Continue\nYour Journey',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Shimmer ────────────────────────────────────────────────────────────────

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ShimmerWrap(
        child: Column(
          children: List.generate(
            5,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  ShimmerBox(width: 120, height: 68, borderRadius: 12),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerBox(width: double.infinity, height: 14),
                        SizedBox(height: 8),
                        ShimmerBox(width: 140, height: 12),
                        SizedBox(height: 8),
                        ShimmerBox(width: 80, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Could not load history',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.read(historyProvider.notifier).load(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty ──────────────────────────────────────────────────────────────────

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _green.withValues(alpha: 0.08),
              ),
              child: const Icon(
                Icons.play_circle_outline_rounded,
                size: 50,
                color: _green,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No videos watched yet',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '"Seek knowledge from the cradle to the grave"\n— Prophet Muhammad ﷺ',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : Colors.grey.shade500,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => context.go('/videos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Browse Videos',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Clear All ──────────────────────────────────────────────────────────────

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Clear Watch History',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Text(
          'This will remove all videos from your watch history. This action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(historyProvider.notifier).clearAll();
            },
            child: Text('Clear All',
                style: GoogleFonts.inter(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Continue Watching – horizontal Netflix-style cards
// =============================================================================

class _ContinueWatchingSection extends StatelessWidget {
  const _ContinueWatchingSection(
      {required this.items, required this.isDark});

  final List<WatchHistoryItem> items;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Continue Watching',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 175,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) =>
                _ContinueCard(item: items[index], isDark: isDark),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(
            color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.item, required this.isDark});

  final WatchHistoryItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/videos/${item.videoUuid}'),
      child: SizedBox(
        width: 175,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Thumbnail
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: item.thumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: item.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                _ThumbPlaceholder(isDark: isDark),
                          )
                        : _ThumbPlaceholder(isDark: isDark),
                  ),
                  // Dark gradient overlay at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Progress bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: item.progressPercent,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_green),
                      minHeight: 3,
                    ),
                  ),
                  // Play icon overlay
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  // % badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(item.progressPercent * 100).round()}%',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Title
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF111827),
                height: 1.4,
              ),
            ),

            if (item.scholarName != null) ...[
              const SizedBox(height: 3),
              Text(
                item.scholarName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: _green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// History List Item – vertical list with dismiss
// =============================================================================

class _HistoryListItem extends ConsumerWidget {
  const _HistoryListItem({
    required this.item,
    required this.isDark,
    required this.onDelete,
  });

  final WatchHistoryItem item;
  final bool isDark;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red.shade700,
        child: const Icon(Icons.delete_rounded,
            color: Colors.white, size: 26),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: () => context.push('/videos/${item.videoUuid}'),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail ──────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 124,
                  height: 70,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      item.thumbnailUrl != null
                          ? CachedNetworkImage(
                              imageUrl: item.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  _ThumbPlaceholder(isDark: isDark),
                            )
                          : _ThumbPlaceholder(isDark: isDark),
                      // Progress bar at bottom
                      if (item.watchedSeconds > 0)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            value: item.progressPercent,
                            backgroundColor: Colors.white24,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(
                              item.isCompleted ? Colors.white54 : _green,
                            ),
                            minHeight: 2.5,
                          ),
                        ),
                      // Duration badge
                      if (item.durationFormatted != null)
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.durationFormatted!,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ── Info ───────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF111827),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 4),

                    if (item.scholarName != null)
                      Text(
                        item.scholarName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          item.timeAgoLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!item.isCompleted && item.watchedSeconds > 5) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.resumeLabel,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _green,
                              ),
                            ),
                          ),
                        ] else if (item.isCompleted) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    size: 10,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey.shade500),
                                const SizedBox(width: 3),
                                Text(
                                  'Watched',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
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

// =============================================================================
// Helper Widgets
// =============================================================================

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton(
      {required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.15),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ClearAllButton extends StatelessWidget {
  const _ClearAllButton(
      {required this.isClearing, required this.onTap});

  final bool isClearing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isClearing ? null : onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: isClearing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.delete_sweep_rounded,
                      size: 15, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    'Clear All',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB),
      child: Icon(
        Icons.play_circle_outline_rounded,
        size: 28,
        color: isDark ? Colors.white24 : Colors.black26,
      ),
    );
  }
}

// =============================================================================
// Islamic Geometric Pattern CustomPainter
// =============================================================================

class _GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Draw subtle 8-pointed star pattern
    const spacing = 60.0;
    for (double x = -spacing / 2; x < size.width + spacing; x += spacing) {
      for (double y = -spacing / 2; y < size.height + spacing; y += spacing) {
        _drawStar(canvas, paint, Offset(x, y), 18);
      }
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 2;
      final outerX = center.dx + radius * math.cos(angle);
      final outerY = center.dy + radius * math.sin(angle);
      final innerAngle = angle + math.pi / 8;
      final innerRadius = radius * 0.4;
      final innerX = center.dx + innerRadius * math.cos(innerAngle);
      final innerY = center.dy + innerRadius * math.sin(innerAngle);
      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(innerX, innerY);
        path.lineTo(outerX, outerY);
      }
      if (i == 7) {
        final lastInnerAngle = angle + math.pi / 8 + math.pi / 4;
        final lastInnerX =
            center.dx + innerRadius * math.cos(lastInnerAngle);
        final lastInnerY =
            center.dy + innerRadius * math.sin(lastInnerAngle);
        path.lineTo(lastInnerX, lastInnerY);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Inner circle
    canvas.drawCircle(center, radius * 0.22, paint);
  }

  @override
  bool shouldRepaint(_GeometricPatternPainter old) => false;
}
