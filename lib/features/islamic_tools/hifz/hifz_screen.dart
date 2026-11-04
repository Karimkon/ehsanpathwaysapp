import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/features/islamic_tools/islamic_tools_provider.dart';

class HifzScreen extends ConsumerStatefulWidget {
  const HifzScreen({super.key});

  @override
  ConsumerState<HifzScreen> createState() => _HifzScreenState();
}

class _HifzScreenState extends ConsumerState<HifzScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'all'; // all | memorised | in_progress | not_started
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hifzProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 232 + MediaQuery.paddingOf(context).top,
            pinned: true,
            backgroundColor: AppColors.emerald900,
            foregroundColor: Colors.white,
            title: const Text('Hifz Tracker'),
            flexibleSpace: FlexibleSpaceBar(
              background: _ProgressHeader(state: state),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.gold,
              labelColor: AppColors.goldLight,
              unselectedLabelColor: Colors.white70,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'List View'),
                Tab(text: 'By Juz'),
              ],
            ),
          ),
        ],
        body: Column(
          children: [
            // Filter + search bar
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                children: [
                  // Search
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search surahs...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.sand),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.sand),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          count: state.surahs.length,
                          selected: _filter == 'all',
                          color: AppColors.ink2,
                          onTap: () => setState(() => _filter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Memorised',
                          count: state.memorisedCount,
                          selected: _filter == 'memorised',
                          color: AppTheme.primaryGreen,
                          onTap: () => setState(() => _filter = 'memorised'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'In Progress',
                          count: state.inProgressCount,
                          selected: _filter == 'in_progress',
                          color: AppTheme.accentGold,
                          onTap: () => setState(() => _filter = 'in_progress'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Not Started',
                          count: state.notStartedCount,
                          selected: _filter == 'not_started',
                          color: AppColors.muted,
                          onTap: () => setState(() => _filter = 'not_started'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ListView(
                    state: state,
                    filter: _filter,
                    query: _query,
                    onStatusChanged: (no, status) =>
                        ref.read(hifzProvider.notifier).setStatus(no, status),
                  ),
                  _JuzView(
                    state: state,
                    filter: _filter,
                    query: _query,
                    onStatusChanged: (no, status) =>
                        ref.read(hifzProvider.notifier).setStatus(no, status),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showResetDialog(context),
        backgroundColor: AppColors.dangerTint,
        foregroundColor: AppColors.danger,
        elevation: 0,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Reset', style: TextStyle(fontSize: 13)),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text(
          'This will clear all your Hifz progress. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(hifzProvider.notifier).resetAll();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Progress has been reset')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

// ─── Progress header ─────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  final HifzState state;
  const _ProgressHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final pct = (state.verseFraction * 100);
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.emerald),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 56),
          child: Center(
            child: FitHeader(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Row(
                  children: [
                    _ProgressRing(
                      memorised: state.verseFraction,
                      inProgress: state.inProgressFraction,
                      label: pct >= 10
                          ? '${pct.round()}%'
                          : '${pct.toStringAsFixed(1)}%',
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OF THE QUR\'AN MEMORISED',
                            style: AppTheme.eyebrow(AppColors.goldLight),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${state.memorisedVerses} of ${state.totalVerses} verses',
                            style: AppTheme.ui(
                              size: 16,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${state.memorisedCount} surahs memorised · '
                            '${state.inProgressCount} in progress',
                            style: AppTheme.ui(
                              size: 12.5,
                              weight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-arc ring: gold for memorised, a paler arc for in progress.
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.memorised,
    required this.inProgress,
    required this.label,
  });

  final double memorised;
  final double inProgress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label of the Quran memorised',
      child: SizedBox(
        width: 92,
        height: 92,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: AppMotion.of(context, const Duration(milliseconds: 900)),
          curve: AppMotion.curve,
          builder: (context, t, _) => CustomPaint(
            painter: _RingPainter(memorised * t, inProgress * t),
            child: Center(
              child: Text(
                label,
                style: AppTheme.ui(
                  size: 18,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.memorised, this.inProgress);
  final double memorised;
  final double inProgress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    const start = -1.5708; // 12 o'clock
    const full = 6.28318;
    Paint arc(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = c;

    canvas.drawArc(
      arcRect,
      0,
      full,
      false,
      arc(Colors.white.withValues(alpha: 0.14)),
    );
    if (inProgress > 0) {
      canvas.drawArc(
        arcRect,
        start + full * memorised,
        full * inProgress,
        false,
        arc(AppColors.goldLight.withValues(alpha: 0.45)),
      );
    }
    if (memorised > 0) {
      canvas.drawArc(
        arcRect,
        start,
        full * memorised,
        false,
        arc(AppColors.gold)..shader = AppGradients.gold.createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.memorised != memorised || old.inProgress != inProgress;
}

// ─── Filter chip ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

// ─── Status dropdown ─────────────────────────────────────────────────────────

class _StatusDropdown extends StatelessWidget {
  final HifzStatus status;
  final ValueChanged<HifzStatus> onChanged;

  const _StatusDropdown({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case HifzStatus.memorised:
        bgColor = AppColors.emerald100;
        textColor = AppColors.emerald800;
        break;
      case HifzStatus.inProgress:
        bgColor = AppColors.goldTint;
        textColor = AppColors.goldDeep;
        break;
      case HifzStatus.notStarted:
        bgColor = AppColors.creamDeep;
        textColor = AppColors.muted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<HifzStatus>(
          value: status,
          isDense: true,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          dropdownColor: Colors.white,
          icon: Icon(Icons.arrow_drop_down, color: textColor, size: 16),
          items: const [
            DropdownMenuItem(
              value: HifzStatus.notStarted,
              child: Text(
                'Not Started',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ),
            DropdownMenuItem(
              value: HifzStatus.inProgress,
              child: Text(
                'In Progress',
                style: TextStyle(fontSize: 11, color: AppColors.goldDeep),
              ),
            ),
            DropdownMenuItem(
              value: HifzStatus.memorised,
              child: Text(
                'Memorised ✓',
                style: TextStyle(fontSize: 11, color: AppColors.emerald800),
              ),
            ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ─── List view ───────────────────────────────────────────────────────────────

class _ListView extends StatelessWidget {
  final HifzState state;
  final String filter;
  final String query;
  final void Function(int no, HifzStatus status) onStatusChanged;

  const _ListView({
    required this.state,
    required this.filter,
    required this.query,
    required this.onStatusChanged,
  });

  List<HifzSurah> get _filtered {
    return state.surahs.where((s) {
      final matchFilter =
          filter == 'all' ||
          (filter == 'memorised' && s.status == HifzStatus.memorised) ||
          (filter == 'in_progress' && s.status == HifzStatus.inProgress) ||
          (filter == 'not_started' && s.status == HifzStatus.notStarted);

      final matchQuery =
          query.isEmpty ||
          s.name.toLowerCase().contains(query) ||
          s.arabic.contains(query) ||
          s.no.toString() == query;

      return matchFilter && matchQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final surahs = _filtered;
    if (surahs.isEmpty) {
      return const Center(
        child: Text(
          'No surahs match the filter',
          style: TextStyle(color: AppColors.subtle),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: surahs.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final s = surahs[i];
        // Tap a surah to practise it with verses hidden.
        return InkWell(
          onTap: () => context.push('/islamic-tools/quran/${s.no}?mode=hifz'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Number
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(
                      '${s.no}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Juz ${s.juz} · ${s.verses}v',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.subtle,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arabic
                Text(
                  s.arabic,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: AppTheme.arabicFamily,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 10),
                // Status dropdown
                _StatusDropdown(
                  status: s.status,
                  onChanged: (v) => onStatusChanged(s.no, v),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Juz view ────────────────────────────────────────────────────────────────

class _JuzView extends StatelessWidget {
  final HifzState state;
  final String filter;
  final String query;
  final void Function(int no, HifzStatus status) onStatusChanged;

  const _JuzView({
    required this.state,
    required this.filter,
    required this.query,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Group by juz
    final Map<int, List<HifzSurah>> groups = {};
    for (final s in state.surahs) {
      groups.putIfAbsent(s.juz, () => []).add(s);
    }
    final juzList = groups.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: juzList.length,
      itemBuilder: (context, index) {
        final juzNo = juzList[index];
        final surahs = groups[juzNo]!;
        final memorised = surahs
            .where((s) => s.status == HifzStatus.memorised)
            .length;
        final pct = surahs.isEmpty ? 0.0 : memorised / surahs.length;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.sand),
          ),
          child: ExpansionTile(
            shape: const Border(),
            tilePadding: const EdgeInsets.symmetric(horizontal: 14),
            title: Row(
              children: [
                Text(
                  'Juz $juzNo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: AppColors.sand,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryGreen,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(pct * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            children: surahs.map((s) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      '${s.no}.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.subtle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      s.arabic,
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: AppTheme.arabicFamily,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusDropdown(
                      status: s.status,
                      onChanged: (v) => onStatusChanged(s.no, v),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
