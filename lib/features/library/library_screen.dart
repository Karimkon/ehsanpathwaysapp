import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/features/library/library_provider.dart';
import 'package:ehsan_pathways/features/library/models/library_book.dart';
import 'package:ehsan_pathways/features/library/widgets/book_cover.dart';

/// The library: the scanned classical works, and the way in to the searchable
/// hadith collections.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  /// On a wide browser window the shelf stops widening and centres instead —
  /// covers stretched across 1900px read as a stock photo grid, not a library.
  static const double maxContentWidth = 1160;

  static double contentWidth(BuildContext context) =>
      math.min(MediaQuery.sizeOf(context).width, maxContentWidth);

  /// Cover width is chosen from the viewport so the same screen works on a
  /// phone, a tablet and the web portal without separate layouts.
  static int _columnsFor(double width) {
    if (width >= 900) return 6;
    if (width >= 680) return 5;
    if (width >= 480) return 4;
    return 3;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogue = ref.watch(libraryCatalogueProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        color: AppTheme.primaryGreen,
        onRefresh: () async {
          ref.invalidate(libraryCatalogueProvider);
          ref.invalidate(continueReadingProvider);
          await ref.read(libraryCatalogueProvider.future);
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: LibraryScreen.maxContentWidth,
            ),
            child: CustomScrollView(
              slivers: [
                _LibraryHeader(isDark: isDark),
                catalogue.when(
                  loading: () => const _LoadingShelf(),
                  error: (e, _) => _ErrorShelf(
                    onRetry: () => ref.invalidate(libraryCatalogueProvider),
                  ),
                  data: (data) => _Shelves(catalogue: data),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Library',
                      style: AppTheme.ui(
                        size: 30,
                        weight: FontWeight.w800,
                        color: isDark
                            ? AppTheme.textOnDark
                            : AppTheme.textOnLight,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'المكتبة',
                      textDirection: TextDirection.rtl,
                      style: AppTheme.arabic(
                        size: 19,
                        color: AppTheme.accentGold,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.pushNamed('hadith-search'),
                icon: const Icon(Icons.search_rounded),
                tooltip: 'Search the hadith collections',
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? AppTheme.inkSoft : Colors.white,
                  foregroundColor: isDark
                      ? AppTheme.textOnDark
                      : AppTheme.textOnLight,
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isDark ? AppTheme.inkLine : AppTheme.sand,
                    ),
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

class _Shelves extends ConsumerWidget {
  const _Shelves({required this.catalogue});

  final LibraryCatalogue catalogue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(libraryFilterProvider);
    final continuing = ref.watch(continueReadingProvider);
    final books = catalogue.inCategory(filter);
    final width = LibraryScreen.contentWidth(context);
    final columns = LibraryScreen._columnsFor(width);

    // 20px page margin each side, 16px between columns.
    final coverWidth = (width - 40 - (columns - 1) * 16) / columns;

    return SliverMainAxisGroup(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        const SliverToBoxAdapter(child: _HadithGateway()),

        continuing.maybeWhen(
          data: (list) => list.isEmpty
              ? const SliverToBoxAdapter(child: SizedBox.shrink())
              : SliverToBoxAdapter(child: _ContinueRow(books: list)),
          orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
        ),

        SliverToBoxAdapter(
          child: _ShelfFilters(categories: catalogue.categories),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 24,
              crossAxisSpacing: 16,
              // Cover, then two lines of title and one of meta.
              mainAxisExtent: coverWidth / BookCover.aspect + 62,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _BookTile(book: books[i], width: coverWidth),
              childCount: books.length,
            ),
          ),
        ),
      ],
    );
  }
}

/// The way in to the 36,108 hadith held as text — distinct from the scans,
/// because that content is searchable and these books are not.
class _HadithGateway extends StatelessWidget {
  const _HadithGateway();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.pushNamed('hadith-books'),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryGreenDark, AppTheme.primaryGreen],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'THE SIX BOOKS & MORE',
                          style: AppTheme.eyebrow(AppTheme.accentGoldLight),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Hadith Collections',
                          style: AppTheme.ui(
                            size: 19,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '36,108 hadith in Arabic and English, every one searchable',
                          style: AppTheme.ui(
                            size: 12.5,
                            weight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.82),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueRow extends StatelessWidget {
  const _ContinueRow({required this.books});

  final List<LibraryBook> books;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            'Continue reading',
            style: AppTheme.ui(
              size: 16,
              weight: FontWeight.w800,
              color: isDark ? AppTheme.textOnDark : AppTheme.textOnLight,
            ),
          ),
        ),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final book = books[i];

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.pushNamed(
                  'library-book',
                  pathParameters: {'slug': book.slug},
                ),
                child: Container(
                  width: 268,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.inkSoft : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppTheme.inkLine : AppTheme.sand,
                    ),
                  ),
                  child: Row(
                    children: [
                      BookCover(book: book, width: 66),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              book.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.ui(
                                size: 13.5,
                                weight: FontWeight.w700,
                                color: isDark
                                    ? AppTheme.textOnDark
                                    : AppTheme.textOnLight,
                                height: 1.32,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Page ${book.progressPage} of ${book.pageCount}',
                              style: AppTheme.ui(
                                size: 11.5,
                                weight: FontWeight.w500,
                                color: isDark
                                    ? AppTheme.textMutedDark
                                    : AppTheme.textMutedLight,
                              ),
                            ),
                            const SizedBox(height: 9),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: (book.progressPercent ?? 0) / 100,
                                minHeight: 4,
                                backgroundColor: isDark
                                    ? AppTheme.inkLine
                                    : AppTheme.parchmentDeep,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppTheme.accentGold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 26),
      ],
    );
  }
}

class _ShelfFilters extends ConsumerWidget {
  const _ShelfFilters({required this.categories});

  final List<LibraryCategory> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(libraryFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final entries = <MapEntry<String?, String>>[
      const MapEntry(null, 'All books'),
      ...categories.map((c) => MapEntry<String?, String>(c.slug, c.label)),
    ];

    return SizedBox(
      height: 66,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, i) {
          final entry = entries[i];
          final active = selected == entry.key;
          final tint = entry.key == null
              ? AppTheme.primaryGreen
              : AppTheme.shelfColor(entry.key);

          return Center(
            child: GestureDetector(
              onTap: () =>
                  ref.read(libraryFilterProvider.notifier).state = entry.key,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? tint
                      : (isDark ? AppTheme.inkSoft : Colors.white),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: active
                        ? tint
                        : (isDark ? AppTheme.inkLine : AppTheme.sand),
                  ),
                ),
                child: Text(
                  entry.value,
                  style: AppTheme.ui(
                    size: 13,
                    weight: FontWeight.w700,
                    color: active
                        ? Colors.white
                        : (isDark
                              ? AppTheme.textMutedDark
                              : AppTheme.textMutedLight),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.book, required this.width});

  final LibraryBook book;
  final double width;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.pushNamed(
        'library-book',
        pathParameters: {'slug': book.slug},
      ),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookCover(book: book, width: width, showProgress: true),
          const SizedBox(height: 10),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.ui(
              size: 12.5,
              weight: FontWeight.w700,
              color: isDark ? AppTheme.textOnDark : AppTheme.textOnLight,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${book.pageCount} pages',
            style: AppTheme.ui(
              size: 11,
              weight: FontWeight.w500,
              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingShelf extends StatelessWidget {
  const _LoadingShelf();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = LibraryScreen.contentWidth(context);
    final columns = LibraryScreen._columnsFor(width);
    final coverWidth = (width - 40 - (columns - 1) * 16) / columns;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 24,
          crossAxisSpacing: 16,
          mainAxisExtent: coverWidth / BookCover.aspect + 62,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => Shimmer.fromColors(
            baseColor: isDark ? AppTheme.inkSoft : AppTheme.parchmentDeep,
            highlightColor: isDark ? AppTheme.inkLine : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: coverWidth,
                  height: coverWidth / BookCover.aspect,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 11,
                  width: coverWidth * 0.86,
                  color: Colors.white,
                ),
                const SizedBox(height: 6),
                Container(
                  height: 9,
                  width: coverWidth * 0.5,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          childCount: 9,
        ),
      ),
    );
  }
}

class _ErrorShelf extends StatelessWidget {
  const _ErrorShelf({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 44,
              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
            ),
            const SizedBox(height: 16),
            Text(
              'The shelf could not be loaded',
              textAlign: TextAlign.center,
              style: AppTheme.ui(
                size: 16,
                weight: FontWeight.w700,
                color: isDark ? AppTheme.textOnDark : AppTheme.textOnLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: AppTheme.ui(
                size: 13,
                weight: FontWeight.w500,
                color: isDark
                    ? AppTheme.textMutedDark
                    : AppTheme.textMutedLight,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
