import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shimmer/shimmer.dart';

import 'package:share_plus/share_plus.dart';

import 'package:ehsan_pathways/features/podcasts/podcast_provider.dart';
import 'package:ehsan_pathways/shared/widgets/scholar_avatar.dart';
import 'package:ehsan_pathways/shared/widgets/badge_chip.dart';
import 'package:ehsan_pathways/shared/widgets/section_header.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';

// ---------------------------------------------------------------------------
// Colour constants
// ---------------------------------------------------------------------------

const Color _podcastPurple = Color(0xFF8B5CF6);
const Color _podcastPurpleLight = Color(0xFFA78BFA);
const Color _podcastPurpleDark = Color(0xFF7C3AED);
const Color _primaryGreen = Color(0xFF16A34A);

// ---------------------------------------------------------------------------
// Podcast Detail Screen
// ---------------------------------------------------------------------------

class PodcastDetailScreen extends ConsumerStatefulWidget {
  const PodcastDetailScreen({
    super.key,
    required this.slug,
  });

  final String slug;

  @override
  ConsumerState<PodcastDetailScreen> createState() =>
      _PodcastDetailScreenState();
}

class _PodcastDetailScreenState extends ConsumerState<PodcastDetailScreen> {
  late final AudioPlayer _audioPlayer;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Sets the audio source once we have the podcast data.
  Future<void> _initAudio(Podcast podcast) async {
    if (podcast.audioUrl == null || podcast.audioUrl!.isEmpty) return;
    try {
      // Only set if not already loaded or if the URL changed.
      final currentUri = _audioPlayer.audioSource;
      if (currentUri == null) {
        await _audioPlayer.setUrl(podcast.audioUrl!);
      }
    } catch (_) {
      // Silently ignore audio init errors; the UI will show a disabled state.
    }
  }

  void _seekRelative(Duration offset) {
    final current = _audioPlayer.position;
    final duration = _audioPlayer.duration ?? Duration.zero;
    var target = current + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (target > duration) target = duration;
    _audioPlayer.seek(target);
  }

  @override
  Widget build(BuildContext context) {
    final asyncPodcast = ref.watch(podcastDetailProvider(widget.slug));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: asyncPodcast.when(
        loading: () => _buildLoadingState(isDark),
        error: (error, _) => _buildErrorState(isDark),
        data: (podcast) {
          // Kick off audio init (idempotent).
          _initAudio(podcast);
          return _buildContent(podcast, isDark);
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Loading
  // -------------------------------------------------------------------------

  Widget _buildLoadingState(bool isDark) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: ShimmerWrap(
              child: Container(color: Colors.white),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ShimmerWrap(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: double.infinity, height: 24),
                  SizedBox(height: 12),
                  ShimmerBox(width: 200, height: 16),
                  SizedBox(height: 24),
                  ShimmerBox(width: double.infinity, height: 48),
                  SizedBox(height: 24),
                  ShimmerBox(width: double.infinity, height: 80),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Error
  // -------------------------------------------------------------------------

  Widget _buildErrorState(bool isDark) {
    return SafeArea(
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          Expanded(
            child: EmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'Could not load podcast',
              subtitle: 'Please check your connection and try again.',
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(podcastDetailProvider(widget.slug)),
              iconColor: _podcastPurple,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Main content
  // -------------------------------------------------------------------------

  Widget _buildContent(Podcast podcast, bool isDark) {
    return CustomScrollView(
      slivers: [
        // -- Collapsing header with cover art --------------------------------
        SliverAppBar(
          expandedHeight: 340,
          pinned: true,
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          leading: _BackButton(isDark: isDark),
          flexibleSpace: FlexibleSpaceBar(
            background: _CoverArtHeader(
              imageUrl: podcast.coverImageUrl,
              isDark: isDark,
              player: _audioPlayer,
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -- Series badge -------------------------------------------
                if (podcast.series != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: BadgeChip(
                      label: podcast.series!.title,
                      variant: BadgeVariant.purple,
                      icon: Icons.album_rounded,
                    ),
                  ),

                // -- Title --------------------------------------------------
                Text(
                  podcast.title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 14),

                // -- Scholar info -------------------------------------------
                if (podcast.scholar != null)
                  _ScholarRow(
                    scholar: podcast.scholar!,
                    episodeNumber: podcast.episodeNumber,
                    isDark: isDark,
                  ),

                const SizedBox(height: 20),

                // -- Share button -------------------------------------------
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final url =
                          'https://ehsanpathways.com/podcasts/${podcast.slug}';
                      Share.share(
                        '${podcast.title}\n\n$url',
                        subject: podcast.title,
                      );
                    },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share Episode'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _podcastPurple,
                      side: const BorderSide(color: _podcastPurple),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // -- Audio player controls ----------------------------------
                _AudioPlayerControls(
                  player: _audioPlayer,
                  durationSeconds: podcast.durationSeconds,
                  hasAudio: podcast.audioUrl != null &&
                      podcast.audioUrl!.isNotEmpty,
                  isDark: isDark,
                  onSkipBackward: () =>
                      _seekRelative(const Duration(seconds: -15)),
                  onSkipForward: () =>
                      _seekRelative(const Duration(seconds: 15)),
                ),

                const SizedBox(height: 28),

                // -- Description (expandable) -------------------------------
                if (podcast.description != null &&
                    podcast.description!.isNotEmpty)
                  _ExpandableDescription(
                    description: podcast.description!,
                    isExpanded: _isDescriptionExpanded,
                    isDark: isDark,
                    onToggle: () {
                      setState(() {
                        _isDescriptionExpanded = !_isDescriptionExpanded;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),

        // -- Related episodes -----------------------------------------------
        if (podcast.relatedPodcasts.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Related Episodes',
              subtitle: 'More from this series',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final related = podcast.relatedPodcasts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RelatedEpisodeItem(
                      podcast: related,
                      isDark: isDark,
                      onTap: () {
                        context.push('/podcasts/${related.slug}');
                      },
                    ),
                  );
                },
                childCount: podcast.relatedPodcasts.length,
              ),
            ),
          ),
        ],

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 40),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Back Button
// ---------------------------------------------------------------------------

class _BackButton extends StatelessWidget {
  const _BackButton({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF111827),
            size: 22,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cover Art Header (large, centred, pulsing when playing)
// ---------------------------------------------------------------------------

class _CoverArtHeader extends StatefulWidget {
  const _CoverArtHeader({
    this.imageUrl,
    required this.isDark,
    required this.player,
  });

  final String? imageUrl;
  final bool isDark;
  final AudioPlayer player;

  @override
  State<_CoverArtHeader> createState() => _CoverArtHeaderState();
}

class _CoverArtHeaderState extends State<_CoverArtHeader>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  StreamSubscription<PlayerState>? _playerSub;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _playerSub = widget.player.playerStateStream.listen((state) {
      if (!mounted) return;
      final playing = state.playing &&
          state.processingState != ProcessingState.completed &&
          state.processingState != ProcessingState.idle;
      if (playing != _isPlaying) {
        setState(() => _isPlaying = playing);
        if (playing) {
          _pulseController.repeat(reverse: true);
          _waveController.repeat();
        } else {
          _pulseController.stop();
          _pulseController.animateBack(0);
          _waveController.stop();
        }
      }
    });
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.isDark
              ? [
                  _podcastPurple.withValues(alpha: 0.15),
                  const Color(0xFF121212),
                ]
              : [
                  _podcastPurple.withValues(alpha: 0.08),
                  Colors.white,
                ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 56),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _podcastPurple.withValues(
                        alpha: _isPlaying ? 0.5 : 0.25),
                    blurRadius: _isPlaying ? 60 : 40,
                    offset: const Offset(0, 16),
                    spreadRadius: _isPlaying ? 6 : 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(
                        alpha: widget.isDark ? 0.4 : 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.imageUrl!,
                      fit: BoxFit.cover,
                      width: 220,
                      height: 220,
                      placeholder: (_, __) => Shimmer.fromColors(
                        baseColor: widget.isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFE5E7EB),
                        highlightColor: widget.isDark
                            ? const Color(0xFF3A3A3A)
                            : const Color(0xFFF3F4F6),
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(height: 18),
          _WaveformBars(
            waveController: _waveController,
            isPlaying: _isPlaying,
            isDark: widget.isDark,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _podcastPurple.withValues(alpha: widget.isDark ? 0.35 : 0.2),
            _podcastPurpleDark.withValues(alpha: widget.isDark ? 0.2 : 0.1),
          ],
        ),
      ),
      child: Icon(
        Icons.headphones_rounded,
        size: 80,
        color: _podcastPurple.withValues(alpha: 0.5),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated Waveform / Equalizer Bars
// ---------------------------------------------------------------------------

class _WaveformBars extends StatelessWidget {
  const _WaveformBars({
    required this.waveController,
    required this.isPlaying,
    required this.isDark,
  });

  final AnimationController waveController;
  final bool isPlaying;
  final bool isDark;

  static const _phases = [0.0, 1.1, 2.3, 0.6, 1.8, 3.0, 0.4];
  static const _maxH = [28.0, 36.0, 24.0, 40.0, 22.0, 34.0, 18.0];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: AnimatedBuilder(
        animation: waveController,
        builder: (context, __) {
          final t = waveController.value * 2 * pi;
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_phases.length, (i) {
              final h = isPlaying
                  ? _maxH[i] * 0.35 +
                      _maxH[i] * 0.65 * ((sin(t + _phases[i]) + 1) / 2)
                  : 4.0;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 4,
                height: h.clamp(4.0, 44.0),
                decoration: BoxDecoration(
                  color: _podcastPurple.withValues(
                      alpha: isPlaying ? 0.9 : 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
// ---------------------------------------------------------------------------
// Scholar Row
// ---------------------------------------------------------------------------

class _ScholarRow extends StatelessWidget {
  const _ScholarRow({
    required this.scholar,
    this.episodeNumber,
    required this.isDark,
  });

  final PodcastScholar scholar;
  final int? episodeNumber;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ScholarAvatar(
          name: scholar.name,
          imageUrl: scholar.avatarUrl,
          size: ScholarAvatarSize.small,
          borderColor: _podcastPurple,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                scholar.name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              if (episodeNumber != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Episode $episodeNumber',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _podcastPurple,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Audio Player Controls
// ---------------------------------------------------------------------------

class _AudioPlayerControls extends StatelessWidget {
  const _AudioPlayerControls({
    required this.player,
    required this.durationSeconds,
    required this.hasAudio,
    required this.isDark,
    required this.onSkipBackward,
    required this.onSkipForward,
  });

  final AudioPlayer player;
  final int durationSeconds;
  final bool hasAudio;
  final bool isDark;
  final VoidCallback onSkipBackward;
  final VoidCallback onSkipForward;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? _podcastPurple.withValues(alpha: 0.08)
            : _podcastPurple.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _podcastPurple.withValues(alpha: isDark ? 0.15 : 0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // -- Seek bar / progress slider ---------------------------------
          _SeekBar(
            player: player,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // -- Control buttons --------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Skip backward 15s
              _ControlButton(
                icon: Icons.replay_rounded,
                label: '15',
                size: 44,
                onTap: hasAudio ? onSkipBackward : null,
                isDark: isDark,
              ),
              const SizedBox(width: 20),

              // Play / Pause (large, circular, green gradient)
              _PlayPauseButton(
                player: player,
                hasAudio: hasAudio,
                isDark: isDark,
              ),
              const SizedBox(width: 20),

              // Skip forward 15s
              _ControlButton(
                icon: Icons.forward_rounded,
                label: '15',
                size: 44,
                onTap: hasAudio ? onSkipForward : null,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Seek Bar
// ---------------------------------------------------------------------------

class _SeekBar extends StatelessWidget {
  const _SeekBar({
    required this.player,
    required this.isDark,
  });

  final AudioPlayer player;
  final bool isDark;

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, posSnapshot) {
        final position = posSnapshot.data ?? Duration.zero;
        final duration = player.duration ?? Duration.zero;
        final maxVal = duration.inMilliseconds.toDouble();
        final curVal = position.inMilliseconds
            .toDouble()
            .clamp(0.0, maxVal > 0 ? maxVal : 1.0);

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 7,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 16,
                ),
                activeTrackColor: _podcastPurple,
                inactiveTrackColor:
                    _podcastPurple.withValues(alpha: isDark ? 0.2 : 0.15),
                thumbColor: _podcastPurple,
                overlayColor: _podcastPurple.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: curVal,
                max: maxVal > 0 ? maxVal : 1.0,
                onChanged: maxVal > 0
                    ? (value) {
                        player.seek(Duration(milliseconds: value.toInt()));
                      }
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Play / Pause Button (large, circular, green gradient)
// ---------------------------------------------------------------------------

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.player,
    required this.hasAudio,
    required this.isDark,
  });

  final AudioPlayer player;
  final bool hasAudio;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final isPlaying = playerState?.playing ?? false;
        final processingState = playerState?.processingState;
        final isBuffering = processingState == ProcessingState.buffering ||
            processingState == ProcessingState.loading;

        return GestureDetector(
          onTap: hasAudio
              ? () {
                  if (processingState == ProcessingState.completed) {
                    player.seek(Duration.zero);
                    player.play();
                  } else if (isPlaying) {
                    player.pause();
                  } else {
                    player.play();
                  }
                }
              : null,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: hasAudio
                    ? [
                        const Color(0xFF22C55E),
                        _primaryGreen,
                      ]
                    : [
                        const Color(0xFF6B7280),
                        const Color(0xFF4B5563),
                      ],
              ),
              boxShadow: hasAudio
                  ? [
                      BoxShadow(
                        color: _primaryGreen.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: isBuffering
                ? const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Icon(
                    isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Skip Control Button (backward / forward)
// ---------------------------------------------------------------------------

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.size,
    required this.isDark,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final double size;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled
        ? (isDark ? Colors.white : const Color(0xFF111827))
        : (isDark ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF));

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: size * 0.7,
              color: color,
            ),
            Positioned(
              bottom: 2,
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expandable Description
// ---------------------------------------------------------------------------

class _ExpandableDescription extends StatelessWidget {
  const _ExpandableDescription({
    required this.description,
    required this.isExpanded,
    required this.isDark,
    required this.onToggle,
  });

  final String description;
  final bool isExpanded;
  final bool isDark;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this Episode',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF111827),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedCrossFade(
          firstChild: Text(
            description,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? const Color(0xFFD1D5DB)
                  : const Color(0xFF4B5563),
              height: 1.7,
            ),
          ),
          secondChild: Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? const Color(0xFFD1D5DB)
                  : const Color(0xFF4B5563),
              height: 1.7,
            ),
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onToggle,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isExpanded ? 'Show less' : 'Read more',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _podcastPurple,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: _podcastPurple,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Related Episode Item
// ---------------------------------------------------------------------------

class _RelatedEpisodeItem extends StatelessWidget {
  const _RelatedEpisodeItem({
    required this.podcast,
    required this.isDark,
    this.onTap,
  });

  final Podcast podcast;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _podcastPurple.withValues(alpha: isDark ? 0.1 : 0.06),
            width: 1,
          ),
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
        child: Row(
          children: [
            // Small cover image
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF3F4F6),
              ),
              clipBehavior: Clip.antiAlias,
              child: podcast.coverImageUrl != null &&
                      podcast.coverImageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: podcast.coverImageUrl!,
                      fit: BoxFit.cover,
                      width: 56,
                      height: 56,
                      placeholder: (_, __) => Container(
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFF3F4F6),
                      ),
                      errorWidget: (_, __, ___) => _relatedPlaceholder(),
                    )
                  : _relatedPlaceholder(),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    podcast.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.headphones_rounded,
                        size: 12,
                        color: _podcastPurple.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        podcast.formattedDuration,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _podcastPurple,
                        ),
                      ),
                      if (podcast.episodeNumber != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Ep. ${podcast.episodeNumber}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Mini play icon
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _podcastPurple.withValues(alpha: isDark ? 0.15 : 0.1),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: _podcastPurple,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _relatedPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      color: _podcastPurple.withValues(alpha: 0.1),
      child: Icon(
        Icons.headphones_rounded,
        size: 24,
        color: _podcastPurple.withValues(alpha: 0.4),
      ),
    );
  }
}
