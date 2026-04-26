import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ehsan_pathways/config/theme.dart';

class IslamicToolsScreen extends StatelessWidget {
  const IslamicToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryGreen, const Color(0xFF14532D)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Islamic Tools',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'أدوات إسلامية',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.8),
                            fontFamily: 'Amiri',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionTitle(title: 'Quran & Memorisation'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ToolCard(
                        icon: '📖',
                        title: 'Quran',
                        subtitle: '114 Surahs',
                        color: AppTheme.primaryGreen,
                        onTap: () => context.push('/islamic-tools/quran'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ToolCard(
                        icon: '🗂️',
                        title: 'Hifz Tracker',
                        subtitle: 'Track memorisation',
                        color: const Color(0xFF059669),
                        onTap: () => context.push('/islamic-tools/hifz'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionTitle(title: 'Hadith & Dua'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ToolCard(
                        icon: '📜',
                        title: 'Hadith',
                        subtitle: '4 Collections',
                        color: const Color(0xFF1D4ED8),
                        onTap: () => context.push('/islamic-tools/hadith'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ToolCard(
                        icon: '🤲',
                        title: 'Duas',
                        subtitle: '10 Categories',
                        color: AppTheme.accentGold,
                        onTap: () => context.push('/islamic-tools/dua'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionTitle(title: 'Names & Worship'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ToolCard(
                        icon: '✨',
                        title: "Asma'ul Husna",
                        subtitle: '99 Names of Allah',
                        color: const Color(0xFF7C3AED),
                        onTap: () => context.push('/islamic-tools/asmaul-husna'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ToolCard(
                        icon: '📿',
                        title: 'Tasbih',
                        subtitle: 'Digital dhikr counter',
                        color: const Color(0xFF0891B2),
                        onTap: () => context.push('/islamic-tools/tasbih'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionTitle(title: 'Prayer & Direction'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ToolCard(
                        icon: '🕌',
                        title: 'Prayer Times',
                        subtitle: 'Daily salah schedule',
                        color: const Color(0xFFB45309),
                        onTap: () => context.push('/islamic-tools/prayer-times'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ToolCard(
                        icon: '🧭',
                        title: 'Qibla',
                        subtitle: 'Find the direction',
                        color: const Color(0xFF065F46),
                        onTap: () => context.push('/islamic-tools/qibla'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionTitle(title: 'Calendar'),
                const SizedBox(height: 12),
                _ToolCard(
                  icon: '📅',
                  title: 'Islamic Calendar',
                  subtitle: 'Hijri calendar & Islamic dates',
                  color: const Color(0xFF9D174D),
                  onTap: () => context.push('/islamic-tools/calendar'),
                  wide: true,
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1F2937),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool wide;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: wide
              ? Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(icon, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: color),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(icon, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    return card;
  }
}
