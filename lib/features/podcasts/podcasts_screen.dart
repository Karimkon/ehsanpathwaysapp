import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import 'package:ehsan_pathways/features/podcasts/podcast_provider.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';
import 'package:ehsan_pathways/shared/widgets/badge_chip.dart';

// ---------------------------------------------------------------------------
// Colour constants -- purple-tinted accent for the podcast section
// ---------------------------------------------------------------------------

const Color _podcastPurple = Color(0xFF8B5CF6);
const Color _podcastPurpleLight = Color(0xFFA78BFA);
const Color _podcastPurpleDark = Color(0xFF7C3AED);
const Color _primaryGreen = Color(0xFF16A34A);

// ---------------------------------------------------------------------------
// Podcasts Screen
// ---------------------------------------------------------------------------

class PodcastsScreen extends ConsumerStatefulWidget {
  const PodcastsScreen({super.key});

  @override
  ConsumerState<PodcastsScreen> createState() => _PodcastsScreenState();
}

class _PodcastsScreenState extends ConsumerState<PodcastsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Kick off initial load after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(podcastListProvider.notifier).loadInitial();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(podcastListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(podcastListProvider.notifier).loadInitial(
            search: query.trim().isEmpty ? null : query.trim(),
          );
    });
  }

  Future<void> _onRefresh() async {
    final search = _searchController.text.trim();
    await ref.read(podcastListProvider.notifier).loadInitial(
          search: search.isEmpty ? null : search,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(podcastListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _podcastPurple.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.headphones_rounded,
                color: _podcastPurple,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Podcasts',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // -- Search bar ---------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
              decoration: InputDecoration(
                hintText: 'Search podcasts...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _podcastPurple.withValues(alpha: 0.7),
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _podcastPurple.withValues(alpha: isDark ? 0.15 : 0.1),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _podcastPurple.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // -- Content area -------------------------------------------------
          Expanded(
            child: _buildBody(state, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(PodcastListState state, bool isDark) {
    // Initial loading
    if (state.isLoading) {
      return const _PodcastShimmerList();
    }

    // Error
    if (state.error != null && state.podcasts.isEmpty) {
      return EmptyState(
        icon: Icons.headphones_rounded,
        title: 'Coming Soon',
        subtitle: 'Podcasts are being prepared. Check back soon!',
        actionLabel: 'Retry',
        onAction: _onRefresh,
        iconColor: _podcastPurple,
      );
    }

    // Empty
    if (state.podcasts.isEmpty) {
      return EmptyState(
        icon: Icons.headphones_rounded,
        title: 'No podcasts found',
        subtitle: _searchController.text.isNotEmpty
            ? 'Try a different search term.'
            : 'Check back later for new episodes.',
        iconColor: _podcastPurple,
        actionLabel: _searchController.text.isNotEmpty ? 'Clear Search' : null,
        onAction: _searchController.text.isNotEmpty
            ? () {
                _searchController.clear();
                _onSearchChanged('');
              }
            : null,
      );
    }

    // List
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: _podcastPurple,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: state.podcasts.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.podcasts.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: _podcastPurple,
                  ),
                ),
              ),
            );
          }

          final podcast = state.podcasts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PodcastListItem(
              podcast: podcast,
              onTap: () {
                context.push('/podcasts/${podcast.slug}');
              },
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Podcast List Item -- horizontal card with album art + info + play button
// ---------------------------------------------------------------------------

class _PodcastListItem extends StatefulWidget {
  const _PodcastListItem({
    required this.podcast,
    this.onTap,
  });

  final Podcast podcast;
  final VoidCallback? onTap;

  @override
  State<_PodcastListItem> createState() => _PodcastListItemState();
}

class _PodcastListItemState extends State<_PodcastListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final podcast = widget.podcast;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _controller.reverse(),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _podcastPurple.withValues(alpha: isDark ? 0.1 : 0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : _podcastPurple.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // -- Cover image (80x80, rounded) ----------------------------
              _CoverImage(
                imageUrl: podcast.coverImageUrl,
                isDark: isDark,
              ),
              const SizedBox(width: 14),

              // -- Text info -----------------------------------------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Series badge
                    if (podcast.series != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: BadgeChip(
                          label: podcast.series!.title,
                          variant: BadgeVariant.purple,
                          size: BadgeSize.small,
                          icon: Icons.album_rounded,
                        ),
                      ),

                    // Title
                    Text(
                      podcast.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Scholar name
                    if (podcast.scholar != null)
                      Text(
                        podcast.scholar!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    const SizedBox(height: 6),

                    // Duration + episode number
                    Row(
                      children: [
                        Icon(
                          Icons.headphones_rounded,
                          size: 14,
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
                          const SizedBox(width: 10),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFF9CA3AF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Ep. ${podcast.episodeNumber}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
              const SizedBox(width: 10),

              // -- Play button ---------------------------------------------
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_podcastPurpleLight, _podcastPurpleDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _podcastPurple.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
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
// Cover image (square, 80x80, rounded)
// ---------------------------------------------------------------------------

class _CoverImage extends StatelessWidget {
  const _CoverImage({
    this.imageUrl,
    required this.isDark,
  });

  final String? imageUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              width: 80,
              height: 80,
              placeholder: (_, __) => Shimmer.fromColors(
                baseColor:
                    isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB),
                highlightColor:
                    isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF3F4F6),
                child: Container(color: Colors.white),
              ),
              errorWidget: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _podcastPurple.withValues(alpha: isDark ? 0.25 : 0.15),
            _podcastPurple.withValues(alpha: isDark ? 0.10 : 0.05),
          ],
        ),
      ),
      child: Icon(
        Icons.headphones_rounded,
        size: 32,
        color: _podcastPurple.withValues(alpha: 0.5),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer loading list (matches podcast list-item shape)
// ---------------------------------------------------------------------------

class _PodcastShimmerList extends StatelessWidget {
  const _PodcastShimmerList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: 8,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerWrap(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Cover placeholder
                const ShimmerBox(
                  width: 80,
                  height: 80,
                  borderRadius: 12,
                ),
                const SizedBox(width: 14),
                // Text placeholders
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(width: 80, height: 10, borderRadius: 6),
                      SizedBox(height: 8),
                      ShimmerBox(
                          width: double.infinity, height: 14, borderRadius: 6),
                      SizedBox(height: 6),
                      ShimmerBox(width: 140, height: 14, borderRadius: 6),
                      SizedBox(height: 8),
                      ShimmerBox(width: 100, height: 10, borderRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Play button placeholder
                const ShimmerBox(width: 40, height: 40, borderRadius: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
