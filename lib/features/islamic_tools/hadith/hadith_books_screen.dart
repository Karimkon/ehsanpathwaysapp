import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/shared/widgets/reading_width.dart';
import 'package:ehsan_pathways/features/islamic_tools/hadith/hadith_library_provider.dart';

/// The ten collections.
class HadithBooksScreen extends ConsumerWidget {
  const HadithBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(hadithBooksProvider);
    final stats = ref.watch(hadithStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hadith Collections'),
        actions: [
          IconButton(
            onPressed: () => context.pushNamed('hadith-search'),
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: books.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (e, _) =>
            _Retry(onRetry: () => ref.invalidate(hadithBooksProvider)),
        data: (list) => ListView.separated(
          padding: readingInsets(
            context,
            horizontal: 20,
            top: 12,
            bottom: 28,
            maxWidth: 900,
          ),
          itemCount: list.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            if (i == 0) {
              return stats.maybeWhen(
                data: (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${_thousands(s['hadiths'] ?? 0)} hadith across '
                    '${s['books'] ?? 0} collections, in Arabic with the '
                    'sunnah.com English translation.',
                    style: AppTheme.ui(
                      size: 13,
                      weight: FontWeight.w500,
                      color: isDark
                          ? AppTheme.textMutedDark
                          : AppTheme.textMutedLight,
                      height: 1.5,
                    ),
                  ),
                ),
                orElse: () => const SizedBox(height: 8),
              );
            }

            return _BookRow(book: list[i - 1]);
          },
        ),
      ),
    );
  }

  static String _thousands(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );
}

class _BookRow extends StatelessWidget {
  const _BookRow({required this.book});

  final HadithBook book;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppTheme.textOnDark : AppTheme.textOnLight;
    final muted = isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.pushNamed(
          'hadith-chapters',
          pathParameters: {'slug': book.slug},
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.inkSoft : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppTheme.inkLine : AppTheme.sand,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A spine, standing in for the book.
              Container(
                width: 5,
                height: 62,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (book.arabicName != null)
                      Text(
                        book.arabicName!,
                        textDirection: TextDirection.rtl,
                        style: AppTheme.arabic(
                          size: 19,
                          color: fg,
                          height: 1.5,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      book.name,
                      style: AppTheme.ui(
                        size: 15.5,
                        weight: FontWeight.w800,
                        color: fg,
                      ),
                    ),
                    if (book.compiler != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        book.compiler!,
                        style: AppTheme.ui(
                          size: 12.5,
                          weight: FontWeight.w500,
                          color: muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 9),
                    Text(
                      '${HadithBooksScreen._thousands(book.hadithCount)} hadith'
                      '${book.chapterCount > 0 ? ' · ${book.chapterCount} chapters' : ''}',
                      style: AppTheme.ui(
                        size: 12,
                        weight: FontWeight.w700,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 40),
          const SizedBox(height: 14),
          Text(
            'The collections could not be loaded.',
            style: AppTheme.ui(size: 14, weight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
