import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/features/islamic_tools/islamic_tools_provider.dart';
import 'package:ehsan_pathways/features/islamic_tools/quran/quran_reading.dart';
import 'package:ehsan_pathways/features/islamic_tools/quran/quran_text.dart';
import 'package:ehsan_pathways/shared/widgets/reading_width.dart';

/// The mushaf reader: Uthmani text, translation, verse-by-verse recitation,
/// bookmarks, and a memorisation mode that hides each verse until tapped.
class QuranReaderScreen extends ConsumerStatefulWidget {
  const QuranReaderScreen({
    super.key,
    required this.surahNo,
    this.initialVerse,
    this.memorise = false,
  });

  final int surahNo;

  /// Verse to open at (from "continue reading" or a bookmark).
  final int? initialVerse;

  /// Start in memorisation mode (opened from the Hifz tracker).
  final bool memorise;

  @override
  ConsumerState<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends ConsumerState<QuranReaderScreen> {
  final _scroll = ItemScrollController();
  final _positions = ItemPositionsListener.create();
  late bool _memorise = widget.memorise;
  final Set<int> _revealed = {};
  Timer? _markReadDebounce;

  Surah get _surah => surahByNumber(widget.surahNo);

  @override
  void initState() {
    super.initState();
    _positions.itemPositions.addListener(_onScroll);
  }

  @override
  void dispose() {
    _positions.itemPositions.removeListener(_onScroll);
    _markReadDebounce?.cancel();
    super.dispose();
  }

  /// Remembers the first fully visible verse as the reading position.
  void _onScroll() {
    _markReadDebounce?.cancel();
    _markReadDebounce = Timer(const Duration(milliseconds: 600), () {
      final visible = _positions.itemPositions.value
          .where((p) => p.index > 0 && p.itemLeadingEdge >= -0.05)
          .map((p) => p.index)
          .fold<int?>(null, (a, b) => a == null || b < a ? b : a);
      if (visible != null && mounted) {
        ref.read(quranReadingProvider.notifier).markRead(_surah.no, visible);
      }
    });
  }

  /// Item 0 is the surah header; verse n is item n.
  void _scrollToVerse(int verse, {bool animate = true}) {
    if (!_scroll.isAttached) return;
    if (animate) {
      _scroll.scrollTo(
        index: verse,
        duration: AppMotion.of(context, AppMotion.emphasized),
        curve: AppMotion.curve,
        alignment: 0.12,
      );
    } else {
      _scroll.jumpTo(index: verse, alignment: 0.05);
    }
  }

  void _playFrom(List<QuranVerse> verses, int verse) {
    ref.read(recitationProvider.notifier).play(
          surah: _surah.no,
          verse: verse,
          globalByVerse: {for (final v in verses) v.number: v.globalNumber},
        );
  }

  @override
  Widget build(BuildContext context) {
    final surah = _surah;
    final versesAsync = ref.watch(quranVersesProvider(surah.no));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Follow the recitation: keep the verse being read on screen.
    ref.listen<RecitationState>(recitationProvider, (prev, next) {
      if (next.surah == surah.no &&
          next.verse != null &&
          next.verse != prev?.verse) {
        _scrollToVerse(next.verse!);
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    final recitation = ref.watch(recitationProvider);
    final playingHere = recitation.isActive && recitation.surah == surah.no;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.slateDeep : AppColors.emerald900,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              surah.name,
              style: AppTheme.ui(size: 17, weight: FontWeight.w800, color: Colors.white),
            ),
            Text(
              '${surah.meaning} · ${surah.verses} verses',
              style: AppTheme.ui(
                size: 12,
                weight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _memorise ? 'Show all verses' : 'Memorisation mode',
            icon: Icon(
              _memorise ? Icons.visibility_off_rounded : Icons.psychology_rounded,
              color: _memorise ? AppColors.goldLight : Colors.white,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _memorise = !_memorise;
                _revealed.clear();
              });
            },
          ),
          IconButton(
            tooltip: 'Reading settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: versesAsync.when(
        loading: () => const _ReaderLoading(),
        error: (e, _) => _ReaderError(
          onRetry: () => ref.invalidate(quranVersesProvider(surah.no)),
        ),
        data: (verses) {
          final initial = widget.initialVerse;
          return Stack(
            children: [
              ScrollablePositionedList.builder(
                itemScrollController: _scroll,
                itemPositionsListener: _positions,
                initialScrollIndex:
                    initial != null && initial <= verses.length ? initial : 0,
                initialAlignment: initial != null ? 0.05 : 0,
                padding: readingInsets(
                  context,
                  horizontal: 16,
                  top: 16,
                  bottom: playingHere ? 140 : 32,
                ),
                itemCount: verses.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _SurahHeader(
                      surah: surah,
                      onPlay: () => _playFrom(verses, 1),
                    );
                  }
                  final verse = verses[index - 1];
                  return _VerseTile(
                    surah: surah,
                    verse: verse,
                    isCurrent: playingHere && recitation.verse == verse.number,
                    hidden: _memorise && !_revealed.contains(verse.number),
                    onReveal: () => setState(() {
                      HapticFeedback.selectionClick();
                      _revealed.contains(verse.number)
                          ? _revealed.remove(verse.number)
                          : _revealed.add(verse.number);
                    }),
                    onPlay: () => _playFrom(verses, verse.number),
                  );
                },
              ),
              if (_memorise)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: _MemoriseBanner(
                    onRevealAll: () => setState(
                      () => _revealed.addAll(verses.map((v) => v.number)),
                    ),
                  ),
                ),
              if (playingHere)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _RecitationBar(),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ReadingSettingsSheet(),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.surah, required this.onPlay});

  final Surah surah;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: AppGradients.emerald,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
        boxShadow: softShadow(context),
      ),
      child: Stack(
        children: [
          // Faint eight-point star motif behind the title.
          Positioned(
            right: -30,
            top: -30,
            child: Icon(
              Icons.star_rate_rounded,
              size: 180,
              color: AppColors.gold.withValues(alpha: 0.07),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              children: [
                Text(
                  'سُورَةُ ${surah.arabic}',
                  textDirection: TextDirection.rtl,
                  style: AppTheme.quran(size: 30, color: AppColors.goldLight, height: 1.6),
                ),
                const SizedBox(height: 6),
                Text(
                  surah.name,
                  style: AppTheme.display(size: 20, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '${surah.meaning} · ${surah.type} · ${surah.verses} verses',
                  textAlign: TextAlign.center,
                  style: AppTheme.ui(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  width: 140,
                  decoration: const BoxDecoration(gradient: AppGradients.goldRule),
                ),
                if (showsBasmalahHeader(surah.no)) ...[
                  const SizedBox(height: 14),
                  Text(
                    kBasmalah,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: AppTheme.quran(size: 26, color: Colors.white, height: 1.8),
                  ),
                ],
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onPlay,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.emerald950,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Listen to surah'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Verse
// ---------------------------------------------------------------------------

class _VerseTile extends ConsumerWidget {
  const _VerseTile({
    required this.surah,
    required this.verse,
    required this.isCurrent,
    required this.hidden,
    required this.onReveal,
    required this.onPlay,
  });

  final Surah surah;
  final QuranVerse verse;
  final bool isCurrent;
  final bool hidden;
  final VoidCallback onReveal;
  final VoidCallback onPlay;

  String get _reference => '${surah.name} ${surah.no}:${verse.number}';

  String get _shareText =>
      '${verse.arabic}\n\n${verse.translation}\n\n— Qur\'an, $_reference';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reading = ref.watch(quranReadingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookmarked = reading.isBookmarked(surah.no, verse.number);
    final ink = isDark ? AppColors.onDark : AppColors.ink;

    final arabic = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '${verse.arabic} '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _VerseMedallion(number: verse.number),
          ),
        ],
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: AppTheme.quran(size: reading.arabicSize, color: ink),
    );

    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.standard),
      curve: AppMotion.curve,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isCurrent
            ? (isDark ? AppColors.emerald900 : AppColors.emerald50)
            : (isDark ? AppColors.slateCard : AppColors.card),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent
              ? AppColors.gold
              : (isDark ? AppColors.slateLine : AppColors.sand),
          width: isCurrent ? 1.4 : 1,
        ),
        boxShadow: softShadow(context),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    '${surah.no}:${verse.number}',
                    style: AppTheme.ui(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: isDark ? AppColors.goldLight : AppColors.goldDeep,
                    ),
                  ),
                ),
                const Spacer(),
                _VerseAction(
                  icon: isCurrent ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
                  tooltip: 'Play verse ${verse.number}',
                  onTap: onPlay,
                ),
                _VerseAction(
                  icon: bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark verse',
                  active: bookmarked,
                  onTap: () => ref
                      .read(quranReadingProvider.notifier)
                      .toggleBookmark(surah.no, verse.number),
                ),
                _VerseAction(
                  icon: Icons.copy_rounded,
                  tooltip: 'Copy verse',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _shareText));
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$_reference copied')),
                    );
                  },
                ),
                _VerseAction(
                  icon: Icons.ios_share_rounded,
                  tooltip: 'Share verse',
                  onTap: () => Share.share(_shareText, subject: _reference),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (hidden)
              _HiddenVerse(onTap: onReveal, child: arabic)
            else
              GestureDetector(onLongPress: onReveal, child: arabic),
            if (reading.showTranslation && !hidden) ...[
              const SizedBox(height: 12),
              Text(
                verse.translation,
                style: AppTheme.reading(
                  size: 15.5,
                  color: isDark ? AppColors.onDarkMuted : AppColors.ink2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Gold verse-end medallion with Arabic-Indic numerals.
class _VerseMedallion extends StatelessWidget {
  const _VerseMedallion({required this.number});
  final int number;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Verse $number',
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? AppColors.emerald900 : AppColors.goldTint,
          border: Border.all(color: AppColors.gold, width: 1.6),
        ),
        child: Text(
          toArabicDigits(number),
          style: AppTheme.arabic(
            size: number > 99 ? 12 : 14,
            weight: FontWeight.w700,
            height: 1,
            color: isDark ? AppColors.goldLight : AppColors.goldDarkest,
          ),
        ),
      ),
    );
  }
}

class _VerseAction extends StatelessWidget {
  const _VerseAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = active
        ? (isDark ? AppColors.gold : AppColors.goldDeep)
        : (isDark ? AppColors.onDarkSubtle : AppColors.subtle);
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 21, color: color),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// A verse hidden for memorisation: recite it from memory, then tap to check.
class _HiddenVerse extends StatelessWidget {
  const _HiddenVerse({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: 'Hidden verse. Tap to reveal.',
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ExcludeSemantics(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                child: child,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slateRaised : AppColors.card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.gold),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 16,
                    color: isDark ? AppColors.goldLight : AppColors.goldDeep,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Recite, then tap to check',
                    style: AppTheme.ui(
                      size: 12.5,
                      color: isDark ? AppColors.onDark : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoriseBanner extends StatelessWidget {
  const _MemoriseBanner({required this.onRevealAll});
  final VoidCallback onRevealAll;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.goldTint,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
          child: Row(
            children: [
              const Icon(Icons.psychology_rounded, size: 18, color: AppColors.goldDarkest),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Memorisation mode: verses are hidden.',
                  style: AppTheme.ui(size: 13, color: AppColors.goldDarkest),
                ),
              ),
              TextButton(
                onPressed: onRevealAll,
                style: TextButton.styleFrom(foregroundColor: AppColors.goldDarkest),
                child: const Text('Reveal all'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recitation bar
// ---------------------------------------------------------------------------

class _RecitationBar extends ConsumerWidget {
  const _RecitationBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recitationProvider);
    final reciter = ref.watch(quranReadingProvider).reciter;
    final player = ref.read(recitationProvider.notifier);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.emerald,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Verse ${state.verse ?? ''}',
                          style: AppTheme.ui(size: 14, weight: FontWeight.w800, color: Colors.white),
                        ),
                        Text(
                          reciter.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.ui(
                            size: 12,
                            weight: FontWeight.w500,
                            color: AppColors.goldLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _BarButton(
                    icon: Icons.repeat_one_rounded,
                    tooltip: state.repeatVerse ? 'Stop repeating' : 'Repeat verse',
                    active: state.repeatVerse,
                    onTap: player.toggleRepeat,
                  ),
                  _BarButton(
                    icon: Icons.skip_previous_rounded,
                    tooltip: 'Previous verse',
                    onTap: player.previous,
                  ),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: state.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppColors.goldLight,
                            ),
                          )
                        : IconButton.filled(
                            tooltip: state.isPlaying ? 'Pause' : 'Play',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.emerald950,
                            ),
                            icon: Icon(
                              state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 28,
                            ),
                            onPressed: player.togglePlayPause,
                          ),
                  ),
                  _BarButton(
                    icon: Icons.skip_next_rounded,
                    tooltip: 'Next verse',
                    onTap: player.next,
                  ),
                  _BarButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Stop',
                    onTap: player.stop,
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

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(
          icon,
          color: active ? AppColors.goldLight : Colors.white.withValues(alpha: 0.9),
        ),
      );
}

// ---------------------------------------------------------------------------
// Settings sheet
// ---------------------------------------------------------------------------

class _ReadingSettingsSheet extends ConsumerWidget {
  const _ReadingSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reading = ref.watch(quranReadingProvider);
    final notifier = ref.read(quranReadingProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.onDarkMuted : AppColors.muted;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reading settings', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            Text('ARABIC TEXT SIZE', style: AppTheme.eyebrow(muted)),
            Slider(
              value: reading.arabicSize,
              min: 20,
              max: 48,
              divisions: 14,
              label: reading.arabicSize.round().toString(),
              onChanged: notifier.setArabicSize,
            ),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                kBasmalah,
                textAlign: TextAlign.center,
                style: AppTheme.quran(
                  size: reading.arabicSize,
                  color: isDark ? AppColors.onDark : AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show translation'),
              subtitle: const Text('Saheeh International'),
              value: reading.showTranslation,
              onChanged: (_) => notifier.toggleTranslation(),
            ),
            const SizedBox(height: 12),
            Text('RECITER', style: AppTheme.eyebrow(muted)),
            const SizedBox(height: 4),
            RadioGroup<String>(
              groupValue: reading.reciterId,
              onChanged: (id) {
                if (id != null) notifier.setReciter(id);
              },
              child: Column(
                children: [
                  for (final r in kReciters)
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      value: r.id,
                      title: Text(r.name),
                      subtitle: Text(
                        r.arabicName,
                        textDirection: TextDirection.rtl,
                        style: AppTheme.arabic(size: 15, color: muted, height: 1.4),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading / error
// ---------------------------------------------------------------------------

class _ReaderLoading extends StatelessWidget {
  const _ReaderLoading();

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(),
      );
}

class _ReaderError extends StatelessWidget {
  const _ReaderError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: isDark ? AppColors.onDarkSubtle : AppColors.sandDeep,
            ),
            const SizedBox(height: 14),
            Text(
              'This surah is not available offline yet',
              textAlign: TextAlign.center,
              style: AppTheme.ui(size: 16, weight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Connect to the internet once and it will be saved on this '
              'device for offline reading.',
              textAlign: TextAlign.center,
              style: AppTheme.ui(
                size: 13.5,
                weight: FontWeight.w500,
                color: isDark ? AppColors.onDarkMuted : AppColors.muted,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
