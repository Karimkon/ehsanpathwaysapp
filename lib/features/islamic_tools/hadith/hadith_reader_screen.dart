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
    this.highlight,
  });

  final String slug;
  final int? chapter;
  final String? title;

  /// Hadith number to scroll to and mark, used when arriving from the Daily
  /// Hadith card. Opening the right chapter is not enough: a chapter can run
  /// to dozens of hadith and the one you tapped would be somewhere in it.
  final String? highlight;

  @override
  ConsumerState<HadithReaderScreen> createState() => _HadithReaderScreenState();
}

class _HadithReaderScreenState extends ConsumerState<HadithReaderScreen> {
  final _scroll = ScrollController();

  /// Anchor for the highlighted hadith, so it can be brought into view once
  /// the list has actually laid out.
  final _highlightKey = GlobalKey();
  bool _hasScrolledToHighlight = false;

  late final HadithQuery _query = HadithQuery(
    bookSlug: widget.slug,
    chapter: widget.chapter,
  );

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  /// Runs after the frame that first builds the highlighted card. Guarded by
  /// a flag because the list rebuilds on every page load.
  void _revealHighlight() {
    if (_hasScrolledToHighlight) return;

    final context = _highlightKey.currentContext;
    if (context == null) return;

    _hasScrolledToHighlight = true;

    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      alignment: 0.18,
    );
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

            final hadith = page.items[i];
            final isTarget =
                widget.highlight != null && hadith.number == widget.highlight;

            if (!isTarget) {
              return HadithCard(hadith: hadith);
            }

            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _revealHighlight(),
            );

            return _HighlightedHadith(
              key: _highlightKey,
              isDark: isDark,
              child: HadithCard(hadith: hadith),
            );
          },
        ),
      ),
    );
  }
}

/// Marks the hadith you arrived for.
///
/// A ring and a wash of gold that fade out after a few seconds: long enough
/// to say "this one", short enough that it is not a permanent decoration on
/// a page meant for reading.
class _HighlightedHadith extends StatefulWidget {
  const _HighlightedHadith({
    super.key,
    required this.child,
    required this.isDark,
  });

  final Widget child;
  final bool isDark;

  @override
  State<_HighlightedHadith> createState() => _HighlightedHadithState();
}

class _HighlightedHadithState extends State<_HighlightedHadith>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  late final Animation<double> _strength = TweenSequence<double>([
    // Hold, then release — the scroll has to land before it starts fading.
    TweenSequenceItem(tween: ConstantTween<double>(1), weight: 62),
    TweenSequenceItem(
      tween: Tween<double>(begin: 1, end: 0).chain(
        CurveTween(curve: Curves.easeOutCubic),
      ),
      weight: 38,
    ),
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _strength,
      builder: (context, child) {
        final t = _strength.value;

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppColors.gold.withValues(alpha: 0.09 * t),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.55 * t),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(
                  alpha: (widget.isDark ? 0.22 : 0.3) * t,
                ),
                blurRadius: 22 * t,
                spreadRadius: 1.5 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
