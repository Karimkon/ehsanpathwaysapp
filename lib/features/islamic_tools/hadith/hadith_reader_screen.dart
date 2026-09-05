import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/shared/widgets/reading_width.dart';
import 'package:ehsan_pathways/features/islamic_tools/hadith/hadith_library_provider.dart';
import 'package:ehsan_pathways/features/islamic_tools/hadith/widgets/hadith_card.dart';

/// Reads a run of hadith — a whole collection, or one chapter of it.
class HadithReaderScreen extends ConsumerStatefulWidget {
  const HadithReaderScreen({
    super.key,
    required this.slug,
    this.chapter,
    this.title,
  });

  final String slug;
  final int? chapter;
  final String? title;

  @override
  ConsumerState<HadithReaderScreen> createState() => _HadithReaderScreenState();
}

class _HadithReaderScreenState extends ConsumerState<HadithReaderScreen> {
  final _scroll = ScrollController();

  late final HadithQuery _query = HadithQuery(
    bookSlug: widget.slug,
    chapter: widget.chapter,
  );

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  void _maybeLoadMore() {
    if (!_scroll.hasClients) return;

    // Fetch the next page a screenful before the end, so the list does not
    // visibly stall at the bottom.
    final remaining =
        _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining < 1200) {
      ref.read(hadithListProvider(_query).notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_maybeLoadMore);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hadithListProvider(_query));
    final books = ref.watch(hadithBooksProvider);
    final book = books.value?.where((b) => b.slug == widget.slug).firstOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title ?? book?.name ?? 'Hadith',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.ui(
                size: 16,
                weight: FontWeight.w800,
                color: isDark ? AppTheme.textOnDark : AppTheme.textOnLight,
              ),
            ),
            if (widget.title != null && book != null)
              Text(
                book.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.ui(
                  size: 11.5,
                  weight: FontWeight.w500,
                  color: isDark
                      ? AppTheme.textMutedDark
                      : AppTheme.textMutedLight,
                ),
              ),
          ],
        ),
      ),
      body: state.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'These hadith could not be loaded.',
                style: AppTheme.ui(size: 14, weight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.read(hadithListProvider(_query).notifier).loadFirst(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (page) => ListView.builder(
          controller: _scroll,
          padding: readingInsets(context, horizontal: 18, top: 14, bottom: 28),
          itemCount: page.items.length + 1,
          itemBuilder: (context, i) {
            if (i == page.items.length) {
              if (!page.hasMore) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Center(
                    child: Text(
                      '${page.total} hadith · end of '
                      '${widget.chapter == null ? 'the collection' : 'this chapter'}',
                      style: AppTheme.ui(
                        size: 12,
                        weight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.textMutedDark
                            : AppTheme.textMutedLight,
                      ),
                    ),
                  ),
                );
              }

              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              );
            }

            return HadithCard(hadith: page.items[i]);
          },
        ),
      ),
    );
  }
}
