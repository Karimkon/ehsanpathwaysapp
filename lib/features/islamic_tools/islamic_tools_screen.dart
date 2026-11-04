import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/features/islamic_tools/calendar/hijri_calendar_screen.dart';
import 'package:ehsan_pathways/shared/widgets/reading_width.dart';

class _Tool {
  const _Tool(this.icon, this.title, this.arabic, this.subtitle, this.route);
  final IconData icon;
  final String title;
  final String arabic;
  final String subtitle;
  final String route;
}

class _Section {
  const _Section(this.title, this.tools);
  final String title;
  final List<_Tool> tools;
}

const _sections = [
  _Section('Qur\'an & Memorisation', [
    _Tool(
      Icons.menu_book_rounded,
      'Qur\'an',
      'القرآن',
      '114 surahs · audio',
      '/islamic-tools/quran',
    ),
    _Tool(
      Icons.psychology_rounded,
      'Hifz',
      'الحفظ',
      'Memorise & track',
      '/islamic-tools/hifz',
    ),
  ]),
  _Section('Hadith & Du\'a', [
    _Tool(
      Icons.auto_stories_rounded,
      'Hadith',
      'الحديث',
      'Authentic collections',
      '/islamic-tools/hadith',
    ),
    _Tool(
      Icons.volunteer_activism_rounded,
      'Du\'a & Adhkar',
      'الدعاء',
      'For every occasion',
      '/islamic-tools/dua',
    ),
  ]),
  _Section('Worship', [
    _Tool(
      Icons.access_time_filled_rounded,
      'Prayer Times',
      'مواقيت الصلاة',
      'Works offline',
      '/islamic-tools/prayer-times',
    ),
    _Tool(
      Icons.explore_rounded,
      'Qibla',
      'القبلة',
      'Direction to the Ka\'bah',
      '/islamic-tools/qibla',
    ),
    _Tool(
      Icons.blur_circular_rounded,
      'Tasbih',
      'التسبيح',
      'Dhikr counter',
      '/islamic-tools/tasbih',
    ),
    _Tool(
      Icons.star_rounded,
      'Asma\'ul Husna',
      'الأسماء الحسنى',
      'The 99 Names',
      '/islamic-tools/names',
    ),
    _Tool(
      Icons.calendar_month_rounded,
      'Hijri Calendar',
      'التقويم الهجري',
      'Dates & sacred days',
      '/islamic-tools/calendar',
    ),
  ]),
];

class IslamicToolsScreen extends StatelessWidget {
  const IslamicToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1000
        ? 4
        : width >= 640
        ? 3
        : 2;
    final hijri = HijriCalendar.now();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 176,
            backgroundColor: AppColors.emerald900,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 20,
                bottom: 16,
              ),
              title: Text(
                'Islamic Tools',
                style: AppTheme.ui(
                  size: 19,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              background: DecoratedBox(
                decoration: const BoxDecoration(gradient: AppGradients.emerald),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 52),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            '${hijri.hDay} ${kHijriMonthsEnglish[hijri.hMonth - 1]} ${hijri.hYear} AH',
                            style: AppTheme.ui(
                              size: 13,
                              weight: FontWeight.w600,
                              color: AppColors.goldLight,
                            ),
                          ),
                        ),
                        Text(
                          'أدوات إسلامية',
                          textDirection: TextDirection.rtl,
                          style: AppTheme.arabic(
                            size: 24,
                            weight: FontWeight.w700,
                            color: AppColors.gold.withValues(alpha: 0.9),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          for (final section in _sections) ...[
            SliverPadding(
              padding: readingInsets(
                context,
                horizontal: 20,
                top: 24,
                bottom: 10,
                maxWidth: 1100,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  section.title.toUpperCase(),
                  style: AppTheme.eyebrow(
                    isDark ? AppColors.onDarkMuted : AppColors.muted,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: readingInsets(context, horizontal: 16, maxWidth: 1100),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 148,
                ),
                itemCount: section.tools.length,
                itemBuilder: (context, i) => _ToolCard(tool: section.tools[i]),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool});
  final _Tool tool;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: '${tool.title}. ${tool.subtitle}',
      excludeSemantics: true,
      child: Material(
        color: isDark ? AppColors.slateCard : AppColors.card,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            HapticFeedback.selectionClick();
            context.push(tool.route);
          },
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? AppColors.slateLine : AppColors.sand,
              ),
              boxShadow: softShadow(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: AppGradients.emerald,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Icon(
                        tool.icon,
                        color: AppColors.goldLight,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      flex: 3,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          tool.arabic,
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          style: AppTheme.arabic(
                            size: 16,
                            height: 1.4,
                            color: isDark ? AppColors.gold : AppColors.goldDeep,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  tool.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.ui(size: 15.5, weight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  tool.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.ui(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: isDark ? AppColors.onDarkMuted : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
