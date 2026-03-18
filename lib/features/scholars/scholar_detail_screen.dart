import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/shared/widgets/content_card.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';
import 'package:ehsan_pathways/features/scholars/scholar_provider.dart';

/// Detailed view for a single scholar: hero photo, bio, and tabbed content.
class ScholarDetailScreen extends ConsumerWidget {
  const ScholarDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scholarAsync = ref.watch(scholarDetailProvider(slug));

    return Scaffold(
      body: scholarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Failed to load scholar',
          subtitle: error.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(scholarDetailProvider(slug)),
        ),
        data: (scholar) => _ScholarDetailBody(scholar: scholar, slug: slug),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail Body (NestedScrollView with tabs)
// ---------------------------------------------------------------------------

class _ScholarDetailBody extends ConsumerStatefulWidget {
  const _ScholarDetailBody({required this.scholar, required this.slug});

  final Scholar scholar;
  final String slug;

  @override
  ConsumerState<_ScholarDetailBody> createState() =>
      _ScholarDetailBodyState();
}

class _ScholarDetailBodyState extends ConsumerState<_ScholarDetailBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scholar = widget.scholar;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          // ----------------------------------------------------------------
          // Hero image with gradient overlay
          // ----------------------------------------------------------------
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: _CircularBackButton(isDark: isDark),
            backgroundColor:
                isDark ? const Color(0xFF121212) : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo
                  if (scholar.photoUrl != null &&
                      scholar.photoUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: scholar.photoUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          _placeholderGradient(scholar.name),
                    )
                  else
                    _placeholderGradient(scholar.name),

                  // Bottom gradient for readability
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Name and title overlay at bottom
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (scholar.title != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGold
                                  .withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              scholar.title!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        Text(
                          scholar.name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ----------------------------------------------------------------
          // Stats row
          // ----------------------------------------------------------------
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                    icon: Icons.play_circle_rounded,
                    label: 'Videos',
                    count: scholar.videoCount,
                    color: const Color(0xFF3B82F6),
                    isDark: isDark,
                  ),
                  _divider(isDark),
                  _StatItem(
                    icon: Icons.article_rounded,
                    label: 'Articles',
                    count: scholar.articleCount,
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                  _divider(isDark),
                  _StatItem(
                    icon: Icons.headphones_rounded,
                    label: 'Podcasts',
                    count: scholar.podcastCount,
                    color: const Color(0xFF8B5CF6),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),

          // ----------------------------------------------------------------
          // Bio section
          // ----------------------------------------------------------------
          if (scholar.bio != null && scholar.bio!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scholar.bio!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
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

          // ----------------------------------------------------------------
          // Tab bar
          // ----------------------------------------------------------------
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabController: _tabController,
              isDark: isDark,
            ),
          ),
        ];
      },

      // ----------------------------------------------------------------
      // Tab content
      // ----------------------------------------------------------------
      body: TabBarView(
        controller: _tabController,
        children: [
          _ContentTab(
            provider: scholarVideosProvider(widget.slug),
            emptyIcon: Icons.play_circle_outline_rounded,
            emptyTitle: 'No videos yet',
            contentType: ContentType.video,
            onItemTap: (item) => context.push('/videos/${item.identifier}'),
          ),
          _ContentTab(
            provider: scholarArticlesProvider(widget.slug),
            emptyIcon: Icons.article_outlined,
            emptyTitle: 'No articles yet',
            contentType: ContentType.article,
            onItemTap: (item) =>
                context.push('/articles/${item.identifier}'),
          ),
          _ContentTab(
            provider: scholarPodcastsProvider(widget.slug),
            emptyIcon: Icons.headphones_rounded,
            emptyTitle: 'No podcasts yet',
            contentType: ContentType.podcast,
            onItemTap: (item) =>
                context.push('/podcasts/${item.identifier}'),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      width: 1,
      height: 36,
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06),
    );
  }

  static Widget _placeholderGradient(String name) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF16A34A),
            Color(0xFF059669),
            Color(0xFF14532D),
          ],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.inter(
            fontSize: 80,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat Item
// ---------------------------------------------------------------------------

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark
                ? const Color(0xFF9CA3AF)
                : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Circular back button
// ---------------------------------------------------------------------------

class _CircularBackButton extends StatelessWidget {
  const _CircularBackButton({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          iconSize: 22,
          onPressed: () => context.pop(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab bar delegate for SliverPersistentHeader
// ---------------------------------------------------------------------------

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate({
    required this.tabController,
    required this.isDark,
  });

  final TabController tabController;
  final bool isDark;

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? const Color(0xFF121212) : AppTheme.surfaceLight,
      child: TabBar(
        controller: tabController,
        labelColor: AppTheme.primaryGreen,
        unselectedLabelColor:
            isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
        indicatorColor: AppTheme.primaryGreen,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Videos'),
          Tab(text: 'Articles'),
          Tab(text: 'Podcasts'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Content Tab (Videos / Articles / Podcasts)
// ---------------------------------------------------------------------------

class _ContentTab extends ConsumerWidget {
  const _ContentTab({
    required this.provider,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.contentType,
    required this.onItemTap,
  });

  final FutureProvider<List<ScholarContentItem>> provider;
  final IconData emptyIcon;
  final String emptyTitle;
  final ContentType contentType;
  final void Function(ScholarContentItem) onItemTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(provider);

    return asyncItems.when(
      loading: () => const SingleChildScrollView(
        child: ShimmerList(itemCount: 5),
      ),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Failed to load content',
        subtitle: error.toString(),
        compact: true,
      ),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: emptyIcon,
            title: emptyTitle,
            subtitle: 'Check back later for new content.',
            compact: true,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final item = items[index];
            return ContentCard(
              title: item.title,
              imageUrl: item.imageUrl,
              contentType: contentType,
              trailingInfo: item.duration,
              trailingIcon: contentType == ContentType.video
                  ? Icons.access_time_rounded
                  : contentType == ContentType.podcast
                      ? Icons.access_time_rounded
                      : Icons.menu_book_rounded,
              onTap: () => onItemTap(item),
            );
          },
        );
      },
    );
  }
}
