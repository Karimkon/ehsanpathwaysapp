import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/features/library/library_provider.dart';
import 'package:ehsan_pathways/features/library/models/library_book.dart';
import 'package:ehsan_pathways/features/library/widgets/book_cover.dart';

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(libraryBookProvider(slug));

    return Scaffold(
      body: book.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => _DetailError(
          onRetry: () => ref.invalidate(libraryBookProvider(slug)),
        ),
        data: (data) => _Detail(book: data),
      ),
    );
  }
}

class _Detail extends ConsumerStatefulWidget {
  const _Detail({required this.book});

  final LibraryBook book;

  @override
  ConsumerState<_Detail> createState() => _DetailState();
}

class _DetailState extends ConsumerState<_Detail> {
  double? _downloadProgress;
  CancelToken? _cancel;
  String? _error;

  @override
  void dispose() {
    _cancel?.cancel();
    super.dispose();
  }

  Future<void> _download() async {
    setState(() {
      _downloadProgress = 0;
      _error = null;
    });

    _cancel = CancelToken();

    try {
      await ref.read(offlineLibraryProvider).download(
            widget.book,
            cancelToken: _cancel,
            onProgress: (received, total) {
              if (total > 0 && mounted) {
                setState(() => _downloadProgress = received / total);
              }
            },
          );

      if (!mounted) return;
      ref.invalidate(offlineCopyProvider(widget.book.slug));
      setState(() => _downloadProgress = null);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${widget.book.title} is saved for offline reading'),
        backgroundColor: AppTheme.primaryGreenDark,
      ));
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _downloadProgress = null;
        _error = e.type == DioExceptionType.cancel
            ? null
            : 'The download did not finish. Check your connection and try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _downloadProgress = null;
        _error = 'This book could not be saved to the device.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shelf = AppTheme.shelfColor(book.category);
    final saved = ref.watch(offlineCopyProvider(book.slug));
    final fg = isDark ? AppTheme.textOnDark : AppTheme.textOnLight;
    final muted = isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 330,
          backgroundColor: isDark ? AppTheme.ink : AppTheme.parchment,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    shelf.withValues(alpha: isDark ? 0.34 : 0.20),
                    isDark ? AppTheme.ink : AppTheme.parchment,
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 26),
                    child: Hero(
                      tag: 'cover-${book.slug}',
                      child: BookCover(book: book, width: 152),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.arabicTitle,
                    textDirection: TextDirection.rtl,
                    style: AppTheme.arabic(size: 27, color: fg, height: 1.62)),
                const SizedBox(height: 8),
                Text(book.title,
                    style: AppTheme.ui(
                        size: 19, weight: FontWeight.w800, color: fg)),
                if (book.author != null) ...[
                  const SizedBox(height: 7),
                  Text(book.author!,
                      style: AppTheme.ui(
                          size: 13.5, weight: FontWeight.w500, color: muted)),
                ],
                if (book.arabicAuthor != null) ...[
                  const SizedBox(height: 3),
                  Text(book.arabicAuthor!,
                      textDirection: TextDirection.rtl,
                      style: AppTheme.arabic(size: 16, color: muted, height: 1.5)),
                ],

                const SizedBox(height: 20),
                Row(children: [
                  _Fact(icon: Icons.menu_book_rounded, label: '${book.pageCount} pages', tint: shelf),
                  const SizedBox(width: 10),
                  _Fact(icon: Icons.sd_storage_rounded, label: book.fileSizeLabel, tint: shelf),
                ]),

                if (book.description != null) ...[
                  const SizedBox(height: 22),
                  Text(book.description!,
                      style: AppTheme.reading(size: 15, color: muted)),
                ],

                const SizedBox(height: 26),

                // Read
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.pushNamed('library-reader',
                        pathParameters: {'slug': book.slug}),
                    icon: Icon(book.hasProgress
                        ? Icons.play_arrow_rounded
                        : Icons.chrome_reader_mode_rounded),
                    label: Text(
                      book.hasProgress
                          ? 'Continue from page ${book.progressPage}'
                          : 'Start reading',
                      style: AppTheme.ui(
                          size: 15, weight: FontWeight.w700, color: Colors.white),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: shelf,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),

                const SizedBox(height: 11),

                // Offline. Web has no writable app directory, so the option is
                // simply not offered there rather than failing on tap.
                if (!kIsWeb && book.isDownloadable)
                  saved.maybeWhen(
                    data: (path) => path != null
                        ? _SavedRow(
                            onRemove: () async {
                              await ref
                                  .read(offlineLibraryProvider)
                                  .remove(book.slug);
                              ref.invalidate(offlineCopyProvider(book.slug));
                            },
                          )
                        : _DownloadButton(
                            label: 'Save for offline (${book.fileSizeLabel})',
                            progress: _downloadProgress,
                            onPressed: _downloadProgress == null ? _download : null,
                            onCancel: () => _cancel?.cancel(),
                          ),
                    orElse: () => const SizedBox.shrink(),
                  ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: AppTheme.ui(
                          size: 12.5,
                          weight: FontWeight.w500,
                          color: Colors.red.shade400)),
                ],

                const SizedBox(height: 20),
                Text(
                  'This is a scanned book. The pages are images, so the text inside '
                  'it cannot be searched — use the hadith collections for that.',
                  style: AppTheme.ui(
                      size: 12, weight: FontWeight.w500, color: muted, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.tint});

  final IconData icon;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: tint),
        const SizedBox(width: 7),
        Text(label,
            style: AppTheme.ui(size: 12.5, weight: FontWeight.w700, color: tint)),
      ]),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({
    required this.label,
    required this.progress,
    required this.onPressed,
    required this.onCancel,
  });

  final String label;
  final double? progress;
  final VoidCallback? onPressed;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppTheme.textOnDark : AppTheme.textOnLight;

    if (progress != null) {
      return Column(
        children: [
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor:
                      isDark ? AppTheme.inkLine : AppTheme.parchmentDeep,
                  valueColor:
                      const AlwaysStoppedAnimation(AppTheme.accentGold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('${((progress ?? 0) * 100).round()}%',
                style: AppTheme.ui(size: 12.5, weight: FontWeight.w700, color: fg)),
            TextButton(onPressed: onCancel, child: const Text('Cancel')),
          ]),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.download_rounded, size: 19),
        label: Text(label,
            style: AppTheme.ui(size: 14, weight: FontWeight.w700, color: fg)),
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          padding: const EdgeInsets.symmetric(vertical: 15),
          side: BorderSide(color: isDark ? AppTheme.inkLine : AppTheme.sand),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}

class _SavedRow extends StatelessWidget {
  const _SavedRow({required this.onRemove});

  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        const Icon(Icons.offline_pin_rounded,
            color: AppTheme.primaryGreen, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text('Saved on this device',
              style: AppTheme.ui(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppTheme.primaryGreen)),
        ),
        TextButton(onPressed: onRemove, child: const Text('Remove')),
      ]),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, size: 42),
          const SizedBox(height: 14),
          Text('This book could not be opened.',
              style: AppTheme.ui(size: 15, weight: FontWeight.w700)),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            child: const Text('Try again'),
          ),
        ]),
      ),
    );
  }
}
