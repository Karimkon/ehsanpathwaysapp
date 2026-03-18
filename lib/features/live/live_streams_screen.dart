import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

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

final liveStreamsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(_contentServiceProvider);
  return service.fetchLiveStreams();
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class LiveStreamsScreen extends ConsumerStatefulWidget {
  const LiveStreamsScreen({super.key});

  @override
  ConsumerState<LiveStreamsScreen> createState() => _LiveStreamsScreenState();
}

class _LiveStreamsScreenState extends ConsumerState<LiveStreamsScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) ref.invalidate(liveStreamsProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(liveStreamsProvider);
  }

  String _formatStartTime(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final streamDay = DateTime(dt.year, dt.month, dt.day);

      String dayStr;
      if (streamDay == today) {
        dayStr = 'Today';
      } else if (streamDay ==
          today.add(const Duration(days: 1))) {
        dayStr = 'Tomorrow';
      } else {
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        dayStr = '${months[dt.month - 1]} ${dt.day}';
      }

      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$dayStr at $hour:$minute $ampm';
    } catch (_) {
      return raw;
    }
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final streamsAsync = ref.watch(liveStreamsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFF14532D),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF14532D),
                      Color(0xFF15803D),
                      Color(0xFF16A34A),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.live_tv_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Live Streams',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Watch Islamic content live',
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
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          streamsAsync.when(
            loading: () => SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _StreamShimmer(isDark: isDark),
                childCount: 4,
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: EmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Could not load streams',
                subtitle: 'Please check your connection and try again.',
                actionLabel: 'Retry',
                onAction: _onRefresh,
              ),
            ),
            data: (data) {
              final liveNow =
                  (data['live_now'] as List<dynamic>? ?? [])
                      .cast<Map<String, dynamic>>();
              final upcoming =
                  (data['upcoming'] as List<dynamic>? ?? [])
                      .cast<Map<String, dynamic>>();

              if (liveNow.isEmpty && upcoming.isEmpty) {
                return SliverFillRemaining(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: AppTheme.primaryGreen,
                    child: ListView(
                      children: [
                        EmptyState(
                          icon: Icons.live_tv_rounded,
                          title: 'No live streams currently',
                          subtitle:
                              'Check back soon for live Islamic content.',
                          iconColor: const Color(0xFFDC2626),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildListDelegate([
                  // Live Now section
                  if (liveNow.isNotEmpty) ...[
                    _SectionHeader(
                      label: 'LIVE NOW',
                      icon: Icons.circle,
                      iconColor: const Color(0xFFDC2626),
                      pulse: true,
                      isDark: isDark,
                    ),
                    ...liveNow.map((stream) => _StreamCard(
                          stream: stream,
                          isLive: true,
                          isDark: isDark,
                          formatTime: _formatStartTime,
                          onWatch: () =>
                              _launchUrl(stream['stream_url'] as String?),
                        )),
                  ],

                  // Upcoming section
                  if (upcoming.isNotEmpty) ...[
                    _SectionHeader(
                      label: 'UPCOMING',
                      icon: Icons.schedule_rounded,
                      iconColor: AppTheme.primaryGreen,
                      isDark: isDark,
                    ),
                    ...upcoming.map((stream) => _StreamCard(
                          stream: stream,
                          isLive: false,
                          isDark: isDark,
                          formatTime: _formatStartTime,
                          onWatch: null,
                        )),
                  ],

                  const SizedBox(height: 32),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatefulWidget {
  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    this.pulse = false,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final bool pulse;

  @override
  State<_SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<_SectionHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.pulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          if (widget.pulse)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, __) => Icon(
                widget.icon,
                size: 12,
                color: widget.iconColor
                    .withValues(alpha: _pulseAnimation.value),
              ),
            )
          else
            Icon(widget.icon, size: 14, color: widget.iconColor),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: widget.iconColor,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stream card
// ---------------------------------------------------------------------------

class _StreamCard extends StatelessWidget {
  const _StreamCard({
    required this.stream,
    required this.isLive,
    required this.isDark,
    required this.formatTime,
    required this.onWatch,
  });

  final Map<String, dynamic> stream;
  final bool isLive;
  final bool isDark;
  final String Function(String?) formatTime;
  final VoidCallback? onWatch;

  @override
  Widget build(BuildContext context) {
    final title = stream['title'] as String? ?? '';
    final scholar = stream['scholar'] as Map<String, dynamic>?;
    final scholarName = scholar?['name'] as String? ?? '';
    final streamType = stream['stream_type'] as String? ?? '';
    final startTime = stream['start_time'] as String?;
    final description = stream['description'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isLive
              ? Border.all(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                  width: 1.5,
                )
              : null,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isLive
                        ? const Color(0xFFDC2626).withValues(alpha: 0.1)
                        : AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isLive ? Icons.live_tv_rounded : Icons.schedule_rounded,
                    color: isLive
                        ? const Color(0xFFDC2626)
                        : AppTheme.primaryGreen,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                          height: 1.35,
                        ),
                      ),
                      if (scholarName.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          scholarName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
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

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (isLive)
                        const BadgeChip(
                          label: 'LIVE',
                          variant: BadgeVariant.red,
                          size: BadgeSize.small,
                          icon: Icons.circle,
                          filled: true,
                        ),
                      if (streamType.isNotEmpty)
                        BadgeChip(
                          label: streamType,
                          variant: BadgeVariant.gray,
                          size: BadgeSize.small,
                        ),
                      if (startTime != null)
                        BadgeChip(
                          label: formatTime(startTime),
                          variant: BadgeVariant.blue,
                          size: BadgeSize.small,
                          icon: Icons.access_time_rounded,
                        ),
                    ],
                  ),
                ),
                if (isLive && onWatch != null)
                  FilledButton.icon(
                    onPressed: onWatch,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: Text(
                      'Watch',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer
// ---------------------------------------------------------------------------

class _StreamShimmer extends StatelessWidget {
  const _StreamShimmer({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                    ShimmerBox(width: double.infinity, height: 13),
                    SizedBox(height: 7),
                    ShimmerBox(width: 120, height: 11),
                    SizedBox(height: 10),
                    ShimmerBox(width: double.infinity, height: 11),
                    SizedBox(height: 5),
                    ShimmerBox(width: 180, height: 11),
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
