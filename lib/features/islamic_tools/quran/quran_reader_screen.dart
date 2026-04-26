import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/features/islamic_tools/islamic_tools_provider.dart';

class QuranReaderScreen extends ConsumerStatefulWidget {
  final int surahNo;
  const QuranReaderScreen({super.key, required this.surahNo});

  @override
  ConsumerState<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends ConsumerState<QuranReaderScreen> {
  double _fontSize = 22;

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(quranSurahsProvider);

    return surahsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('$e')),
      ),
      data: (surahs) {
        final surah = surahs.firstWhere(
          (s) => s.no == widget.surahNo,
          orElse: () => surahs.first,
        );

        return Scaffold(
          backgroundColor: const Color(0xFFFAFDF8),
          appBar: AppBar(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(surah.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Surah ${surah.no} · ${surah.verses} verses',
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.text_decrease_rounded),
                onPressed: () =>
                    setState(() => _fontSize = (_fontSize - 2).clamp(14, 36)),
                tooltip: 'Decrease font',
              ),
              IconButton(
                icon: const Icon(Icons.text_increase_rounded),
                onPressed: () =>
                    setState(() => _fontSize = (_fontSize + 2).clamp(14, 36)),
                tooltip: 'Increase font',
              ),
            ],
          ),
          body: _QuranContent(surah: surah, fontSize: _fontSize),
        );
      },
    );
  }
}

class _QuranContent extends ConsumerWidget {
  final Surah surah;
  final double fontSize;

  const _QuranContent({required this.surah, required this.fontSize});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versesAsync = ref.watch(quranVersesProvider(surah.no));

    return versesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          const Text('Could not load verses',
              style: TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => ref.invalidate(quranVersesProvider(surah.no)),
            child: const Text('Retry'),
          ),
        ]),
      ),
      data: (verses) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: verses.length + 1, // +1 for bismillah header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _SurahHeader(surah: surah);
          }
          final verse = verses[index - 1];
          return _VerseCard(
            verse: verse,
            surahNo: surah.no,
            fontSize: fontSize,
          );
        },
      ),
    );
  }
}

class _SurahHeader extends StatelessWidget {
  final Surah surah;
  const _SurahHeader({required this.surah});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, const Color(0xFF14532D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            surah.arabic,
            style: const TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontFamily: 'Amiri',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            surah.name,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            surah.meaning,
            style: TextStyle(
                fontSize: 13, color: Colors.white.withOpacity(0.75)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontFamily: 'Amiri',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  final QuranVerse verse;
  final int surahNo;
  final double fontSize;

  const _VerseCard({
    required this.verse,
    required this.surahNo,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Verse number chip
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$surahNo:${verse.number}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Arabic text
          Text(
            verse.arabic,
            style: TextStyle(
              fontSize: fontSize,
              height: 1.8,
              fontFamily: 'Amiri',
              color: const Color(0xFF111827),
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // Translation
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              verse.translation,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
