import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/shared/widgets/scholar_avatar.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';
import 'package:ehsan_pathways/features/scholars/scholar_provider.dart';

/// Displays a searchable grid of scholars, each presented as a beautiful card
/// with a circular photo, name, title, and content counts.
class ScholarsScreen extends ConsumerStatefulWidget {
  const ScholarsScreen({super.key});

  @override
  ConsumerState<ScholarsScreen> createState() => _ScholarsScreenState();
}

class _ScholarsScreenState extends ConsumerState<ScholarsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Scholar> _filterScholars(List<Scholar> scholars) {
    if (_searchQuery.isEmpty) return scholars;
    final query = _searchQuery.toLowerCase();
    return scholars.where((s) {
      return s.name.toLowerCase().contains(query) ||
          (s.title?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scholarsAsync = ref.watch(scholarsListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------------------------------------------------
            // Header
            // -----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Scholars',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Text(
                'Learn from trusted Islamic scholars',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),

            // -----------------------------------------------------------------
            // Search bar
            // -----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search scholars...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppTheme.primaryGreen.withValues(alpha: 0.7),
                      size: 22,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: isDark
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF6B7280),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
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

            // -----------------------------------------------------------------
            // Content
            // -----------------------------------------------------------------
            Expanded(
              child: scholarsAsync.when(
                loading: () => const SingleChildScrollView(
                  child: ShimmerGrid(
                    crossAxisCount: 2,
                    itemCount: 6,
                    imageHeight: 100,
                    childAspectRatio: 0.72,
                  ),
                ),
                error: (error, _) => EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Failed to load scholars',
                  subtitle: error.toString(),
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(scholarsListProvider),
                ),
                data: (scholars) {
                  final filtered = _filterScholars(scholars);

                  if (filtered.isEmpty && _searchQuery.isNotEmpty) {
                    return EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No scholars found',
                      subtitle: 'Try a different search term',
                      compact: true,
                    );
                  }

                  if (filtered.isEmpty) {
                    return const EmptyState(
                      icon: Icons.school_rounded,
                      title: 'No scholars yet',
                      subtitle: 'Scholars will appear here once added.',
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _ScholarCard(
                        scholar: filtered[index],
                        onTap: () => context
                            .push('/scholars/${filtered[index].slug}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scholar Card
// ---------------------------------------------------------------------------

class _ScholarCard extends StatefulWidget {
  const _ScholarCard({
    required this.scholar,
    required this.onTap,
  });

  final Scholar scholar;
  final VoidCallback onTap;

  @override
  State<_ScholarCard> createState() => _ScholarCardState();
}

class _ScholarCardState extends State<_ScholarCard>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
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
    final scholar = widget.scholar;

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
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // -- Avatar ---------------------------------------------------
                ScholarAvatar(
                  name: scholar.name,
                  imageUrl: scholar.photoUrl,
                  size: ScholarAvatarSize.large,
                ),
                const SizedBox(height: 14),

                // -- Name -----------------------------------------------------
                Text(
                  scholar.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),

                // -- Title ----------------------------------------------------
                if (scholar.title != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    scholar.title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.accentGold,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // -- Content counts -------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CountChip(
                      icon: Icons.play_circle_outline_rounded,
                      count: scholar.videoCount,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _CountChip(
                      icon: Icons.article_outlined,
                      count: scholar.articleCount,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _CountChip(
                      icon: Icons.headphones_rounded,
                      count: scholar.podcastCount,
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Count Chip (icon + number)
// ---------------------------------------------------------------------------

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.icon,
    required this.count,
    required this.isDark,
  });

  final IconData icon;
  final int count;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
        ),
        const SizedBox(width: 3),
        Text(
          count.toString(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}
