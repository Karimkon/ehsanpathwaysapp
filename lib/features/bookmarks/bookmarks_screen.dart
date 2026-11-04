import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:ehsan_pathways/core/providers/auth_provider.dart';
import 'package:ehsan_pathways/features/bookmarks/bookmark_provider.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';
import 'package:ehsan_pathways/config/theme.dart';

const Color _green = AppColors.emerald700;

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  String? _selectedType;
  final _scrollController = ScrollController();

  static const _typeFilters = <String?, String>{
    null: 'All',
    'video': 'Videos',
    'pathway': 'Pathways',
    'scholar': 'Scholars',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(bookmarkListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authProvider);

    // Guard: show login prompt if not authenticated
    if (auth.status != AuthStatus.authenticated) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.slate : AppColors.cream,
        appBar: AppBar(
          title: Text('Bookmarks',
              style: GoogleFonts.lora(
                  fontSize: 24, fontWeight: FontWeight.w700)),
          centerTitle: false,
          backgroundColor:
              isDark ? AppColors.slate : AppColors.cream,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: const LoginPrompt(feature: 'bookmarks'),
      );
    }

    final bookmarkState = ref.watch(bookmarkListProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.slate : AppColors.cream,
      appBar: AppBar(
        title: Text(
          'Bookmarks',
          style: GoogleFonts.lora(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        backgroundColor:
            isDark ? AppColors.slate : AppColors.cream,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // -- Filter chips --
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _typeFilters.entries.map((entry) {
                final selected = _selectedType == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: selected,
                    label: Text(entry.value),
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? Colors.white
                          : isDark
                              ? AppColors.onDarkMuted
                              : AppColors.ink2,
                    ),
                    backgroundColor: isDark
                        ? AppColors.slateCard
                        : Colors.white,
                    selectedColor: _green,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: selected
                            ? _green
                            : isDark
                                ? Colors.white12
                                : AppColors.sand,
                      ),
                    ),
                    onSelected: (_) {
                      setState(() => _selectedType = entry.key);
                      ref
                          .read(bookmarkListProvider.notifier)
                          .fetchBookmarks(type: entry.key);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // -- Content --
          Expanded(
            child: bookmarkState.isLoading && bookmarkState.bookmarks.isEmpty
                ? const SingleChildScrollView(
                    child: ShimmerList(itemCount: 6),
                  )
                : bookmarkState.error != null &&
                        bookmarkState.bookmarks.isEmpty
                    ? EmptyState(
                        icon: Icons.error_outline_rounded,
                        title: 'Failed to load',
                        subtitle: bookmarkState.error!,
                        actionLabel: 'Retry',
                        onAction: () => ref
                            .read(bookmarkListProvider.notifier)
                            .fetchBookmarks(type: _selectedType),
                      )
                    : bookmarkState.bookmarks.isEmpty
                        ? EmptyState(
                            icon: Icons.bookmark_outline_rounded,
                            title: 'No bookmarks yet',
                            subtitle:
                                'Bookmark your favorite content to find it quickly here.',
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: bookmarkState.bookmarks.length +
                                (bookmarkState.isLoading ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if (index >= bookmarkState.bookmarks.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                );
                              }
                              return _BookmarkCard(
                                bookmark: bookmarkState.bookmarks[index],
                                isDark: isDark,
                                onTap: () => _navigateToContent(
                                    bookmarkState.bookmarks[index]),
                                onDelete: () => _confirmDelete(
                                    bookmarkState.bookmarks[index]),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  void _navigateToContent(Bookmark bookmark) {
    final id = bookmark.item.identifier;
    if (id.isEmpty) return;

    switch (bookmark.type) {
      case 'video':
        context.push('/videos/$id');
      case 'scholar':
        context.push('/scholars/$id');
      case 'pathway':
        context.push('/pathways/$id');
      default:
        break;
    }
  }

  void _confirmDelete(Bookmark bookmark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove Bookmark',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: Text(
          'Remove "${bookmark.item.title}" from your bookmarks?',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(bookmarkListProvider.notifier).deleteBookmark(bookmark.id);
            },
            child: Text('Remove',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bookmark Card
// ---------------------------------------------------------------------------

class _BookmarkCard extends StatelessWidget {
  const _BookmarkCard({
    required this.bookmark,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  final Bookmark bookmark;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  IconData get _typeIcon {
    switch (bookmark.type) {
      case 'video':
        return Icons.play_circle_rounded;
      case 'pathway':
        return Icons.route_rounded;
      case 'scholar':
        return Icons.person_rounded;
      case 'khutbah':
        return Icons.mosque_rounded;
      case 'arabic_course':
        return Icons.translate_rounded;
      default:
        return Icons.bookmark_rounded;
    }
  }

  Color get _typeColor {
    switch (bookmark.type) {
      case 'video':
        return AppColors.sapphire;
      case 'pathway':
        return _green;
      case 'scholar':
        return AppColors.amethyst;
      case 'khutbah':
        return AppColors.gold;
      case 'arabic_course':
        return AppColors.emerald500;
      default:
        return _green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.slateCard : Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: bookmark.item.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: bookmark.item.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_typeIcon, size: 12, color: _typeColor),
                          const SizedBox(width: 4),
                          Text(
                            bookmark.typeLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _typeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      bookmark.item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : AppColors.ink,
                        height: 1.3,
                      ),
                    ),

                    if (bookmark.notes != null &&
                        bookmark.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        bookmark.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.onDarkMuted
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Delete button
              IconButton(
                icon: Icon(
                  Icons.bookmark_remove_rounded,
                  size: 20,
                  color: isDark ? Colors.white38 : Colors.black26,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_typeColor.withValues(alpha: 0.3), _typeColor.withValues(alpha: 0.1)],
        ),
      ),
      child: Icon(_typeIcon, size: 28, color: _typeColor.withValues(alpha: 0.5)),
    );
  }
}
