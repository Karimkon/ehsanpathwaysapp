import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/core/services/api_service.dart';
import 'package:ehsan_pathways/features/islamic_tools/quran/quran_data.dart';

/// Search every verse of the Qur'an.
///
/// The server does the matching (GET /quran/search) so the app and the
/// website give identical results: Arabic with or without harakat, the word
/// anywhere inside a longer word, every word in any order, 2:255 as a
/// reference, or English against the translation.

class QuranHit {
  final String verseKey;
  final int surah;
  final int verse;
  final String surahName;
  final List<String> words;
  final Set<int> highlight;
  final String translation;
  final List<List<int>> translationHighlight;

  const QuranHit({
    required this.verseKey,
    required this.surah,
    required this.verse,
    required this.surahName,
    required this.words,
    required this.highlight,
    required this.translation,
    required this.translationHighlight,
  });

  factory QuranHit.fromJson(Map<String, dynamic> j) => QuranHit(
        verseKey: j['verse_key'] as String? ?? '',
        surah: (j['surah'] as num?)?.toInt() ?? 1,
        verse: (j['verse_number'] as num?)?.toInt() ?? 1,
        surahName: j['surah_name'] as String? ?? '',
        words: ((j['words'] as List?) ?? const []).map((e) => e.toString()).toList(),
        highlight: ((j['highlight'] as List?) ?? const []).map((e) => (e as num).toInt()).toSet(),
        translation: j['translation'] as String? ?? '',
        translationHighlight: ((j['translation_highlight'] as List?) ?? const [])
            .whereType<List>()
            .map((r) => r.map((e) => (e as num).toInt()).toList())
            .where((r) => r.length == 2)
            .toList(),
      );
}

class QuranSearchResult {
  final String query;
  final int total;
  final int page;
  final int lastPage;
  final int? surah;
  final Map<int, int> bySurah;
  final List<QuranHit> hits;

  const QuranSearchResult({
    required this.query,
    required this.total,
    required this.page,
    required this.lastPage,
    required this.surah,
    required this.bySurah,
    required this.hits,
  });

  factory QuranSearchResult.fromJson(Map<String, dynamic> j) {
    // PHP encodes {"2": 6, "3": 1} as an object, but a single surah 1 entry
    // ({"1": 1}) can arrive as a list. Accept both.
    final raw = j['by_surah'];
    final by = <int, int>{};
    if (raw is Map) {
      raw.forEach((k, v) => by[int.parse(k.toString())] = (v as num).toInt());
    } else if (raw is List) {
      for (var i = 0; i < raw.length; i++) {
        if (raw[i] != null) by[i] = (raw[i] as num).toInt();
      }
    }
    return QuranSearchResult(
      query: j['query'] as String? ?? '',
      total: (j['total'] as num?)?.toInt() ?? 0,
      page: (j['page'] as num?)?.toInt() ?? 1,
      lastPage: (j['last_page'] as num?)?.toInt() ?? 1,
      surah: (j['surah'] as num?)?.toInt(),
      bySurah: by,
      hits: ((j['results'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(QuranHit.fromJson)
          .toList(),
    );
  }
}

class QuranSearchScreen extends ConsumerStatefulWidget {
  const QuranSearchScreen({super.key, this.initialQuery = '', this.initialSurah});
  final String initialQuery;
  final int? initialSurah;

  @override
  ConsumerState<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends ConsumerState<QuranSearchScreen> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialQuery);
  Timer? _debounce;
  int? _surah;
  int _seq = 0;

  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  QuranSearchResult? _result;
  final List<QuranHit> _hits = [];

  @override
  void initState() {
    super.initState();
    _surah = widget.initialSurah;
    if (widget.initialQuery.trim().isNotEmpty) _run();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _run);
  }

  Future<QuranSearchResult> _fetch(String q, int page) async {
    final Dio dio = ref.read(apiProvider);
    final r = await dio.get('/quran/search', queryParameters: {
      'q': q,
      if (_surah != null) 'surah': _surah,
      'page': page,
    });
    return QuranSearchResult.fromJson((r.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  Future<void> _run() async {
    final q = _controller.text.trim();
    final seq = ++_seq;
    if (q.isEmpty) {
      setState(() {
        _result = null;
        _hits.clear();
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _fetch(q, 1);
      if (!mounted || seq != _seq) return; // a newer search has started
      setState(() {
        _result = res;
        _hits
          ..clear()
          ..addAll(res.hits);
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _loading = false;
        _error = e is DioException && e.response == null
            ? 'No connection. Check your internet and try again.'
            : 'Search failed. Please try again.';
      });
    }
  }

  Future<void> _more() async {
    final r = _result;
    if (r == null || _loadingMore || r.page >= r.lastPage) return;
    setState(() => _loadingMore = true);
    final seq = _seq;
    try {
      final res = await _fetch(r.query, r.page + 1);
      if (!mounted || seq != _seq) return;
      setState(() {
        _result = res;
        _hits.addAll(res.hits);
      });
    } catch (_) {
      // Leave what is shown; scrolling again retries.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _pickSurah(int? s) {
    setState(() => _surah = s);
    _run();
  }

  String _surahName(int no) {
    final s = kSurahs.where((x) => x.no == no);
    return s.isEmpty ? 'Surah $no' : s.first.name;
  }

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final ink = d ? AppColors.onDark : AppColors.ink;
    final muted = d ? AppColors.onDarkMuted : AppColors.muted;

    return Scaffold(
      backgroundColor: d ? AppColors.slate : AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.emerald900,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: widget.initialQuery.isEmpty,
          onChanged: _onChanged,
          onSubmitted: (_) {
            _debounce?.cancel();
            _run();
          },
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: Colors.white, fontSize: 17),
          cursorColor: AppColors.goldLight,
          decoration: InputDecoration(
            hintText: 'ابحث · Search every verse',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _controller.clear();
                _run();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_result != null && (_result!.bySurah.length > 1 || _surah != null))
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                children: [
                  _Chip(
                    label: 'All · ${_result!.bySurah.values.fold<int>(0, (a, b) => a + b)}',
                    selected: _surah == null,
                    onTap: () => _pickSurah(null),
                  ),
                  for (final e in _result!.bySurah.entries)
                    _Chip(
                      label: '${e.key}. ${_surahName(e.key)} · ${e.value}',
                      selected: _surah == e.key,
                      onTap: () => _pickSurah(e.key),
                    ),
                ],
              ),
            ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _body(d, ink, muted)),
        ],
      ),
    );
  }

  Widget _body(bool d, Color ink, Color muted) {
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: TextStyle(color: muted)),
          const SizedBox(height: 8),
          FilledButton(onPressed: _run, child: const Text('Try again')),
        ]),
      );
    }

    final r = _result;
    if (r == null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Search the whole Qur\'an', style: AppTheme.ui(size: 17, weight: FontWeight.w700, color: ink)),
          const SizedBox(height: 6),
          Text(
            'Type Arabic with or without harakat, a verse like 2:255, or English. '
            'يحب finds يُحِبُّ, يُحِبُّونَ and every other verse containing it.',
            style: TextStyle(color: muted, height: 1.45),
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final eg in const ['يحب', 'الصبر', 'رحمة', 'الجنة', '2:255', 'patience'])
              ActionChip(
                label: Text(eg),
                onPressed: () {
                  _controller.text = eg;
                  _run();
                },
              ),
          ]),
        ],
      );
    }

    if (r.total == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No verse contains "${r.query}".\nTry fewer words or the root letters (رحم instead of الرحمن).',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, height: 1.5),
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels > n.metrics.maxScrollExtent - 600) _more();
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        itemCount: _hits.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
              child: Text(
                '${r.total} ${r.total == 1 ? 'verse' : 'verses'}'
                '${_surah != null ? ' in ${_surahName(_surah!)}' : (r.bySurah.length > 1 ? ' across ${r.bySurah.length} surahs' : '')}',
                style: TextStyle(color: muted, fontWeight: FontWeight.w600),
              ),
            );
          }
          final h = _hits[i - 1];
          return _HitCard(
            hit: h,
            name: h.surahName.isNotEmpty ? h.surahName : _surahName(h.surah),
            isDark: d,
            onTap: () => context.push('/islamic-tools/quran/${h.surah}?verse=${h.verse}'),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: AppColors.emerald100,
        ),
      );
}

class _HitCard extends StatelessWidget {
  const _HitCard({required this.hit, required this.name, required this.isDark, required this.onTap});
  final QuranHit hit;
  final String name;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.onDark : AppColors.ink;
    final muted = isDark ? AppColors.onDarkMuted : AppColors.muted;
    final mark = isDark ? const Color(0x66D4AF37) : const Color(0xFFFDE68A);

    final arabic = <TextSpan>[];
    for (var i = 0; i < hit.words.length; i++) {
      arabic.add(TextSpan(
        text: hit.words[i],
        style: hit.highlight.contains(i) ? TextStyle(backgroundColor: mark) : null,
      ));
      if (i < hit.words.length - 1) arabic.add(const TextSpan(text: ' '));
    }

    final english = <TextSpan>[];
    var at = 0;
    final t = hit.translation;
    for (final r in hit.translationHighlight) {
      final s = r[0], len = r[1];
      if (s < at || s + len > t.length) continue;
      english.add(TextSpan(text: t.substring(at, s)));
      english.add(TextSpan(text: t.substring(s, s + len), style: TextStyle(backgroundColor: mark)));
      at = s + len;
    }
    english.add(TextSpan(text: t.substring(at.clamp(0, t.length))));

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isDark ? AppColors.slateCard : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.slateLine : AppColors.sand),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(
                  child: Text('$name · ${hit.verseKey}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.emerald400 : AppColors.emerald700)),
                ),
                Icon(Icons.chevron_right_rounded, color: muted),
              ]),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(children: arabic),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: AppTheme.quran(size: 22, color: ink, height: 2.0),
              ),
              if (t.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text.rich(TextSpan(children: english), style: TextStyle(color: muted, height: 1.45, fontSize: 14)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
