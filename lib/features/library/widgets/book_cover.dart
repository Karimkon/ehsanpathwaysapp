import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/features/library/models/library_book.dart';

/// A book cover drawn as an object rather than a thumbnail.
///
/// The spine gradient down the leading edge, the asymmetric corner radius and
/// the lift under the fore-edge are what make a grid of these read as a shelf
/// of physical books instead of a grid of images.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.book,
    this.width = 116,
    this.showProgress = false,
  });

  final LibraryBook book;
  final double width;
  final bool showProgress;

  static const double aspect = 0.68; // width / height of a printed book

  @override
  Widget build(BuildContext context) {
    final height = width / aspect;
    final shelf = AppTheme.shelfColor(book.category);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The board.
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                bottomLeft: Radius.circular(3),
                topRight: Radius.circular(9),
                bottomRight: Radius.circular(9),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.22),
                  blurRadius: 14,
                  offset: const Offset(3, 7),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                bottomLeft: Radius.circular(3),
                topRight: Radius.circular(9),
                bottomRight: Radius.circular(9),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (book.coverUrl != null)
                    CachedNetworkImage(
                      imageUrl: book.coverUrl!,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 220),
                      placeholder: (_, __) => ColoredBox(
                        color: shelf.withValues(alpha: 0.16),
                      ),
                      errorWidget: (_, __, ___) => _FallbackBoard(book: book),
                    )
                  else
                    _FallbackBoard(book: book),

                  // A hairline edge. Several of these books have near-white
                  // title pages for covers, and without it they dissolve into
                  // the parchment ground instead of reading as objects.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.14),
                            width: 0.8,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(3),
                            bottomLeft: Radius.circular(3),
                            topRight: Radius.circular(9),
                            bottomRight: Radius.circular(9),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Spine shading: a highlight just off the leading edge, so
                  // the board looks bound rather than printed flat.
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: width * 0.16,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.34),
                              Colors.black.withValues(alpha: 0.06),
                              Colors.white.withValues(alpha: 0.10),
                              Colors.transparent,
                            ],
                            stops: const [0, 0.42, 0.72, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (showProgress && (book.progressPercent ?? 0) > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ProgressFoot(percent: book.progressPercent!, tint: shelf),
            ),
        ],
      ),
    );
  }
}

/// Used when a scan has no cover page worth showing: the title set in Amiri on
/// the shelf colour, which is closer to a real board than a grey placeholder.
class _FallbackBoard extends StatelessWidget {
  const _FallbackBoard({required this.book});

  final LibraryBook book;

  @override
  Widget build(BuildContext context) {
    final shelf = AppTheme.shelfColor(book.category);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [shelf, Color.lerp(shelf, Colors.black, 0.45)!],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 10, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 1,
              color: AppTheme.accentGoldLight.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: Text(
                  book.arabicTitle,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.arabic(
                    size: 17,
                    color: Colors.white,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 1,
              color: AppTheme.accentGoldLight.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressFoot extends StatelessWidget {
  const _ProgressFoot({required this.percent, required this.tint});

  final int percent;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.82)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 3,
              backgroundColor: Colors.white.withValues(alpha: 0.28),
              valueColor: AlwaysStoppedAnimation(AppTheme.accentGoldLight),
            ),
          ),
          const SizedBox(height: 5),
          Text('$percent%',
              style: AppTheme.ui(
                size: 10,
                weight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.92),
              )),
        ],
      ),
    );
  }
}
