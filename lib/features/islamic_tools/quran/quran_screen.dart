import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/features/islamic_tools/islamic_tools_provider.dart';
import 'package:ehsan_pathways/features/islamic_tools/quran/quran_data.dart';
import 'package:ehsan_pathways/features/islamic_tools/quran/quran_reading.dart';
import 'package:ehsan_pathways/shared/widgets/reading_width.dart';

/// Surah index with "continue reading", bookmarks and search. The index is
/// bundled with the app, so this screen works fully offline.
class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Surah> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return kSurahs;
    String fold(String s) => s.toLowerCase().replaceAll(RegExp(r"[-'\s]"), '');
    final fq = fold(q);
    return kSurahs
        .where((s) =>
            fold(s.name).contains(fq) ||
            s.meaning.toLowerCase().contains(q) ||
            s.arabic.contains(q) ||
            s.no.toString() == q)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reading = ref.watch(quranReadingProvider);
    final surahs = _filtered;
    final showExtras = _query.isEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 168,
            backgroundColor: isDark ? AppColors.slateDeep : AppColors.emerald900,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 72),
              title: Text(
                'Al-Qur\'an',
                style: AppTheme.ui(size: 18, weight: FontWeight.w800, color: Colors.white),
              ),
              background: DecoratedBox(
                decoration: const BoxDecoration(gradient: AppGradients.emerald),
                child: Align(
                  alignment: const Alignment(0.85, -0.1),
                  child: Text(
                    'القرآن الكريم',
                    textDirection: TextDirection.rtl,
                    style: AppTheme.quran(
                      size: 30,
                      color: AppColors.gold.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Padding(
                padding: readingInsets(context, horizontal: 16, bottom: 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: AppTheme.ui(size: 15, weight: FontWeight.w500, color: Colors.white),
                  cursorColor: AppColors.goldLight,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search by name, meaning or number',
                    hintStyle: AppTheme.ui(
                      size: 14,
                      weight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Colors.white.withValues(alpha: 0.85)),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.14),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (showExtras && reading.lastRead != null)
            SliverPadding(
              padding: readingInsets(context, horizontal: 16, top: 16),
              sliver: SliverToBoxAdapter(
                child: _ContinueCard(ref: reading.lastRead!),
              ),
            ),
          if (showExtras && reading.bookmarks.isNotEmpty)
            SliverPadding(
              padding: readingInsets(context, horizontal: 16, top: 12),
              sliver: SliverToBoxAdapter(
                child: _BookmarksStrip(keys: reading.bookmarks),
              ),
            ),
          if (surahs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No surah matches "$_query"',
                  style: AppTheme.ui(
                    size: 14,
                    color: isDark ? AppColors.onDarkMuted : AppColors.muted,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: readingInsets(context, horizontal: 8, top: 8, bottom: 32),
              sliver: SliverList.separated(
                itemCount: surahs.length,
                separatorBuilder: (_, _) => const Divider(indent: 72, endIndent: 8),
                itemBuilder: (context, i) => _SurahTile(surah: surahs[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.ref});
  final VerseRef ref;

  @override
  Widget build(BuildContext context) {
    final surah = surahByNumber(ref.surah);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/islamic-tools/quran/${ref.surah}?verse=${ref.verse}'),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppGradients.emerald,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
            boxShadow: softShadow(context),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.gold,
                ),
                child: const Icon(Icons.menu_book_rounded, color: AppColors.emerald950),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CONTINUE READING', style: AppTheme.eyebrow(AppColors.goldLight)),
                    const SizedBox(height: 4),
                    Text(
                      '${surah.name} · Verse ${ref.verse}',
                      style: AppTheme.ui(size: 16, weight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Text(
                surah.arabic,
                textDirection: TextDirection.rtl,
                style: AppTheme.quran(size: 22, color: AppColors.goldLight, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookmarksStrip extends StatelessWidget {
  const _BookmarksStrip({required this.keys});
  final List<String> keys;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final refs = keys.map(VerseRef.parse).whereType<VerseRef>().take(12).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'BOOKMARKS',
            style: AppTheme.eyebrow(isDark ? AppColors.onDarkMuted : AppColors.muted),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: refs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final r = refs[i];
              return ActionChip(
                avatar: Icon(
                  Icons.bookmark_rounded,
                  size: 16,
                  color: isDark ? AppColors.gold : AppColors.goldDeep,
                ),
                label: Text('${surahByNumber(r.surah).name} ${r.surah}:${r.verse}'),
                onPressed: () =>
                    context.push('/islamic-tools/quran/${r.surah}?verse=${r.verse}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.surah});
  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: () => context.push('/islamic-tools/quran/${surah.no}'),
      leading: _NumberBadge(number: surah.no),
      title: Text(surah.name, style: AppTheme.ui(size: 15.5, weight: FontWeight.w700)),
      subtitle: Text('${surah.meaning} · ${surah.verses} verses'),
      trailing: Text(
        surah.arabic,
        textDirection: TextDirection.rtl,
        style: AppTheme.quran(
          size: 21,
          height: 1.5,
          color: isDark ? AppColors.goldLight : AppColors.emerald900,
        ),
      ),
    );
  }
}

/// Surah number in a gold-edged rotated square, a common mushaf ornament.
class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number});
  final int number;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.785398, // 45°
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? AppColors.emerald900 : AppColors.emerald50,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: AppColors.gold, width: 1.3),
              ),
            ),
          ),
          Text(
            '$number',
            style: AppTheme.ui(
              size: 12.5,
              weight: FontWeight.w800,
              color: isDark ? AppColors.goldLight : AppColors.emerald900,
            ),
          ),
        ],
      ),
    );
  }
}
