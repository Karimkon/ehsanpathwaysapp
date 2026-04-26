import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      backgroundColor: const Color(0xFFF8FAF9),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            title: const Text('Hifz Tracker',
                style: TextStyle(fontWeight: FontWeight.bold)),
            flexibleSpace: FlexibleSpaceBar(
              background: _ProgressHeader(state: state),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
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
              color: Colors.white,
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
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB))),
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
                          color: const Color(0xFF374151),
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
                          color: const Color(0xFF6B7280),
                          onTap: () =>
                              setState(() => _filter = 'not_started'),
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
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red,
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
            'This will clear all your Hifz progress. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(hifzProvider.notifier).resetAll();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Progress has been reset')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, const Color(0xFF14532D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 48),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Memorised',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    '${state.memorisedCount}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold),
                  ),
                  const Text('of 114 surahs',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${state.percentage.round()}% complete',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          '${state.inProgressCount} in progress',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: state.percentage / 100,
                        backgroundColor: Colors.white30,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF15803D);
        break;
      case HifzStatus.inProgress:
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFB45309);
        break;
      case HifzStatus.notStarted:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
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
              fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          dropdownColor: Colors.white,
          icon: Icon(Icons.arrow_drop_down, color: textColor, size: 16),
          items: const [
            DropdownMenuItem(
              value: HifzStatus.notStarted,
              child: Text('Not Started',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            ),
            DropdownMenuItem(
              value: HifzStatus.inProgress,
              child: Text('In Progress',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB45309))),
            ),
            DropdownMenuItem(
              value: HifzStatus.memorised,
              child: Text('Memorised ✓',
                  style: TextStyle(fontSize: 11, color: Color(0xFF15803D))),
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
      final matchFilter = filter == 'all' ||
          (filter == 'memorised' && s.status == HifzStatus.memorised) ||
          (filter == 'in_progress' && s.status == HifzStatus.inProgress) ||
          (filter == 'not_started' && s.status == HifzStatus.notStarted);

      final matchQuery = query.isEmpty ||
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
        child: Text('No surahs match the filter',
            style: TextStyle(color: Color(0xFF9CA3AF))),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: surahs.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final s = surahs[i];
        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        color: AppTheme.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('Juz ${s.juz} · ${s.verses}v',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              // Arabic
              Text(
                s.arabic,
                style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Amiri',
                    color: AppTheme.primaryGreen),
              ),
              const SizedBox(width: 10),
              // Status dropdown
              _StatusDropdown(
                status: s.status,
                onChanged: (v) => onStatusChanged(s.no, v),
              ),
            ],
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
        final memorised =
            surahs.where((s) => s.status == HifzStatus.memorised).length;
        final pct =
            surahs.isEmpty ? 0.0 : memorised / surahs.length;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
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
                      fontSize: 15),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryGreen),
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
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            children: surahs.map((s) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${s.no}.',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    Text(
                      s.arabic,
                      style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'Amiri',
                          color: AppTheme.primaryGreen),
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
