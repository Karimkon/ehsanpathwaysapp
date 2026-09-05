import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/features/library/library_provider.dart';
import 'package:ehsan_pathways/features/library/models/library_book.dart';

/// Reads one scanned book.
///
/// An offline copy is used when there is one; otherwise the file is streamed by
/// byte range, so opening page 600 of a 45 MB scan does not mean downloading
/// the 599 pages before it.
class BookReaderScreen extends ConsumerWidget {
  const BookReaderScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(libraryBookProvider(slug));

    return Scaffold(
      backgroundColor: AppTheme.ink,
      body: book.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.accentGold)),
        error: (e, _) => _ReaderMessage(
          message: 'This book could not be opened.',
          onBack: () => context.pop(),
        ),
        data: (data) => _Reader(book: data),
      ),
    );
  }
}

class _Reader extends ConsumerStatefulWidget {
  const _Reader({required this.book});

  final LibraryBook book;

  @override
  ConsumerState<_Reader> createState() => _ReaderState();
}

class _ReaderState extends ConsumerState<_Reader> {
  final _controller = PdfViewerController();

  int _page = 1;
  int _totalPages = 0;
  bool _chromeVisible = true;
  bool _ready = false;

  /// Where to resume: the local page wins, because it is written on every page
  /// turn while the server copy is only best-effort.
  int _initialPage = 1;
  bool _resolvedStart = false;
  String? _offlinePath;

  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _resolveStart();
  }

  Future<void> _resolveStart() async {
    final local = await ref.read(readingPositionProvider).localPage(widget.book.slug);
    final offline = await ref.read(offlineLibraryProvider).pathIfSaved(widget.book.slug);

    if (!mounted) return;

    setState(() {
      _initialPage = local > 1 ? local : (widget.book.progressPage ?? 1);
      _page = _initialPage;
      _offlinePath = offline;
      _resolvedStart = true;
    });
  }

  /// Page turns are frequent; the write is not. Debouncing keeps a fast scroll
  /// through the book from firing a request per page.
  void _onPageChanged(int? page) {
    if (page == null || page == _page) return;

    setState(() => _page = page);

    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 900), () {
      ref.read(readingPositionProvider).save(widget.book.slug, page);
    });
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    // The debounce may not have fired yet; make sure the final page is kept.
    ref.read(readingPositionProvider).save(widget.book.slug, _page);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolvedStart) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accentGold));
    }

    final params = PdfViewerParams(
      backgroundColor: AppTheme.ink,
      maxScale: 6,
      onPageChanged: _onPageChanged,
      onViewerReady: (document, controller) {
        if (!mounted) return;
        setState(() {
          _ready = true;
          _totalPages = document.pages.length;
        });
      },
      loadingBannerBuilder: (context, downloaded, total) => _LoadingBanner(
        downloaded: downloaded,
        total: total,
        streaming: _offlinePath == null,
      ),
      errorBannerBuilder: (context, error, stack, documentRef) => _ReaderMessage(
        message: _offlinePath == null
            ? 'This book could not be loaded. It streams from the internet — '
                'check your connection, or save it for offline reading first.'
            : 'The saved copy of this book is damaged. Remove it and download it again.',
        onBack: () => context.pop(),
      ),
    );

    return GestureDetector(
      onTap: () => setState(() => _chromeVisible = !_chromeVisible),
      child: Stack(
        children: [
          Positioned.fill(
            child: _offlinePath != null
                ? PdfViewer.file(
                    _offlinePath!,
                    controller: _controller,
                    initialPageNumber: _initialPage,
                    params: params,
                  )
                : PdfViewer.uri(
                    Uri.parse(widget.book.pdfUrl),
                    controller: _controller,
                    initialPageNumber: _initialPage,
                    // Range access is what makes streaming viable; it is not
                    // available on the web, where pdfrx loads progressively.
                    preferRangeAccess: !kIsWeb,
                    params: params,
                  ),
          ),
          if (_chromeVisible) _TopBar(book: widget.book),
          if (_chromeVisible && _ready && _totalPages > 0)
            _BottomBar(
              page: _page,
              total: _totalPages,
              onSeek: (p) => _controller.goToPage(pageNumber: p),
            ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.book});

  final LibraryBook book;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.ink.withValues(alpha: 0.96),
              AppTheme.ink.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 14, 18),
          child: Row(children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.ui(
                          size: 14,
                          weight: FontWeight.w700,
                          color: Colors.white)),
                  Text(book.arabicTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                      style: AppTheme.arabic(
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.62),
                          height: 1.5)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.page,
    required this.total,
    required this.onSeek,
  });

  final int page;
  final int total;
  final ValueChanged<int> onSeek;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 10,
            left: 18,
            right: 18,
            top: 26),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              AppTheme.ink.withValues(alpha: 0.97),
              AppTheme.ink.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Text('$page',
                style: AppTheme.ui(
                    size: 13, weight: FontWeight.w800, color: Colors.white)),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  activeTrackColor: AppTheme.accentGold,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.22),
                  thumbColor: AppTheme.accentGoldLight,
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 15),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: page.clamp(1, total).toDouble(),
                  min: 1,
                  max: total.toDouble(),
                  onChanged: (v) => onSeek(v.round()),
                ),
              ),
            ),
            Text('$total',
                style: AppTheme.ui(
                    size: 13,
                    weight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.6))),
          ]),
        ]),
      ),
    );
  }
}

class _LoadingBanner extends StatelessWidget {
  const _LoadingBanner({
    required this.downloaded,
    required this.total,
    required this.streaming,
  });

  final int downloaded;
  final int? total;
  final bool streaming;

  @override
  Widget build(BuildContext context) {
    final value = (total != null && total! > 0) ? downloaded / total! : null;

    return ColoredBox(
      color: AppTheme.ink,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 3,
              color: AppTheme.accentGold,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            streaming ? 'Opening the book…' : 'Opening your saved copy…',
            style: AppTheme.ui(
                size: 13.5, weight: FontWeight.w600, color: Colors.white),
          ),
          if (value != null) ...[
            const SizedBox(height: 6),
            Text('${(value * 100).round()}%',
                style: AppTheme.ui(
                    size: 12,
                    weight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.55))),
          ],
        ]),
      ),
    );
  }
}

class _ReaderMessage extends StatelessWidget {
  const _ReaderMessage({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.ink,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(34),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.menu_book_rounded,
                size: 44, color: Colors.white.withValues(alpha: 0.4)),
            const SizedBox(height: 18),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTheme.ui(
                    size: 14,
                    weight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.6)),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: onBack,
              style:
                  FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              child: const Text('Go back'),
            ),
          ]),
        ),
      ),
    );
  }
}
