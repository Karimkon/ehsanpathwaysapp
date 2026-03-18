import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:ehsan_pathways/config/app_config.dart';
import 'package:ehsan_pathways/shared/widgets/section_header.dart';
import 'package:ehsan_pathways/shared/widgets/scholar_avatar.dart';
import 'package:ehsan_pathways/shared/widgets/badge_chip.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';

// ---------------------------------------------------------------------------
// Search provider
// ---------------------------------------------------------------------------

class _SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) {
    state = value;
  }
}

final _searchQueryProvider =
    NotifierProvider<_SearchQueryNotifier, String>(_SearchQueryNotifier.new);

final _searchResultsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final query = ref.watch(_searchQueryProvider);
  if (query.trim().isEmpty) return {};

  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(milliseconds: AppConfig.connectTimeout),
    receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
    headers: {'Accept': 'application/json'},
  ));

  final response = await dio.get('/search', queryParameters: {'q': query});
  return response.data as Map<String, dynamic>;
});

// ---------------------------------------------------------------------------
// Search Screen
// ---------------------------------------------------------------------------

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  static const _green = Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(_searchQueryProvider.notifier).update(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = ref.watch(_searchQueryProvider);
    final resultsAsync = ref.watch(_searchResultsProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
      body: SafeArea(
        child: Column(
          children: [
            // -- Search bar --------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Search field
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: _onSearchChanged,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search for Islamic knowledge...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark
                                ? const Color(0xFF6B7280)
                                : const Color(0xFF9CA3AF),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: _green,
                          ),
                          suffixIcon: _controller.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45,
                                  ),
                                  onPressed: () {
                                    _controller.clear();
                                    ref.read(_searchQueryProvider.notifier).update('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // -- Results body ------------------------------------------------
            Expanded(
              child: query.isEmpty
                  ? _buildEmptyQuery(isDark)
                  : resultsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: ShimmerList(itemCount: 8),
                        ),
                      ),
                      error: (e, _) => EmptyState(
                        icon: Icons.error_outline_rounded,
                        title: 'Search failed',
                        subtitle: 'Please try again.',
                        actionLabel: 'Retry',
                        onAction: () => ref.invalidate(_searchResultsProvider),
                      ),
                      data: (data) => data.isEmpty
                          ? _buildEmptyQuery(isDark)
                          : _buildResults(data, isDark),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQuery(bool isDark) {
    return EmptyState(
      icon: Icons.search_rounded,
      title: 'Search for Islamic Knowledge',
      subtitle:
          'Find videos, articles, podcasts, and scholars across all topics.',
      iconColor: _green,
    );
  }

  Widget _buildResults(Map<String, dynamic> data, bool isDark) {
    final videos = (data['videos'] as List<dynamic>?) ?? [];
    final articles = (data['articles'] as List<dynamic>?) ?? [];
    final podcasts = (data['podcasts'] as List<dynamic>?) ?? [];
    final scholars = (data['scholars'] as List<dynamic>?) ?? [];

    final hasResults =
        videos.isNotEmpty || articles.isNotEmpty || podcasts.isNotEmpty || scholars.isNotEmpty;

    if (!hasResults) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No results found',
        subtitle: 'Try a different search term.',
        iconColor: Colors.grey,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Videos
          if (videos.isNotEmpty) ...[
            SectionHeader(
              title: 'Videos',
              subtitle: '${videos.length} results',
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            ),
            ...videos.take(4).map((v) => _SearchResultTile(
                  title: v['title'] ?? '',
                  subtitle: v['scholar']?['name'] ?? '',
                  imageUrl: v['thumbnail_url'],
                  icon: Icons.play_circle_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  isDark: isDark,
                  onTap: () => context.push('/videos/${v['uuid']}'),
                )),
          ],

          // Articles
          if (articles.isNotEmpty) ...[
            SectionHeader(
              title: 'Articles',
              subtitle: '${articles.length} results',
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            ),
            ...articles.take(4).map((a) => _SearchResultTile(
                  title: a['title'] ?? '',
                  subtitle: a['scholar']?['name'] ?? '',
                  imageUrl: a['featured_image_url'],
                  icon: Icons.article_rounded,
                  iconColor: const Color(0xFF10B981),
                  isDark: isDark,
                  onTap: () => context.push('/articles/${a['slug']}'),
                )),
          ],

          // Podcasts
          if (podcasts.isNotEmpty) ...[
            SectionHeader(
              title: 'Podcasts',
              subtitle: '${podcasts.length} results',
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            ),
            ...podcasts.take(4).map((p) => _SearchResultTile(
                  title: p['title'] ?? '',
                  subtitle: p['scholar']?['name'] ?? '',
                  imageUrl: p['cover_image_url'],
                  icon: Icons.headphones_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  isDark: isDark,
                  onTap: () => context.push('/podcasts/${p['slug']}'),
                )),
          ],

          // Scholars
          if (scholars.isNotEmpty) ...[
            SectionHeader(
              title: 'Scholars',
              subtitle: '${scholars.length} results',
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            ),
            ...scholars.take(4).map((s) => _ScholarResultTile(
                  name: s['name'] ?? '',
                  photoUrl: s['photo_url'],
                  isDark: isDark,
                  onTap: () => context.push('/scholars/${s['slug']}'),
                )),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search result tile
// ---------------------------------------------------------------------------

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Thumbnail or icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          Icon(icon, color: iconColor, size: 24),
                    )
                  : Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                      height: 1.3,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
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
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scholar result tile
// ---------------------------------------------------------------------------

class _ScholarResultTile extends StatelessWidget {
  const _ScholarResultTile({
    required this.name,
    this.photoUrl,
    required this.isDark,
    required this.onTap,
  });

  final String name;
  final String? photoUrl;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ScholarAvatar(
              name: name,
              imageUrl: photoUrl,
              size: ScholarAvatarSize.medium,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}
