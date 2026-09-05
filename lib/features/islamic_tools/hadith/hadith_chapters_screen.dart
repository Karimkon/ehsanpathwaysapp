import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/shared/widgets/reading_width.dart';
import 'package:ehsan_pathways/features/islamic_tools/hadith/hadith_library_provider.dart';

/// The chapters of one collection.
class HadithChaptersScreen extends ConsumerWidget {
  const HadithChaptersScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapters = ref.watch(hadithChaptersProvider(slug));
    final books = ref.watch(hadithBooksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppTheme.textOnDark : AppTheme.textOnLight;
    final muted = isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;

    final book = books.value?.where((b) => b.slug == slug).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(book?.name ?? 'Chapters'),
        actions: [
          IconButton(
            tooltip: 'Search this collection',
            onPressed: () => context.pushNamed(
              'hadith-search',
              queryParameters: {'book': slug},
            ),
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: chapters.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'The chapters could not be loaded.',
                style: AppTheme.ui(size: 14, weight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(hadithChaptersProvider(slug)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (list) => ListView.separated(
          padding: readingInsets(
            context,
            horizontal: 20,
            top: 8,
            bottom: 28,
            maxWidth: 900,
          ),
          itemCount: list.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 9),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _ReadWholeBook(slug: slug, book: book),
              );
            }

            final chapter = list[i - 1];

            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () => context.pushNamed(
                  'hadith-reader',
                  pathParameters: {'slug': slug},
                  queryParameters: {
                    'chapter': '${chapter.number}',
                    if (chapter.name != null) 'title': chapter.name!,
                  },
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(15, 14, 12, 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.inkSoft : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isDark ? AppTheme.inkLine : AppTheme.sand,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 34,
                        child: Text(
                          '${chapter.number}',
                          style: AppTheme.ui(
                            size: 14,
                            weight: FontWeight.w800,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chapter.name ?? 'Chapter ${chapter.number}',
                              style: AppTheme.ui(
                                size: 14,
                                weight: FontWeight.w700,
                                color: fg,
                                height: 1.35,
                              ),
                            ),
                            if (chapter.arabicName != null &&
                                chapter.arabicName!.trim().isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                chapter.arabicName!,
                                textDirection: TextDirection.rtl,
                                style: AppTheme.arabic(
                                  size: 15,
                                  color: muted,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${chapter.hadithCount}',
                        style: AppTheme.ui(
                          size: 12,
                          weight: FontWeight.w600,
                          color: muted,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: muted, size: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReadWholeBook extends StatelessWidget {
  const _ReadWholeBook({required this.slug, required this.book});

  final String slug;
  final HadithBook? book;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            context.pushNamed('hadith-reader', pathParameters: {'slug': slug}),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [AppTheme.primaryGreenDark, AppTheme.primaryGreen],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 15, 14, 15),
            child: Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    book == null
                        ? 'Read from the beginning'
                        : 'Read all ${book!.hadithCount} from the beginning',
                    style: AppTheme.ui(
                      size: 14,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
