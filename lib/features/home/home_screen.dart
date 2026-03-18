import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:ehsan_pathways/features/home/home_provider.dart';
import 'package:ehsan_pathways/shared/widgets/content_card.dart';
import 'package:ehsan_pathways/shared/widgets/section_header.dart';
import 'package:ehsan_pathways/shared/widgets/scholar_avatar.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const Color _primaryGreen = Color(0xFF16A34A);
const Color _primaryGreenDark = Color(0xFF15803D);
const Color _accentGold = Color(0xFFF59E0B);

// ---------------------------------------------------------------------------
// HomeScreen
// ---------------------------------------------------------------------------

/// The main landing screen of EhsanPathways.
///
/// Displays a warm Islamic greeting, a featured video hero card, browsable
/// categories, and horizontal carousels for recent videos, articles, podcasts,
/// and featured scholars.  Built with love, for the sake of Allah.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeDataProvider);

    return Scaffold(
      body: homeAsync.when(
        loading: () => const _HomeShimmer(),
        error: (error, _) => _HomeError(
          message: error.toString(),
          onRetry: () => ref.invalidate(homeDataProvider),
        ),
        data: (data) => _HomeContent(data: data),
      ),
    );
  }
}

// ===========================================================================
// Main content body (loaded state)
// ===========================================================================

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.data});

  final HomeData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      color: _primaryGreen,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      displacement: 60,
      onRefresh: () async {
        ref.invalidate(homeDataProvider);
        // Wait for the new future to settle so the spinner feels natural.
        await ref.read(homeDataProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // -- App bar -------------------------------------------------------
          _SliverAppBar(isDark: isDark),

          // -- Greeting ------------------------------------------------------
          SliverToBoxAdapter(child: _GreetingBanner(isDark: isDark)),

          // -- Quick Actions -------------------------------------------------
          SliverToBoxAdapter(child: _QuickActions(isDark: isDark)),

          // -- Daily Hadith --------------------------------------------------
          SliverToBoxAdapter(child: _DailyHadithCard(isDark: isDark)),

          // -- Featured Video ------------------------------------------------
          if (data.featuredVideo != null)
            SliverToBoxAdapter(
              child: _FeaturedVideoHero(
                video: data.featuredVideo!,
                isDark: isDark,
              ),
            ),

          // -- Categories ----------------------------------------------------
          if (data.categories.isNotEmpty)
            SliverToBoxAdapter(
              child: _CategoriesRow(categories: data.categories),
            ),

          // -- Recent Videos -------------------------------------------------
          if (data.recentVideos.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Recent Videos',
                subtitle: 'Continue your learning journey',
                onTrailingTap: () => context.push('/videos'),
              ),
            ),
            SliverToBoxAdapter(
              child: _VideosCarousel(videos: data.recentVideos),
            ),
          ],

          // -- Recent Articles -----------------------------------------------
          if (data.recentArticles.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Recent Articles',
                subtitle: 'Read and reflect',
                onTrailingTap: () => context.push('/articles'),
              ),
            ),
            SliverToBoxAdapter(
              child: _ArticlesCarousel(articles: data.recentArticles),
            ),
          ],

          // -- Recent Podcasts -----------------------------------------------
          if (data.recentPodcasts.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Recent Podcasts',
                subtitle: 'Listen on the go',
                onTrailingTap: () => context.push('/podcasts'),
              ),
            ),
            SliverToBoxAdapter(
              child: _PodcastsCarousel(podcasts: data.recentPodcasts),
            ),
          ],

          // -- Scholars ------------------------------------------------------
          if (data.scholars.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Featured Scholars',
                subtitle: 'Learn from the best',
                onTrailingTap: () => context.push('/scholars'),
              ),
            ),
            SliverToBoxAdapter(
              child: _ScholarsRow(scholars: data.scholars),
            ),
          ],

          // -- Daily Dua -----------------------------------------------------
          SliverToBoxAdapter(child: _DailyDuaCard(isDark: isDark)),

          // -- Islamic Quote -------------------------------------------------
          SliverToBoxAdapter(child: _IslamicQuoteSection(isDark: isDark)),

          // -- Bottom spacing ------------------------------------------------
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ===========================================================================
// Custom Sliver App Bar
// ===========================================================================

class _SliverAppBar extends StatelessWidget {
  const _SliverAppBar({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 64,
      title: Row(
        children: [
          // Decorative crescent / brand mark
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryGreen, _primaryGreenDark],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Ehsan Pathways',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: () => context.push('/search'),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : _primaryGreen.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              Icons.search_rounded,
              color: isDark ? Colors.white70 : _primaryGreen,
              size: 22,
            ),
          ),
        ),
      ],
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    );
  }
}

// ===========================================================================
// Islamic Greeting Banner
// ===========================================================================

class _GreetingBanner extends StatelessWidget {
  const _GreetingBanner({required this.isDark});

  final bool isDark;

  /// Returns a time-appropriate Islamic greeting and subtitle.
  ({String greeting, String subtitle, IconData icon}) get _timeGreeting {
    final hour = DateTime.now().hour;

    if (hour >= 3 && hour < 12) {
      return (
        greeting: 'Sabah al-Khair',
        subtitle: 'Start your morning with knowledge and remembrance.',
        icon: Icons.wb_sunny_rounded,
      );
    } else if (hour >= 12 && hour < 15) {
      return (
        greeting: 'Good Afternoon',
        subtitle: 'Take a moment to learn something beneficial.',
        icon: Icons.wb_sunny_rounded,
      );
    } else if (hour >= 15 && hour < 18) {
      return (
        greeting: 'Masa al-Khair',
        subtitle: 'Reflect and grow as the day winds down.',
        icon: Icons.wb_twilight_rounded,
      );
    } else {
      return (
        greeting: 'Good Evening',
        subtitle: 'End your day with beneficial knowledge.',
        icon: Icons.nightlight_round,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _timeGreeting;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    _primaryGreen.withValues(alpha: 0.15),
                    _primaryGreenDark.withValues(alpha: 0.08),
                  ]
                : [
                    _primaryGreen.withValues(alpha: 0.06),
                    _accentGold.withValues(alpha: 0.04),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? _primaryGreen.withValues(alpha: 0.12)
                : _primaryGreen.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assalamu Alaikum',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info.greeting,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _primaryGreen,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    info.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primaryGreen, _primaryGreenDark],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primaryGreen.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                info.icon,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Featured Video Hero
// ===========================================================================

class _FeaturedVideoHero extends StatelessWidget {
  const _FeaturedVideoHero({required this.video, required this.isDark});

  final FeaturedVideo video;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: GestureDetector(
        onTap: () => context.push('/videos/${video.uuid}'),
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.5)
                    : _primaryGreen.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // -- Background image -------------------------------------------
              if (video.thumbnailUrl != null)
                CachedNetworkImage(
                  imageUrl: video.thumbnailUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFE5E7EB),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_primaryGreen, _primaryGreenDark],
                      ),
                    ),
                    child: const Icon(
                      Icons.play_circle_outline_rounded,
                      size: 64,
                      color: Colors.white38,
                    ),
                  ),
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_primaryGreen, _primaryGreenDark],
                    ),
                  ),
                ),

              // -- Gradient overlay -------------------------------------------
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.4, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),

              // -- "Featured" badge -------------------------------------------
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_accentGold, Color(0xFFFBBF24)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _accentGold.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'Featured',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // -- Duration badge ---------------------------------------------
              if (video.formattedDuration.isNotEmpty)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 13, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          video.formattedDuration,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // -- Play button (center) ---------------------------------------
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 36,
                    color: _primaryGreen,
                  ),
                ),
              ),

              // -- Title + scholar (bottom) -----------------------------------
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              video.scholar.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
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

// ===========================================================================
// Categories Row
// ===========================================================================

class _CategoriesRow extends StatelessWidget {
  const _CategoriesRow({required this.categories});

  final List<CategorySummary> categories;

  /// Maps a category icon string (from the API) to a Flutter IconData.
  /// Falls back to a generic icon when the value is unrecognised.
  static IconData _resolveIcon(String? icon) {
    const map = <String, IconData>{
      'quran': Icons.menu_book_rounded,
      'hadith': Icons.auto_stories_rounded,
      'fiqh': Icons.gavel_rounded,
      'aqeedah': Icons.shield_rounded,
      'seerah': Icons.history_edu_rounded,
      'tafsir': Icons.chrome_reader_mode_rounded,
      'dawah': Icons.campaign_rounded,
      'family': Icons.family_restroom_rounded,
      'youth': Icons.school_rounded,
      'spirituality': Icons.self_improvement_rounded,
      'history': Icons.account_balance_rounded,
      'khutbah': Icons.mosque_rounded,
      'lecture': Icons.mic_rounded,
      'qa': Icons.question_answer_rounded,
      'arabic': Icons.translate_rounded,
      'ethics': Icons.favorite_rounded,
      'finance': Icons.account_balance_wallet_rounded,
    };
    if (icon == null) return Icons.category_rounded;
    return map[icon.toLowerCase()] ?? Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Explore Topics',
          subtitle: 'Browse by category',
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return _CategoryChip(
                name: cat.name,
                icon: _resolveIcon(cat.icon),
                isDark: isDark,
                onTap: () => context.push('/videos'), // TODO: filter by category
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.name,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? _primaryGreen.withValues(alpha: 0.12)
                    : _primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? _primaryGreen.withValues(alpha: 0.2)
                      : _primaryGreen.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(
                icon,
                size: 26,
                color: _primaryGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Videos Carousel
// ===========================================================================

class _VideosCarousel extends StatelessWidget {
  const _VideosCarousel({required this.videos});

  final List<VideoSummary> videos;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 248,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.none,
        itemCount: videos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final v = videos[index];
          return SizedBox(
            width: 220,
            child: ContentCard(
              title: v.title,
              subtitle: v.scholar.name,
              imageUrl: v.thumbnailUrl,
              contentType: ContentType.video,
              trailingInfo: v.formattedDuration.isNotEmpty
                  ? v.formattedDuration
                  : null,
              trailingIcon: v.formattedDuration.isNotEmpty
                  ? Icons.schedule_rounded
                  : null,
              height: 130,
              onTap: () => context.push('/videos/${v.uuid}'),
            ),
          );
        },
      ),
    );
  }
}

// ===========================================================================
// Articles Carousel
// ===========================================================================

class _ArticlesCarousel extends StatelessWidget {
  const _ArticlesCarousel({required this.articles});

  final List<ArticleSummary> articles;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 248,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.none,
        itemCount: articles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final a = articles[index];
          final readTime = a.readingTimeMinutes != null
              ? '${a.readingTimeMinutes} min read'
              : null;
          return SizedBox(
            width: 220,
            child: ContentCard(
              title: a.title,
              subtitle: a.scholar.name,
              imageUrl: a.featuredImageUrl,
              contentType: ContentType.article,
              trailingInfo: readTime,
              trailingIcon:
                  readTime != null ? Icons.menu_book_rounded : null,
              height: 130,
              onTap: () => context.push('/articles/${a.slug}'),
            ),
          );
        },
      ),
    );
  }
}

// ===========================================================================
// Podcasts Carousel
// ===========================================================================

class _PodcastsCarousel extends StatelessWidget {
  const _PodcastsCarousel({required this.podcasts});

  final List<PodcastSummary> podcasts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 248,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.none,
        itemCount: podcasts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final p = podcasts[index];
          return SizedBox(
            width: 220,
            child: ContentCard(
              title: p.title,
              subtitle: p.scholar.name,
              imageUrl: p.coverImageUrl,
              contentType: ContentType.podcast,
              trailingInfo: p.formattedDuration.isNotEmpty
                  ? p.formattedDuration
                  : null,
              trailingIcon: p.formattedDuration.isNotEmpty
                  ? Icons.headphones_rounded
                  : null,
              height: 130,
              onTap: () => context.push('/podcasts/${p.slug}'),
            ),
          );
        },
      ),
    );
  }
}

// ===========================================================================
// Scholars Row
// ===========================================================================

class _ScholarsRow extends StatelessWidget {
  const _ScholarsRow({required this.scholars});

  final List<ScholarSummary> scholars;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.none,
        itemCount: scholars.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final s = scholars[index];
          return SizedBox(
            width: 90,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScholarAvatar(
                  name: s.name,
                  imageUrl: s.photoUrl,
                  size: ScholarAvatarSize.large,
                  onTap: () => context.push('/scholars/${s.slug}'),
                ),
                const SizedBox(height: 10),
                Text(
                  s.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                    height: 1.2,
                  ),
                ),
                if (s.videoCount != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${s.videoCount} videos',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ===========================================================================
// Quick Actions Row
// ===========================================================================

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          _QuickActionItem(
            icon: Icons.route_rounded,
            label: 'Pathways',
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
            onTap: () => context.push('/pathways'),
          ),
          const SizedBox(width: 10),
          _QuickActionItem(
            icon: Icons.bookmark_rounded,
            label: 'Bookmarks',
            color: const Color(0xFF3B82F6),
            isDark: isDark,
            onTap: () => context.push('/bookmarks'),
          ),
          const SizedBox(width: 10),
          _QuickActionItem(
            icon: Icons.note_alt_rounded,
            label: 'Notes',
            color: const Color(0xFF10B981),
            isDark: isDark,
            onTap: () => context.push('/notes'),
          ),
          const SizedBox(width: 10),
          _QuickActionItem(
            icon: Icons.people_rounded,
            label: 'Scholars',
            color: _accentGold,
            isDark: isDark,
            onTap: () => context.push('/scholars'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? color.withValues(alpha: 0.1)
                : color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.15 : 0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? color.withValues(alpha: 0.9)
                      : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Shimmer Loading State
// ===========================================================================

class _HomeShimmer extends StatelessWidget {
  const _HomeShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // App bar shimmer
            ShimmerWrap(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: const [
                    ShimmerBox(width: 36, height: 36, borderRadius: 10),
                    SizedBox(width: 12),
                    ShimmerBox(width: 160, height: 24, borderRadius: 8),
                    Spacer(),
                    ShimmerBox(width: 40, height: 40, borderRadius: 12),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Greeting shimmer
            ShimmerWrap(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ShimmerBox(
                  width: double.infinity,
                  height: 110,
                  borderRadius: 20,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Hero shimmer
            ShimmerWrap(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ShimmerBox(
                  width: double.infinity,
                  height: 220,
                  borderRadius: 20,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Categories shimmer
            ShimmerWrap(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerBox(width: 140, height: 20, borderRadius: 8),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 84,
                      child: Row(
                        children: List.generate(
                          4,
                          (_) => Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: const [
                                ShimmerBox(
                                    width: 56, height: 56, borderRadius: 16),
                                SizedBox(height: 8),
                                ShimmerBox(
                                    width: 50, height: 10, borderRadius: 4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Section header shimmer
            ShimmerWrap(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: const [
                    ShimmerBox(width: 140, height: 20, borderRadius: 8),
                    Spacer(),
                    ShimmerBox(width: 70, height: 28, borderRadius: 14),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Carousel shimmer
            const ShimmerHorizontalList(
              itemCount: 3,
              cardWidth: 220,
              imageHeight: 130,
              height: 248,
            ),

            const SizedBox(height: 20),

            // Another section shimmer
            ShimmerWrap(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: const [
                    ShimmerBox(width: 140, height: 20, borderRadius: 8),
                    Spacer(),
                    ShimmerBox(width: 70, height: 28, borderRadius: 14),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            const ShimmerHorizontalList(
              itemCount: 3,
              cardWidth: 220,
              imageHeight: 130,
              height: 248,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Error State
// ===========================================================================

class _HomeError extends StatelessWidget {
  const _HomeError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Unable to Load',
          subtitle:
              'We could not fetch the latest content. Please check your connection and try again.',
          actionLabel: 'Retry',
          onAction: onRetry,
        ),
      ),
    );
  }
}

// ===========================================================================
// Daily Hadith Card
// ===========================================================================

class _DailyHadithCard extends StatelessWidget {
  const _DailyHadithCard({required this.isDark});

  final bool isDark;

  // Rotating collection of beautiful hadith/quotes
  static const _hadithCollection = [
    (
      arabic: 'مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ طَرِيقًا إِلَى الْجَنَّةِ',
      english: 'Whoever takes a path seeking knowledge, Allah will make easy for him a path to Paradise.',
      source: 'Sahih Muslim',
    ),
    (
      arabic: 'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ',
      english: 'The best of you are those who learn the Quran and teach it.',
      source: 'Sahih al-Bukhari',
    ),
    (
      arabic: 'طَلَبُ الْعِلْمِ فَرِيضَةٌ عَلَى كُلِّ مُسْلِمٍ',
      english: 'Seeking knowledge is an obligation upon every Muslim.',
      source: 'Sunan Ibn Majah',
    ),
    (
      arabic: 'إِنَّ اللَّهَ يُحِبُّ إِذَا عَمِلَ أَحَدُكُمْ عَمَلًا أَنْ يُتْقِنَهُ',
      english: 'Indeed, Allah loves that when one of you does a deed, he does it with excellence (ihsan).',
      source: 'Al-Bayhaqi',
    ),
    (
      arabic: 'الدَّالُّ عَلَى الْخَيْرِ كَفَاعِلِهِ',
      english: 'The one who guides to good is like the one who does it.',
      source: 'Sahih Muslim',
    ),
    (
      arabic: 'بَلِّغُوا عَنِّي وَلَوْ آيَةً',
      english: 'Convey from me, even if it is one verse.',
      source: 'Sahih al-Bukhari',
    ),
    (
      arabic: 'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ',
      english: 'Actions are judged by intentions.',
      source: 'Sahih al-Bukhari & Muslim',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Pick a hadith based on day of year for daily rotation
    final dayIndex = DateTime.now().difference(DateTime(2026)).inDays;
    final hadith = _hadithCollection[dayIndex % _hadithCollection.length];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF14532D).withValues(alpha: 0.6),
                    const Color(0xFF052E16).withValues(alpha: 0.4),
                  ]
                : [
                    const Color(0xFF052E16),
                    const Color(0xFF14532D),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withValues(alpha: isDark ? 0.15 : 0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _accentGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    size: 18,
                    color: _accentGold,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Daily Hadith',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _accentGold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hadith.source,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Arabic text
            Text(
              hadith.arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFCD34D),
                height: 1.8,
              ),
            ),
            const SizedBox(height: 12),

            // Divider
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _accentGold.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // English translation
            Text(
              '"${hadith.english}"',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Daily Dua Card
// ===========================================================================

class _DailyDuaCard extends StatelessWidget {
  const _DailyDuaCard({required this.isDark});

  final bool isDark;

  static const _duaCollection = [
    (
      arabic: 'رَبِّ زِدْنِي عِلْمًا',
      english: 'My Lord, increase me in knowledge.',
      reference: 'Quran 20:114',
      occasion: 'Before studying',
    ),
    (
      arabic: 'اللَّهُمَّ انْفَعْنِي بِمَا عَلَّمْتَنِي وَعَلِّمْنِي مَا يَنْفَعُنِي',
      english: 'O Allah, benefit me with what You have taught me, and teach me that which will benefit me.',
      reference: 'An-Nasa\'i',
      occasion: 'Seeking knowledge',
    ),
    (
      arabic: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      english: 'Our Lord, give us good in this world and good in the Hereafter, and protect us from the torment of the Fire.',
      reference: 'Quran 2:201',
      occasion: 'General supplication',
    ),
    (
      arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا طَيِّبًا وَعَمَلًا مُتَقَبَّلًا',
      english: 'O Allah, I ask You for beneficial knowledge, good provision, and accepted deeds.',
      reference: 'Ibn Majah',
      occasion: 'After Fajr prayer',
    ),
    (
      arabic: 'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي',
      english: 'My Lord, expand my chest and ease my affair for me.',
      reference: 'Quran 20:25-26',
      occasion: 'Before a difficult task',
    ),
    (
      arabic: 'حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ',
      english: 'Allah is sufficient for me; there is no deity except Him. On Him I have relied.',
      reference: 'Quran 9:129',
      occasion: 'When anxious',
    ),
    (
      arabic: 'اللَّهُمَّ اجْعَلْ فِي قَلْبِي نُورًا وَفِي لِسَانِي نُورًا',
      english: 'O Allah, place light in my heart and light on my tongue.',
      reference: 'Muslim',
      occasion: 'Seeking guidance',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final dayIndex =
        DateTime.now().difference(DateTime(2026)).inDays.abs() + 3;
    final dua = _duaCollection[dayIndex % _duaCollection.length];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? _accentGold.withValues(alpha: 0.12)
                : _accentGold.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : _accentGold.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _accentGold.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.wb_sunny_rounded,
                      size: 15, color: _accentGold),
                ),
                const SizedBox(width: 8),
                Text(
                  'Daily Dua',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _accentGold,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    dua.occasion,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Arabic
            Text(
              dua.arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFFCD34D)
                    : const Color(0xFF92400E),
                height: 1.7,
              ),
            ),
            const SizedBox(height: 8),

            // English
            Text(
              dua.english,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: isDark
                    ? const Color(0xFFD1D5DB)
                    : const Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),

            // Reference
            Text(
              dua.reference,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Islamic Quote Section (bottom of home)
// ===========================================================================

class _IslamicQuoteSection extends StatelessWidget {
  const _IslamicQuoteSection({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    _primaryGreen.withValues(alpha: 0.12),
                    _accentGold.withValues(alpha: 0.06),
                  ]
                : [
                    const Color(0xFFF0FDF4),
                    const Color(0xFFFEFCE8),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? _primaryGreen.withValues(alpha: 0.1)
                : _primaryGreen.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.format_quote_rounded,
              size: 32,
              color: _accentGold.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'وَتَعَاوَنُوا عَلَى الْبِرِّ وَالتَّقْوَى',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFFCD34D)
                    : const Color(0xFF92400E),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"And cooperate in righteousness and piety"',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : const Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Surah Al-Ma\'idah 5:2',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Made with love for the Ummah',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : const Color(0xFFD1D5DB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
