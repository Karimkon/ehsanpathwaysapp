import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/features/islamic_tools/names/asma_ul_husna_data.dart';
import 'package:ehsan_pathways/shared/widgets/reading_width.dart';

/// The Most Beautiful Names, as a responsive grid of cards.
class AsmaUlHusnaScreen extends StatefulWidget {
  const AsmaUlHusnaScreen({super.key});

  @override
  State<AsmaUlHusnaScreen> createState() => _AsmaUlHusnaScreenState();
}

class _AsmaUlHusnaScreenState extends State<AsmaUlHusnaScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final q = _query.trim().toLowerCase();
    final names = q.isEmpty
        ? kAsmaUlHusna
        : kAsmaUlHusna
              .where(
                (n) =>
                    n.transliteration.toLowerCase().contains(q) ||
                    n.meaning.toLowerCase().contains(q) ||
                    n.arabic.contains(q) ||
                    '${n.number}' == q,
              )
              .toList();
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1000
        ? 4
        : width >= 680
        ? 3
        : 2;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 236 + MediaQuery.paddingOf(context).top,
            backgroundColor: AppColors.emerald900,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            title: const Text("Asma'ul Husna"),
            flexibleSpace: FlexibleSpaceBar(
              background: DecoratedBox(
                decoration: const BoxDecoration(gradient: AppGradients.emerald),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
                    child: FitHeader(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'وَلِلَّهِ الْأَسْمَاءُ الْحُسْنَىٰ فَادْعُوهُ بِهَا',
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: AppTheme.quran(
                              size: 24,
                              color: AppColors.goldLight,
                              height: 1.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '"And to Allah belong the best names, so invoke Him by them." (7:180)',
                            textAlign: TextAlign.center,
                            style: AppTheme.reading(
                              size: 13.5,
                              color: Colors.white.withValues(alpha: 0.88),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: readingInsets(
              context,
              horizontal: 16,
              top: 16,
              maxWidth: 1100,
            ),
            sliver: SliverToBoxAdapter(
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search by name or meaning',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: readingInsets(
              context,
              horizontal: 16,
              top: 16,
              bottom: 16,
              maxWidth: 1100,
            ),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 168,
              ),
              itemCount: names.length,
              itemBuilder: (context, i) => _NameCard(name: names[i]),
            ),
          ),
          SliverPadding(
            padding: readingInsets(
              context,
              horizontal: 20,
              bottom: 40,
              maxWidth: 1100,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                'The Prophet ﷺ said that Allah has ninety-nine names, and whoever '
                'learns and acts upon them will enter Paradise (al-Bukhari 2736, '
                'Muslim 2677). This enumeration is the well-known one narrated by '
                'at-Tirmidhi (3507); many scholars hold that the list itself was '
                'added by a narrator. Allah\'s names are not limited to ninety-nine.',
                style: AppTheme.ui(
                  size: 12.5,
                  weight: FontWeight.w500,
                  height: 1.55,
                  color: isDark ? AppColors.onDarkMuted : AppColors.muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameCard extends StatelessWidget {
  const _NameCard({required this.name});
  final DivineName name;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.slateCard : AppColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onLongPress: () => Share.share(
          '${name.arabic}\n${name.transliteration}: ${name.meaning}',
        ),
        onTap: () {
          Clipboard.setData(
            ClipboardData(
              text: '${name.arabic} (${name.transliteration}): ${name.meaning}',
            ),
          );
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${name.transliteration} copied')),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.slateLine : AppColors.sand,
            ),
            boxShadow: softShadow(context),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  '${name.number}',
                  style: AppTheme.ui(
                    size: 11.5,
                    weight: FontWeight.w800,
                    color: isDark ? AppColors.gold : AppColors.goldDeep,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      name.arabic,
                      textDirection: TextDirection.rtl,
                      style: AppTheme.arabic(
                        size: 30,
                        weight: FontWeight.w700,
                        height: 1.5,
                        color: isDark
                            ? AppColors.goldLight
                            : AppColors.emerald900,
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                name.transliteration,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.ui(size: 14, weight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                name.meaning,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.ui(
                  size: 12,
                  weight: FontWeight.w500,
                  color: isDark ? AppColors.onDarkMuted : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
