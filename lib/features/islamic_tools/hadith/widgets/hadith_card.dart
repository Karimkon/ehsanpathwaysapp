import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/features/islamic_tools/hadith/hadith_library_provider.dart';

/// One hadith, set for reading rather than for scanning.
///
/// The Arabic is given first and in Amiri, because that is the text; the
/// translation follows in a serif at a comfortable measure.
class HadithCard extends StatelessWidget {
  const HadithCard({
    super.key,
    required this.hadith,
    this.showSource = false,
    this.highlight,
  });

  final Hadith hadith;

  /// Search results need to say which book they came from; a chapter listing
  /// does not.
  final bool showSource;

  /// Term to mark in the translation, for search results.
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppTheme.textOnDark : AppTheme.textOnLight;
    final muted = isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;

    final hasArabic = (hadith.arabicText ?? '').trim().isNotEmpty;
    final hasEnglish = (hadith.englishText ?? '').trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.inkSoft : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppTheme.inkLine : AppTheme.sand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text('#${hadith.number}',
                  style: AppTheme.ui(
                      size: 11.5,
                      weight: FontWeight.w800,
                      color: AppTheme.primaryGreen)),
            ),
            const SizedBox(width: 8),
            if (hadith.grade != null && hadith.grade!.trim().isNotEmpty)
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(hadith.grade!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.ui(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: AppTheme.accentGoldDark)),
                ),
              ),
          ]),

          if (showSource && hadith.bookName != null) ...[
            const SizedBox(height: 10),
            Text(hadith.bookName!,
                style: AppTheme.eyebrow(muted)),
          ],

          if (hasArabic) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                hadith.arabicText!,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: AppTheme.arabic(size: 21, color: fg, height: 2.05),
              ),
            ),
          ],

          if (hasArabic && hasEnglish) ...[
            const SizedBox(height: 14),
            Divider(color: isDark ? AppTheme.inkLine : AppTheme.sand, height: 1),
          ],

          if (hasEnglish) ...[
            const SizedBox(height: 14),
            _Translation(
              text: hadith.englishText!,
              highlight: highlight,
              color: fg,
            ),
          ],

          if (!hasArabic && !hasEnglish)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text('This entry has no text.',
                  style: AppTheme.ui(size: 13, color: muted)),
            ),

          if (hadith.chapterName != null &&
              hadith.chapterName!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(hadith.chapterName!,
                style: AppTheme.ui(
                    size: 11.5, weight: FontWeight.w600, color: muted)),
          ],

          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            IconButton(
              tooltip: 'Copy',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _plainText()));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Hadith copied'),
                  backgroundColor: AppTheme.primaryGreenDark,
                  duration: const Duration(seconds: 2),
                ));
              },
              icon: Icon(Icons.copy_rounded, size: 18, color: muted),
            ),
            IconButton(
              tooltip: 'Share',
              visualDensity: VisualDensity.compact,
              onPressed: () => Share.share(_plainText()),
              icon: Icon(Icons.ios_share_rounded, size: 18, color: muted),
            ),
          ]),
        ],
      ),
    );
  }

  String _plainText() {
    final parts = <String>[
      if ((hadith.arabicText ?? '').trim().isNotEmpty) hadith.arabicText!.trim(),
      if ((hadith.englishText ?? '').trim().isNotEmpty)
        hadith.englishText!.trim(),
      if (hadith.bookName != null) '— ${hadith.bookName}, #${hadith.number}',
    ];

    return parts.join('\n\n');
  }
}

/// The translation, with the searched term marked where there is one.
class _Translation extends StatelessWidget {
  const _Translation({
    required this.text,
    required this.highlight,
    required this.color,
  });

  final String text;
  final String? highlight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = AppTheme.reading(size: 15.5, color: color, height: 1.78);
    final term = highlight?.trim();

    if (term == null || term.length < 3) {
      return Text(text, style: style);
    }

    // Mark every case-insensitive occurrence, keeping the original casing.
    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerTerm = term.toLowerCase();
    var start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerTerm, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + term.length),
        style: TextStyle(
          backgroundColor: AppTheme.accentGold.withValues(alpha: 0.28),
          fontWeight: FontWeight.w700,
        ),
      ));

      start = index + term.length;
    }

    return Text.rich(TextSpan(children: spans), style: style);
  }
}
