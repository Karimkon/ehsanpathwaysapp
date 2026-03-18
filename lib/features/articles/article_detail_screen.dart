import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/features/articles/article_provider.dart';
import 'package:ehsan_pathways/features/bookmarks/bookmark_provider.dart';
import 'package:ehsan_pathways/shared/widgets/scholar_avatar.dart';
import 'package:ehsan_pathways/shared/widgets/badge_chip.dart';
import 'package:ehsan_pathways/shared/widgets/section_header.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';

class ArticleDetailScreen extends ConsumerWidget {
  const ArticleDetailScreen({
    super.key,
    required this.slug,
  });

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleAsync = ref.watch(articleDetailProvider(slug));

    return articleAsync.when(
      loading: () => _buildLoadingScaffold(context),
      error: (error, _) => _buildErrorScaffold(context, ref, error),
      data: (article) => _ArticleDetailBody(article: article),
    );
  }

  Widget _buildLoadingScaffold(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsed app bar while loading
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: ShimmerWrap(
                child: Container(color: Colors.white),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const ShimmerWrap(
                  child: ShimmerBox(width: double.infinity, height: 28),
                ),
                const SizedBox(height: 12),
                const ShimmerWrap(
                  child: ShimmerBox(width: 200, height: 28),
                ),
                const SizedBox(height: 20),
                const ShimmerListTile(),
                const SizedBox(height: 16),
                ...List.generate(
                  8,
                  (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: ShimmerWrap(
                      child: ShimmerBox(width: double.infinity, height: 14),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScaffold(BuildContext context, WidgetRef ref, Object error) {
    return Scaffold(
      appBar: AppBar(),
      body: EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Could not load article',
        subtitle: 'Please check your connection and try again.',
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(articleDetailProvider(slug)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main article detail body (shown when data is loaded)
// ---------------------------------------------------------------------------

class _ArticleDetailBody extends ConsumerWidget {
  const _ArticleDetailBody({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('MMMM d, yyyy');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // -- Hero image with gradient overlay + app bar -------------------
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor:
                isDark ? const Color(0xFF121212) : Colors.white,
            foregroundColor: Colors.white,
            actions: [
              // Bookmark button
              _ArticleBookmarkButton(slug: article.slug),
              // Share button
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Share article',
                onPressed: () => _onShare(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  if (article.featuredImageUrl != null)
                    CachedNetworkImage(
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
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryGreen,
                            AppTheme.primaryGreenDark,
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.article_outlined,
                          size: 64,
                          color: Colors.white38,
                        ),
                      ),
                    ),

                  // Gradient overlay for legibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.6),
                        ],
                        stops: const [0.3, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -- Article content below the hero image -------------------------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    article.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // -- Author / Scholar section -----------------------------
                  if (article.scholar != null)
                    Row(
                      children: [
                        ScholarAvatar(
                          name: article.scholar!.name,
                          imageUrl: article.scholar!.avatarUrl,
                          size: ScholarAvatarSize.small,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article.scholar!.name,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                ),
                              ),
                              if (article.publishedAt != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    dateFormat.format(article.publishedAt!),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // -- Reading time + category badges -----------------------
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (article.readingTimeMinutes != null)
                        BadgeChip(
                          label: '${article.readingTimeMinutes} min read',
                          variant: BadgeVariant.blue,
                          icon: Icons.schedule_rounded,
                        ),
                      if (article.category != null)
                        BadgeChip(
                          label: article.category!.name,
                          variant: BadgeVariant.green,
                        ),
                      // Tags
                      ...article.tags.map(
                        (tag) => BadgeChip(
                          label: tag.name,
                          variant: BadgeVariant.gray,
                          size: BadgeSize.small,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // -- Divider -----------------------------------------------
                  Divider(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // -- Article body (HTML) ------------------------------------------
          if (article.content != null && article.content!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Html(
                  data: article.content!,
                  onLinkTap: (url, _, __) {
                    if (url != null) {
                      launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  style: {
                    'body': Style(
                      fontSize: FontSize(16),
                      lineHeight: LineHeight(1.75),
                      color: isDark
                          ? const Color(0xFFD1D5DB)
                          : const Color(0xFF374151),
                      fontFamily: GoogleFonts.inter().fontFamily,
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                    ),
                    'h1': Style(
                      fontSize: FontSize(24),
                      fontWeight: FontWeight.w800,
                      fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                      margin: Margins.only(top: 24, bottom: 12),
                    ),
                    'h2': Style(
                      fontSize: FontSize(20),
                      fontWeight: FontWeight.w700,
                      fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                      margin: Margins.only(top: 20, bottom: 10),
                    ),
                    'h3': Style(
                      fontSize: FontSize(18),
                      fontWeight: FontWeight.w700,
                      fontFamily: GoogleFonts.inter().fontFamily,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                      margin: Margins.only(top: 18, bottom: 8),
                    ),
                    'p': Style(
                      margin: Margins.only(bottom: 14),
                    ),
                    'a': Style(
                      color: AppTheme.primaryGreen,
                      textDecoration: TextDecoration.underline,
                    ),
                    'blockquote': Style(
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                      border: Border(
                        left: BorderSide(
                          color: AppTheme.accentGold,
                          width: 3,
                        ),
                      ),
                      padding: HtmlPaddings.only(left: 14),
                      margin: Margins.only(top: 16, bottom: 16),
                    ),
                    'img': Style(
                      margin: Margins.symmetric(vertical: 12),
                    ),
                    'ul': Style(
                      margin: Margins.only(bottom: 14),
                    ),
                    'ol': Style(
                      margin: Margins.only(bottom: 14),
                    ),
                    'li': Style(
                      margin: Margins.only(bottom: 6),
                    ),
                    'code': Style(
                      backgroundColor: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF3F4F6),
                      padding: HtmlPaddings.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      fontSize: FontSize(14),
                    ),
                  },
                ),
              ),
            ),

          // -- Related articles section -------------------------------------
          if (article.relatedArticles.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Divider(
                    indent: 20,
                    endIndent: 20,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                  SectionHeader(
                    title: 'Related Articles',
                    subtitle: 'Continue your reading',
                  ),
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: article.relatedArticles.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final related = article.relatedArticles[index];
                        return _RelatedArticleCard(
                          article: related,
                          isDark: isDark,
                          onTap: () => context.push('/articles/${related.slug}'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Bottom spacing
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  void _onShare(BuildContext context) {
    final url = 'https://ehsanpathways.com/articles/${article.slug}';
    Share.share('${article.title}\n\n$url', subject: article.title);
  }
}

// ---------------------------------------------------------------------------
// Related article card (compact horizontal card)
// ---------------------------------------------------------------------------

class _RelatedArticleCard extends StatelessWidget {
  const _RelatedArticleCard({
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
        width: 200,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            SizedBox(
              height: 110,
              width: double.infinity,
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
                        child: const Icon(Icons.article_outlined,
                            size: 28, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF3F4F6),
                      child: const Center(
                        child: Icon(Icons.article_outlined,
                            size: 28, color: Colors.grey),
                      ),
                    ),
            ),

            // Text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    if (article.readingTimeMinutes != null)
                      Text(
                        '${article.readingTimeMinutes} min read',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                        ),
                      ),
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

// ---------------------------------------------------------------------------
// Bookmark button for article detail
// ---------------------------------------------------------------------------

class _ArticleBookmarkButton extends ConsumerStatefulWidget {
  const _ArticleBookmarkButton({required this.slug});

  final String slug;

  @override
  ConsumerState<_ArticleBookmarkButton> createState() =>
      _ArticleBookmarkButtonState();
}

class _ArticleBookmarkButtonState
    extends ConsumerState<_ArticleBookmarkButton> {
  bool _isBookmarked = false;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final result = await ref.read(
        isBookmarkedProvider((type: 'article', id: widget.slug)).future,
      );
      if (mounted) setState(() => _isBookmarked = result);
    } catch (_) {}
  }

  Future<void> _toggle() async {
    if (_isToggling) return;
    setState(() => _isToggling = true);

    final result = await ref
        .read(bookmarkListProvider.notifier)
        .toggleBookmark('article', widget.slug);

    if (mounted) {
      setState(() {
        _isBookmarked = result;
        _isToggling = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result ? 'Bookmarked!' : 'Bookmark removed',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _toggle,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Icon(
          _isBookmarked
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          key: ValueKey(_isBookmarked),
          color: _isBookmarked
              ? const Color(0xFFF59E0B)
              : Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
