import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'package:ehsan_pathways/core/providers/auth_provider.dart';
import 'package:ehsan_pathways/features/bookmarks/bookmark_provider.dart';
import 'package:ehsan_pathways/features/history/history_provider.dart';
import 'package:ehsan_pathways/features/notes/notes_provider.dart';
import 'package:ehsan_pathways/features/videos/video_provider.dart';
import 'package:ehsan_pathways/shared/widgets/badge_chip.dart';
import 'package:ehsan_pathways/shared/widgets/content_card.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';
import 'package:ehsan_pathways/shared/widgets/scholar_avatar.dart';
import 'package:ehsan_pathways/shared/widgets/section_header.dart';

// ─── Colours ──────────────────────────────────────────────────────────────────
const _primaryGreen = Color(0xFF16A34A);
const _gold = Color(0xFFF59E0B);

/// Video detail screen — YouTube-inspired but with Islamic aesthetics.
///
/// Features:
/// - YouTube player with green progress bar
/// - Scroll-aware gradient app bar
/// - Action row: Share · Note · Bookmark · More
/// - Scholar card (tap → scholar profile)
/// - Expandable description
/// - Tags
/// - Related videos horizontal scroll
/// - Watch progress auto-saved every 30 s and on exit
class VideoDetailScreen extends ConsumerStatefulWidget {
  const VideoDetailScreen({super.key, required this.uuid});

  final String uuid;

  @override
  ConsumerState<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends ConsumerState<VideoDetailScreen>
    with WidgetsBindingObserver {
  YoutubePlayerController? _ytController;
  final _scrollController = ScrollController();

  bool _descriptionExpanded = false;
  double _appBarOpacity = 0.0;

  // Watch-progress tracking
  int _watchedSeconds = 0;
  int _totalSeconds = 0;
  Timer? _progressTimer;
  bool _progressDirty = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressTimer?.cancel();
    _flushProgress();
    _ytController?.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Save progress when the app goes to background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _flushProgress();
  }

  // ── Scroll-aware app bar ───────────────────────────────────────────────────

  void _onScroll() {
    const fadeStart = 180.0;
    const fadeEnd = 280.0;
    final offset = _scrollController.offset;
    final opacity = offset > fadeStart
        ? ((offset - fadeStart) / (fadeEnd - fadeStart)).clamp(0.0, 1.0)
        : 0.0;
    if (opacity != _appBarOpacity) setState(() => _appBarOpacity = opacity);
  }

  // ── YouTube player ─────────────────────────────────────────────────────────

  void _ensureYoutubeController(String? youtubeUrl) {
    if (_ytController != null || youtubeUrl == null) return;
    final videoId = YoutubePlayer.convertUrlToId(youtubeUrl);
    if (videoId == null) return;

    _ytController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        forceHD: false,
      ),
    )..addListener(_onPlayerUpdate);

    // Start 30-second save timer
    _progressTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _flushProgress(),
    );

    if (mounted) setState(() {});
  }

  void _onPlayerUpdate() {
    if (_ytController == null) return;
    final pos = _ytController!.value.position.inSeconds;
    final dur = _ytController!.metadata.duration.inSeconds;
    if (pos > 0) {
      _watchedSeconds = pos;
      if (dur > 0) _totalSeconds = dur;
      _progressDirty = true;
    }
  }

  Future<void> _flushProgress() async {
    if (!_progressDirty || _watchedSeconds <= 0) return;
    _progressDirty = false;
    await ref.read(historyProvider.notifier).updateProgress(
          uuid: widget.uuid,
          watchedSeconds: _watchedSeconds,
          totalSeconds: _totalSeconds,
        );
  }

  // ── Share ──────────────────────────────────────────────────────────────────

  void _share(Video video) {
    final url = 'https://ehsanpathways.com/videos/${video.uuid}';
    Share.share('${video.title}\n\n$url', subject: video.title);
  }

  // ── Quick Note sheet ───────────────────────────────────────────────────────

  void _showNoteSheet(Video video) {
    final authState = ref.read(authProvider);
    if (authState.status != AuthStatus.authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign in to take notes',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: _primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Sign In',
            textColor: Colors.white,
            onPressed: () => context.push('/login'),
          ),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NoteBottomSheet(
        video: video,
        currentTimestamp: _watchedSeconds > 0 ? _watchedSeconds : null,
      ),
    );
  }

  // ── More options ───────────────────────────────────────────────────────────

  void _showMoreOptions(Video video) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoreOptionsSheet(video: video, isDark: isDark),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final videoAsync = ref.watch(videoDetailProvider(widget.uuid));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return videoAsync.when(
      loading: () => _buildLoadingScaffold(isDark),
      error: (error, _) => _buildErrorScaffold(isDark, error),
      data: (video) {
        _ensureYoutubeController(video.youtubeUrl);
        return _buildScaffold(video, isDark);
      },
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Scaffold _buildLoadingScaffold(bool isDark) {
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _BackButton(isDark: isDark),
      ),
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerWrap(
              child: ShimmerBox(
                  width: double.infinity, height: 220, borderRadius: 0),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ShimmerWrap(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: double.infinity, height: 22),
                    SizedBox(height: 10),
                    ShimmerBox(width: 220, height: 22),
                    SizedBox(height: 20),
                    // Action row shimmer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ShimmerBox(width: 60, height: 52, borderRadius: 12),
                        ShimmerBox(width: 60, height: 52, borderRadius: 12),
                        ShimmerBox(width: 60, height: 52, borderRadius: 12),
                        ShimmerBox(width: 60, height: 52, borderRadius: 12),
                      ],
                    ),
                    SizedBox(height: 20),
                    ShimmerBox(width: double.infinity, height: 70),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────

  Scaffold _buildErrorScaffold(bool isDark, Object error) {
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _BackButton(isDark: isDark),
      ),
      body: EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Failed to load video',
        subtitle: 'Please check your connection and try again.',
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(videoDetailProvider(widget.uuid)),
        iconColor: Colors.red.shade400,
      ),
    );
  }

  // ── Main scaffold ──────────────────────────────────────────────────────────

  Scaffold _buildScaffold(Video video, bool isDark) {
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
      extendBodyBehindAppBar: true,
      appBar: _buildGradientAppBar(video.title, isDark),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Player ───────────────────────────────────────────────
            _buildPlayer(isDark),

            // ── Title ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Text(
                video.title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  height: 1.3,
                ),
              ),
            ),

            // ── Meta (views · duration · category) ───────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _buildMetaBadges(video, isDark),
            ),

            // ── ACTION ROW ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
              child: _buildActionRow(video, isDark),
            ),

            // Divider
            _Divider(isDark: isDark),

            // ── Scholar ──────────────────────────────────────────────
            if (video.scholar != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: _buildScholarRow(video.scholar!, isDark),
              ),

            _Divider(isDark: isDark),

            // ── Description ──────────────────────────────────────────
            if (video.description != null &&
                video.description!.isNotEmpty)
              _buildDescription(video.description!, isDark),

            // ── Tags ─────────────────────────────────────────────────
            if (video.tags.isNotEmpty) _buildTags(video.tags, isDark),

            // ── Related Videos ───────────────────────────────────────
            if (video.relatedVideos.isNotEmpty)
              _buildRelatedVideos(video.relatedVideos, isDark),

            SizedBox(height: MediaQuery.paddingOf(context).bottom + 32),
          ],
        ),
      ),
    );
  }

  // ── Gradient app bar ───────────────────────────────────────────────────────

  PreferredSizeWidget _buildGradientAppBar(String title, bool isDark) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _primaryGreen.withValues(alpha: _appBarOpacity),
              const Color(0xFF059669).withValues(alpha: _appBarOpacity),
            ],
          ),
          boxShadow: _appBarOpacity > 0.5
              ? [
                  BoxShadow(
                    color:
                        _primaryGreen.withValues(alpha: 0.2 * _appBarOpacity),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: _BackButton(
            isDark: isDark,
            overrideColor: _appBarOpacity > 0.5 ? Colors.white : null,
          ),
          title: AnimatedOpacity(
            opacity: _appBarOpacity,
            duration: const Duration(milliseconds: 200),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  // ── Player ─────────────────────────────────────────────────────────────────

  Widget _buildPlayer(bool isDark) {
    if (_ytController == null) {
      return Container(
        width: double.infinity,
        height: 220 + MediaQuery.paddingOf(context).top,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1A1A1A)
              : const Color(0xFFE5E7EB),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: MediaQuery.paddingOf(context).top),
              Icon(Icons.play_circle_outline_rounded,
                  size: 56,
                  color: isDark ? Colors.white24 : Colors.black26),
              const SizedBox(height: 10),
              Text('Video unavailable',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white38 : Colors.black38)),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      child: YoutubePlayer(
        controller: _ytController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: _primaryGreen,
        progressColors: const ProgressBarColors(
          playedColor: _primaryGreen,
          handleColor: _primaryGreen,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
      ),
    );
  }

  // ── Meta badges ────────────────────────────────────────────────────────────

  Widget _buildMetaBadges(Video video, bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _MetaItem(
          icon: Icons.visibility_outlined,
          label: _formatViewCount(video.viewCount),
          isDark: isDark,
        ),
        if (video.durationFormatted != null &&
            video.durationFormatted!.isNotEmpty)
          _MetaItem(
            icon: Icons.access_time_rounded,
            label: video.durationFormatted!,
            isDark: isDark,
          ),
        if (video.category != null)
          BadgeChip(
            label: video.category!.name,
            variant: BadgeVariant.green,
            icon: Icons.category_outlined,
          ),
      ],
    );
  }

  String _formatViewCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M views';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K views';
    return '$count ${count == 1 ? 'view' : 'views'}';
  }

  // ── ACTION ROW ─────────────────────────────────────────────────────────────
  //
  // YouTube-style pill buttons: Share · Note · Bookmark · More
  //

  Widget _buildActionRow(Video video, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _ActionButton(
            icon: Icons.share_rounded,
            label: 'Share',
            isDark: isDark,
            onTap: () => _share(video),
          ),
          const SizedBox(width: 10),
          _ActionButton(
            icon: Icons.edit_note_rounded,
            label: 'Note',
            isDark: isDark,
            onTap: () => _showNoteSheet(video),
          ),
          const SizedBox(width: 10),
          _BookmarkActionButton(
            uuid: widget.uuid,
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          _ActionButton(
            icon: Icons.more_horiz_rounded,
            label: 'More',
            isDark: isDark,
            onTap: () => _showMoreOptions(video),
          ),
        ],
      ),
    );
  }

  // ── Scholar row ────────────────────────────────────────────────────────────

  Widget _buildScholarRow(VideoScholar scholar, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/scholars/${scholar.slug}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : _primaryGreen.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : _primaryGreen.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            ScholarAvatar(
              name: scholar.name,
              imageUrl: scholar.avatarUrl,
              size: ScholarAvatarSize.medium,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scholar.name,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827))),
                  const SizedBox(height: 3),
                  Text('View scholar profile',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _primaryGreen)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : Colors.black26, size: 22),
          ],
        ),
      ),
    );
  }

  // ── Description ────────────────────────────────────────────────────────────

  Widget _buildDescription(String description, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About this video',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  letterSpacing: -0.2)),
          const SizedBox(height: 10),
          AnimatedCrossFade(
            firstChild: Text(description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: _descStyle(isDark)),
            secondChild: Text(description, style: _descStyle(isDark)),
            crossFadeState: _descriptionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () =>
                setState(() => _descriptionExpanded = !_descriptionExpanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _descriptionExpanded ? 'Show less' : 'Read more',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _primaryGreen),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _descriptionExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: _primaryGreen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  TextStyle _descStyle(bool isDark) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
      );

  // ── Tags ───────────────────────────────────────────────────────────────────

  Widget _buildTags(List<VideoTag> tags, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Topics',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  letterSpacing: -0.2)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map((t) => BadgeChip(
                    label: t.name,
                    variant: BadgeVariant.gray,
                    size: BadgeSize.regular))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Related Videos ─────────────────────────────────────────────────────────

  Widget _buildRelatedVideos(List<Video> related, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            height: 1,
          ),
        ),
        SectionHeader(
          title: 'Up Next',
          subtitle: 'Continue your learning journey',
        ),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: related.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final rv = related[index];
              return SizedBox(
                width: 200,
                child: ContentCard(
                  title: rv.title,
                  subtitle: rv.scholar?.name,
                  imageUrl: rv.thumbnailUrl,
                  contentType: ContentType.video,
                  trailingInfo: rv.durationFormatted,
                  trailingIcon: Icons.access_time_rounded,
                  height: 115,
                  onTap: () => context.push('/videos/${rv.uuid}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// ACTION ROW WIDGETS
// =============================================================================

/// A YouTube-style pill action button (icon + label).
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.isActive = false,
    this.activeColor = _primaryGreen,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final bool isActive;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final bg = isActive
        ? activeColor.withValues(alpha: 0.12)
        : (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05));
    final fg = isActive
        ? activeColor
        : (isDark ? Colors.white70 : const Color(0xFF374151));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.3)
                : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bookmark action button — stateful, toggles on tap.
class _BookmarkActionButton extends ConsumerStatefulWidget {
  const _BookmarkActionButton(
      {required this.uuid, required this.isDark});

  final String uuid;
  final bool isDark;

  @override
  ConsumerState<_BookmarkActionButton> createState() =>
      _BookmarkActionButtonState();
}

class _BookmarkActionButtonState
    extends ConsumerState<_BookmarkActionButton> {
  bool _isBookmarked = false;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _checkBookmark();
  }

  Future<void> _checkBookmark() async {
    final result = await ref.read(
      isBookmarkedProvider((type: 'video', id: widget.uuid)).future,
    );
    if (mounted) setState(() => _isBookmarked = result);
  }

  Future<void> _toggle() async {
    if (_isToggling) return;
    setState(() => _isToggling = true);
    final result = await ref
        .read(bookmarkListProvider.notifier)
        .toggleBookmark('video', widget.uuid);
    if (mounted) {
      setState(() {
        _isBookmarked = result;
        _isToggling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _isBookmarked
        ? _gold.withValues(alpha: 0.12)
        : (widget.isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05));
    final fg = _isBookmarked
        ? _gold
        : (widget.isDark ? Colors.white70 : const Color(0xFF374151));

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isBookmarked
                ? _gold.withValues(alpha: 0.3)
                : (widget.isDark
                    ? Colors.white12
                    : Colors.black.withValues(alpha: 0.07)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isToggling
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: fg),
                  )
                : Icon(
                    _isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 18,
                    color: fg,
                  ),
            const SizedBox(width: 7),
            Text(
              _isBookmarked ? 'Saved' : 'Save',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// QUICK NOTE BOTTOM SHEET
// =============================================================================

class _NoteBottomSheet extends ConsumerStatefulWidget {
  const _NoteBottomSheet({required this.video, this.currentTimestamp});

  final Video video;
  final int? currentTimestamp;

  @override
  ConsumerState<_NoteBottomSheet> createState() => _NoteBottomSheetState();
}

class _NoteBottomSheetState extends ConsumerState<_NoteBottomSheet> {
  final _ctrl = TextEditingController();
  bool _isSaving = false;
  bool _includeTimestamp = true;

  String get _timestampLabel {
    if (widget.currentTimestamp == null || widget.currentTimestamp == 0) {
      return '';
    }
    final m = widget.currentTimestamp! ~/ 60;
    final s = widget.currentTimestamp! % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    final ok = await ref.read(noteListProvider.notifier).createNote(
          notableType: 'video',
          notableId: widget.video.id ?? 0,
          content: _ctrl.text.trim(),
          timestampSeconds: (_includeTimestamp && widget.currentTimestamp != null)
              ? widget.currentTimestamp
              : null,
        );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Note saved!' : 'Failed to save note',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: ok ? _primaryGreen : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(Icons.edit_note_rounded,
                  color: _primaryGreen, size: 22),
              const SizedBox(width: 8),
              Text('Quick Note',
                  style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF111827))),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            widget.video.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.grey.shade500),
          ),

          const SizedBox(height: 16),

          // Text field
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLines: 4,
            minLines: 3,
            decoration: InputDecoration(
              hintText: 'Write your note here...',
              hintStyle: GoogleFonts.inter(
                  color: isDark ? Colors.white38 : Colors.grey.shade400),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),

          // Timestamp toggle
          if (widget.currentTimestamp != null && widget.currentTimestamp! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: GestureDetector(
                onTap: () =>
                    setState(() => _includeTimestamp = !_includeTimestamp),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _includeTimestamp
                            ? _primaryGreen
                            : Colors.transparent,
                        border: Border.all(
                          color: _includeTimestamp
                              ? _primaryGreen
                              : Colors.grey.shade400,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: _includeTimestamp
                          ? const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Link to timestamp $_timestampLabel',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Save Note',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// MORE OPTIONS SHEET
// =============================================================================

class _MoreOptionsSheet extends StatelessWidget {
  const _MoreOptionsSheet({required this.video, required this.isDark});

  final Video video;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          _MoreOption(
            icon: Icons.open_in_browser_rounded,
            label: 'Open on YouTube',
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              if (video.youtubeUrl != null) {
                launchUrl(Uri.parse(video.youtubeUrl!),
                    mode: LaunchMode.externalApplication);
              }
            },
          ),
          _MoreOption(
            icon: Icons.copy_rounded,
            label: 'Copy link',
            isDark: isDark,
            onTap: () {
              final url = video.youtubeUrl ??
                  'https://ehsanpathways.com/videos/${video.uuid}';
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Link copied!',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  backgroundColor: _primaryGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          _MoreOption(
            icon: Icons.report_outlined,
            label: 'Report an issue',
            isDark: isDark,
            color: Colors.orange.shade400,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MoreOption extends StatelessWidget {
  const _MoreOption({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? (isDark ? Colors.white : const Color(0xFF374151));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: c),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SHARED PRIVATE WIDGETS
// =============================================================================

class _Divider extends StatelessWidget {
  const _Divider({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Divider(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
        height: 1,
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.isDark, this.overrideColor});

  final bool isDark;
  final Color? overrideColor;

  @override
  Widget build(BuildContext context) {
    final color =
        overrideColor ?? (isDark ? Colors.white : const Color(0xFF111827));
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.pop(),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(Icons.arrow_back_rounded, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem(
      {required this.icon, required this.label, required this.isDark});

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final c =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: c),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w500, color: c)),
      ],
    );
  }
}
