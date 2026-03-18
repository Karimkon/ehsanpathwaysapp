import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/features/articles/article_provider.dart';
import 'package:ehsan_pathways/shared/widgets/badge_chip.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';

class ArticlesScreen extends ConsumerStatefulWidget {
  const ArticlesScreen({super.key});

  @override
  ConsumerState<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends ConsumerState<ArticlesScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load initial articles after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(articleListProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(articleListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(articleListProvider.notifier).loadInitial(
            search: query.isEmpty ? null : query,
          );
    });
  }

  Future<void> _onRefresh() async {
    final search = _searchController.text.trim();
    await ref.read(articleListProvider.notifier).loadInitial(
          search: search.isEmpty ? null : search,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(articleListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Articles',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // -- Search bar ---------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search articles...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF9CA3AF),
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 22),
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

  Widget _buildBody(ArticleListState state, bool isDark) {
    // Loading state (initial load)
    if (state.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const _ArticleShimmerTile(),
      );
    }

    // Error state
    if (state.error != null && state.articles.isEmpty) {
      return EmptyState(
        icon: Icons.article_outlined,
        title: 'Coming Soon',
        subtitle: 'Articles are being prepared. Check back soon!',
        actionLabel: 'Retry',
        onAction: _onRefresh,
      );
    }

    // Empty state
    if (state.articles.isEmpty) {
      return EmptyState(
        icon: Icons.article_outlined,
        title: 'No articles found',
        subtitle: _searchController.text.isNotEmpty
            ? 'Try a different search term.'
            : 'Check back later for new content.',
        actionLabel: _searchController.text.isNotEmpty ? 'Clear Search' : null,
        onAction: _searchController.text.isNotEmpty
            ? () {
                _searchController.clear();
                _onSearchChanged('');
              }
            : null,
      );
    }

    // Articles list
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.primaryGreen,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: state.articles.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          // Loading more indicator
          if (index >= state.articles.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            );
          }

          final article = state.articles[index];
          return _ArticleListItem(
            article: article,
            isDark: isDark,
            onTap: () => context.push('/articles/${article.slug}'),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Article list item – horizontal card (image left, text right)
// ---------------------------------------------------------------------------

class _ArticleListItem extends StatelessWidget {
  const _ArticleListItem({
    required this.article,
    required this.isDark,
    required this.onTap,
  });

  final Article article;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
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
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -- Thumbnail (left) ------------------------------------------
              SizedBox(
                width: 120,
                child: article.featuredImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: article.featuredImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFE5E7EB),
                          highlightColor: isDark
                              ? const Color(0xFF3A3A3A)
                              : const Color(0xFFF3F4F6),
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFF3F4F6),
                          child: const Icon(
                            Icons.article_outlined,
                            size: 32,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFF3F4F6),
                        child: Center(
                          child: Icon(
                            Icons.article_outlined,
                            size: 36,
                            color: isDark
                                ? Colors.white24
                                : Colors.black26,
                          ),
                        ),
                      ),
              ),

              // -- Text content (right) --------------------------------------
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        article.title,
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

                      const SizedBox(height: 6),

                      // Scholar name
                      if (article.scholar != null)
                        Text(
                          article.scholar!.name,
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

                      const SizedBox(height: 8),

                      // Reading time badge + category chip
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Reading time
                          if (article.readingTimeMinutes != null)
                            BadgeChip(
                              label: '${article.readingTimeMinutes} min read',
                              variant: BadgeVariant.blue,
                              size: BadgeSize.small,
                              icon: Icons.schedule_rounded,
                            ),

                          // Category
                          if (article.category != null)
                            BadgeChip(
                              label: article.category!.name,
                              variant: BadgeVariant.green,
                              size: BadgeSize.small,
                            ),
                        ],
                      ),
                    ],
                  ),
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
// Shimmer placeholder for article list tiles
// ---------------------------------------------------------------------------

class _ArticleShimmerTile extends StatelessWidget {
  const _ArticleShimmerTile();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ShimmerWrap(
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Image placeholder
            ShimmerBox(
              width: 120,
              height: 110,
              borderRadius: 14,
            ),
            const SizedBox(width: 12),
            // Text placeholders
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    ShimmerBox(width: double.infinity, height: 14),
                    SizedBox(height: 6),
                    ShimmerBox(width: 160, height: 14),
                    SizedBox(height: 8),
                    ShimmerBox(width: 100, height: 12),
                    SizedBox(height: 8),
                    ShimmerBox(width: 80, height: 20, borderRadius: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
