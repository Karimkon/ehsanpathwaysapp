import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ehsan_pathways/features/videos/video_provider.dart';
import 'package:ehsan_pathways/shared/widgets/content_card.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';

/// The main videos listing screen.
///
/// Features:
/// - Search bar with debounced input
/// - 2-column grid of video cards using slivers
/// - Infinite scroll pagination
/// - Pull-to-refresh
/// - Shimmer loading placeholders
/// - Empty state when no results
class VideosScreen extends ConsumerStatefulWidget {
  const VideosScreen({super.key});

  @override
  ConsumerState<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends ConsumerState<VideosScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;

  // -- Colours ---------------------------------------------------------------
  static const _primaryGreen = Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load initial data after the first frame so ref is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(videoListProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // -- Infinite scroll -------------------------------------------------------

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    // Trigger load-more when 200px from the bottom.
    if (currentScroll >= maxScroll - 200) {
      ref.read(videoListProvider.notifier).loadMore();
    }
  }

  // -- Search ----------------------------------------------------------------

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(videoListProvider.notifier).loadInitial(
            search: query.trim().isEmpty ? null : query.trim(),
          );
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    ref.read(videoListProvider.notifier).loadInitial();
  }

  // -- Pull-to-refresh -------------------------------------------------------

  Future<void> _onRefresh() async {
    await ref.read(videoListProvider.notifier).loadInitial(
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        );
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(videoListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: _primaryGreen,
        edgeOffset: 130, // offset for the SliverAppBar height
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(isDark),
            _buildSliverBody(state, isDark),
          ],
        ),
      ),
    );
  }

  // -- Sliver App Bar --------------------------------------------------------

  SliverAppBar _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      toolbarHeight: 64,
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryGreen, Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.play_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Videos',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _SearchBar(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _onSearchChanged,
            onClear: _clearSearch,
            isDark: isDark,
          ),
        ),
      ),
    );
  }

  // -- Sliver Body -----------------------------------------------------------

  Widget _buildSliverBody(VideoListState state, bool isDark) {
    // Initial loading
    if (state.isLoading) {
      return const _SliverShimmerGrid();
    }

    // Error state
    if (state.error != null && state.videos.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'Something went wrong',
          subtitle: 'Please check your connection and try again.',
          actionLabel: 'Retry',
          onAction: _onRefresh,
          iconColor: Colors.red.shade400,
        ),
      );
    }

    // Empty state
    if (state.videos.isEmpty) {
      final isSearching = _searchController.text.trim().isNotEmpty;
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: isSearching
              ? Icons.search_off_rounded
              : Icons.play_circle_outline_rounded,
          title: isSearching ? 'No videos found' : 'No videos yet',
          subtitle: isSearching
              ? 'Try different keywords or clear the search.'
              : 'New Islamic knowledge content is coming soon.',
          actionLabel: isSearching ? 'Clear Search' : null,
          onAction: isSearching ? _clearSearch : null,
        ),
      );
    }

    // Video grid with optional load-more indicator at the bottom
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final video = state.videos[index];
                return ContentCard(
                  title: video.title,
                  subtitle: video.scholar?.name,
                  imageUrl: video.thumbnailUrl,
                  contentType: ContentType.video,
                  trailingInfo: video.durationFormatted,
                  trailingIcon: Icons.access_time_rounded,
                  height: 120,
                  onTap: () => context.push('/videos/${video.uuid}'),
                );
              },
              childCount: state.videos.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 14,
              childAspectRatio: 0.68,
            ),
          ),
        ),

        // Loading more indicator
        if (state.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: _primaryGreen,
                  ),
                ),
              ),
            ),
          ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),
      ],
    );
  }
}

// =============================================================================
// PRIVATE WIDGETS
// =============================================================================

// -- Search Bar ---------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.isDark,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF111827),
        ),
        decoration: InputDecoration(
          hintText: 'Search videos...',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          ),
          suffixIcon: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              if (controller.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
                onPressed: onClear,
              );
            },
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// -- Shimmer loading grid (sliver version) ------------------------------------

class _SliverShimmerGrid extends StatelessWidget {
  const _SliverShimmerGrid();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const ShimmerCard(imageHeight: 120),
          childCount: 6,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 14,
          childAspectRatio: 0.68,
        ),
      ),
    );
  }
}
