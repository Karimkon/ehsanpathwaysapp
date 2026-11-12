import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/core/providers/auth_provider.dart';
import 'package:ehsan_pathways/core/services/api_service.dart';

Color _card(bool d) => d ? AppColors.slateCard : AppColors.card;
Color _line(bool d) => d ? AppColors.slateLine : AppColors.sand;
Color _ink(bool d) => d ? AppColors.onDark : AppColors.ink;
Color _muted(bool d) => d ? AppColors.onDarkMuted : AppColors.muted;
Color _accent(bool d) => d ? AppColors.emerald400 : AppColors.emerald700;

/// One item the user has shared, with what it did.
class SharedItem {
  const SharedItem({
    required this.type,
    required this.title,
    required this.reached,
    required this.started,
  });

  factory SharedItem.fromJson(Map<String, dynamic> j) => SharedItem(
        type: j['type'] as String? ?? '',
        title: j['title'] as String? ?? '',
        reached: (j['reached'] as num?)?.toInt() ?? 0,
        started: (j['started'] as num?)?.toInt() ?? 0,
      );

  final String type;
  final String title;
  final int reached;
  final int started;

  /// Only pathways and courses have an enrol step to count.
  bool get canStart => type == 'pathway' || type == 'course';

  String get typeLabel => const {
        'verse': "Qur'an verse",
        'article': 'Article',
        'video': 'Video',
        'podcast': 'Podcast',
        'document': 'Book',
        'khutbah': 'Khutbah',
        'pathway': 'Pathway',
        'course': 'Arabic course',
      }[type] ??
      type;
}

class Impact {
  const Impact({
    required this.reached,
    required this.started,
    required this.shared,
    required this.items,
    required this.intention,
    required this.presets,
  });

  factory Impact.fromJson(Map<String, dynamic> j) {
    final intentions = (j['intentions'] as List? ?? const []).cast<Map<String, dynamic>>();
    final general = intentions.where((i) => i['context_type'] == 'general');
    return Impact(
      reached: (j['reached'] as num?)?.toInt() ?? 0,
      started: (j['started'] as num?)?.toInt() ?? 0,
      shared: (j['shared'] as num?)?.toInt() ?? 0,
      items: (j['links'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(SharedItem.fromJson)
          .toList(),
      intention: general.isEmpty ? null : general.first['text'] as String?,
      presets: (j['presets'] as List? ?? const []).cast<String>(),
    );
  }

  final int reached;
  final int started;
  final int shared;
  final List<SharedItem> items;
  final String? intention;
  final List<String> presets;
}

final impactProvider = FutureProvider.autoDispose<Impact>((ref) async {
  final res = await ref.read(apiProvider).get<Map<String, dynamic>>('/me/impact');
  return Impact.fromJson(res.data ?? const {});
});

/// "Whoever guides someone to good has a reward like the one who does it"
/// (Sahih Muslim 1893). Private: only the signed-in user sees their numbers.
class ImpactScreen extends ConsumerWidget {
  const ImpactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final signedIn = ref.watch(authProvider).status == AuthStatus.authenticated;

    return Scaffold(
      appBar: AppBar(title: const Text('My Impact')),
      body: !signedIn
          ? _SignedOut(isDark: d)
          : ref.watch(impactProvider).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Could not load your impact.', style: TextStyle(color: _ink(d))),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => ref.invalidate(impactProvider),
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (impact) => RefreshIndicator(
                  onRefresh: () async => ref.refresh(impactProvider.future),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      Text(
                        '"Whoever guides someone to good has a reward like the one who does it." Sahih Muslim 1893. Only you can see these numbers.',
                        style: TextStyle(fontSize: 13.5, height: 1.45, color: _muted(d)),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _Stat(value: impact.reached, label: impact.reached == 1 ? 'person reached' : 'people reached', isDark: d),
                          const SizedBox(width: 10),
                          _Stat(value: impact.started, label: 'started learning', isDark: d),
                          const SizedBox(width: 10),
                          _Stat(value: impact.shared, label: impact.shared == 1 ? 'thing shared' : 'things shared', isDark: d),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _IntentionCard(current: impact.intention, presets: impact.presets, isDark: d),
                      const SizedBox(height: 22),
                      Text('What you shared',
                          style: GoogleFonts.lora(fontSize: 19, fontWeight: FontWeight.w700, color: _ink(d))),
                      const SizedBox(height: 4),
                      Text(
                        'A person is counted once, the first time they open your link.',
                        style: TextStyle(fontSize: 13, color: _muted(d)),
                      ),
                      const SizedBox(height: 10),
                      if (impact.items.isEmpty)
                        _EmptyShares(isDark: d)
                      else
                        ...impact.items.map((item) => _SharedTile(item: item, isDark: d)),
                    ],
                  ),
                ),
              ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.isDark});

  final int value;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.emerald950 : AppColors.emerald50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _accent(isDark))),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12.5, color: _muted(isDark))),
          ],
        ),
      ),
    );
  }
}

class _SharedTile extends StatelessWidget {
  const _SharedTile({required this.item, required this.isDark});

  final SharedItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line(isDark)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.typeLabel.toUpperCase(),
                    style: TextStyle(fontSize: 11, letterSpacing: 0.6, fontWeight: FontWeight.w600, color: _accent(isDark))),
                const SizedBox(height: 3),
                Text(item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _ink(isDark))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${item.reached} reached',
                  style: TextStyle(fontWeight: FontWeight.w700, color: _ink(isDark))),
              if (item.canStart)
                Text('${item.started} started', style: TextStyle(fontSize: 13, color: _muted(isDark))),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyShares extends StatelessWidget {
  const _EmptyShares({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line(isDark)),
      ),
      child: Column(
        children: [
          Text('Nothing shared yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _ink(isDark))),
          const SizedBox(height: 6),
          Text(
            'Tap Share on any verse, article, video or podcast. Everyone who opens your link shows up here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, height: 1.4, color: _muted(isDark)),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go('/quran'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.emerald700),
            child: const Text("Open the Qur'an"),
          ),
        ],
      ),
    );
  }
}

/// A private niyyah for everything the user does in the app.
/// "Actions are judged by intentions" (Sahih al-Bukhari 1).
class _IntentionCard extends ConsumerStatefulWidget {
  const _IntentionCard({required this.current, required this.presets, required this.isDark});

  final String? current;
  final List<String> presets;
  final bool isDark;

  @override
  ConsumerState<_IntentionCard> createState() => _IntentionCardState();
}

class _IntentionCardState extends ConsumerState<_IntentionCard> {
  late final TextEditingController _text = TextEditingController(text: widget.current ?? '');
  late bool _editing = widget.current == null;
  late String? _saved = widget.current;
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(apiProvider).post('/me/intentions', data: {'context_type': 'general', 'text': text});
      if (!mounted) return;
      setState(() {
        _saved = text;
        _editing = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.isDark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card(d),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line(d)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Your intention',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink(d))),
              ),
              Text('Private', style: TextStyle(fontSize: 12, color: _muted(d))),
            ],
          ),
          const SizedBox(height: 6),
          if (!_editing && _saved != null) ...[
            Text('"$_saved"',
                style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, height: 1.4, color: _ink(d))),
            TextButton(
              onPressed: () => setState(() => _editing = true),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: _accent(d)),
              child: const Text('Renew or change it'),
            ),
          ] else ...[
            Text('Actions are judged by intentions (Sahih al-Bukhari 1). Why do you learn here?',
                style: TextStyle(fontSize: 13.5, height: 1.4, color: _muted(d))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.presets
                  .map((p) => ActionChip(
                        label: Text(p, style: const TextStyle(fontSize: 12.5)),
                        onPressed: () => setState(() => _text.text = p),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _text,
              maxLength: 300,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'In my own words...', counterText: ''),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: AppColors.emerald700),
                child: Text(_saving ? 'Saving...' : 'Save'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.volunteer_activism_rounded, size: 44, color: _accent(isDark)),
            const SizedBox(height: 12),
            Text('See the good you pass on',
                style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: _ink(isDark))),
            const SizedBox(height: 8),
            Text(
              'Sign in and every verse, lesson or video you share shows how many people it reached.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.45, color: _muted(isDark)),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push('/login'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.emerald700),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
