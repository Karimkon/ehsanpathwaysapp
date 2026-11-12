import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/core/providers/auth_provider.dart';
import 'package:ehsan_pathways/core/services/guided_share.dart';
import 'package:ehsan_pathways/features/daily/daily_deed_provider.dart';

Color _card(bool d) => d ? AppColors.slateCard : AppColors.card;
Color _line(bool d) => d ? AppColors.slateLine : AppColors.sand;
Color _ink(bool d) => d ? AppColors.onDark : AppColors.ink;
Color _muted(bool d) => d ? AppColors.onDarkMuted : AppColors.muted;
Color _accent(bool d) => d ? AppColors.emerald400 : AppColors.emerald700;

/// Two minutes a day: one verse, one dhikr, one du'a.
/// "The most beloved deeds to Allah are the most consistent, even if small"
/// (Sahih al-Bukhari 6464). There is no streak to lose: the month record only
/// counts the days that were done.
class DailyDeedScreen extends ConsumerWidget {
  const DailyDeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final signedIn = ref.watch(authProvider).status == AuthStatus.authenticated;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Deed')),
      body: ref.watch(dailyDeedProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 40, color: _muted(d)),
                    const SizedBox(height: 12),
                    Text("Today's deed needs a connection.", style: TextStyle(color: _ink(d))),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: () => ref.invalidate(dailyDeedProvider), child: const Text('Try again')),
                  ],
                ),
              ),
            ),
            data: (deed) => RefreshIndicator(
              onRefresh: () async => ref.refresh(dailyDeedProvider.future),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Text(
                    signedIn ? '${deed.doneCount} of 3 done today' : "Today's two minutes",
                    style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.w700, color: _ink(d)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"The most beloved deeds to Allah are the most consistent, even if small." Sahih al-Bukhari 6464',
                    style: TextStyle(fontSize: 13, height: 1.4, color: _muted(d)),
                  ),
                  const SizedBox(height: 16),
                  _VerseCard(part: 'verse', label: 'Reflect on a verse', button: 'I read and reflected', verse: deed.verse, done: deed.done['verse']!, signedIn: signedIn, isDark: d),
                  _DhikrCard(dhikr: deed.dhikr, done: deed.done['dhikr']!, signedIn: signedIn, isDark: d),
                  _VerseCard(part: 'dua', label: "Make a du'a", button: "I made this du'a", verse: deed.dua, done: deed.done['dua']!, signedIn: signedIn, isDark: d),
                  if (!signedIn)
                    Card(
                      color: d ? AppColors.emerald950 : AppColors.emerald50,
                      child: ListTile(
                        title: Text('Sign in to tick each part and keep a private record of your month.',
                            style: TextStyle(fontSize: 13.5, color: _ink(d))),
                        trailing: TextButton(onPressed: () => context.push('/login'), child: const Text('Sign in')),
                      ),
                    ),
                  if (deed.month != null) _MonthCard(month: deed.month!, date: deed.date, isDark: d),
                  _ReminderCard(isDark: d),
                ],
              ),
            ),
          ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.label, required this.done, required this.isDark, required this.children});

  final String label;
  final bool done;
  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: done ? _accent(isDark) : _line(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label.toUpperCase(),
                    style: TextStyle(fontSize: 11.5, letterSpacing: 0.6, fontWeight: FontWeight.w700, color: _accent(isDark))),
              ),
              if (done)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: _accent(isDark)),
                  const SizedBox(width: 4),
                  Text('Done', style: TextStyle(fontWeight: FontWeight.w700, color: _accent(isDark))),
                ]),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

Widget _arabic(String text, bool d) => Text(
      text,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      style: AppTheme.arabic(size: 24, height: 2.0, color: _ink(d)),
    );

class _DoneButton extends ConsumerStatefulWidget {
  const _DoneButton({required this.part, required this.label});

  final String part;
  final String label;

  @override
  ConsumerState<_DoneButton> createState() => _DoneButtonState();
}

class _DoneButtonState extends ConsumerState<_DoneButton> {
  bool _busy = false;

  Future<void> _tap() async {
    setState(() => _busy = true);
    try {
      await ref.read(dailyDeedActionsProvider)(widget.part);
      HapticFeedback.lightImpact();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FilledButton(
          onPressed: _busy ? null : _tap,
          style: FilledButton.styleFrom(backgroundColor: AppColors.emerald700),
          child: Text(_busy ? 'Saving...' : widget.label),
        ),
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  const _VerseCard({required this.part, required this.label, required this.button, required this.verse, required this.done, required this.signedIn, required this.isDark});

  final String part;
  final String label;
  final String button;
  final DeedVerse verse;
  final bool done;
  final bool signedIn;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final d = isDark;
    return _Frame(
      label: label,
      done: done,
      isDark: d,
      children: [
        if (verse.arabic != null && verse.arabic!.isNotEmpty) _arabic(verse.arabic!, d),
        if (verse.translation != null && verse.translation!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(verse.translation!, style: TextStyle(fontSize: 15, height: 1.55, color: _ink(d))),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () => context.push('/islamic-tools/quran/${verse.surah}?verse=${verse.ayah}'),
              icon: const Icon(Icons.menu_book_rounded, size: 18),
              label: Text("Qur'an ${verse.reference}"),
              style: TextButton.styleFrom(foregroundColor: _accent(d), padding: EdgeInsets.zero),
            ),
            IconButton(
              tooltip: 'Share',
              icon: Icon(Icons.ios_share_rounded, size: 20, color: _muted(d)),
              onPressed: () => GuidedShare.share(
                context,
                type: 'verse',
                key: verse.key,
                fallbackPath: '/quran/${verse.surah}#v${verse.ayah}',
                subject: "Qur'an ${verse.reference}",
                text: (url) => [
                  if (verse.arabic != null) verse.arabic!,
                  if (verse.translation != null) verse.translation!,
                  "Qur'an ${verse.reference}",
                  url,
                ].join('\n\n'),
              ),
            ),
          ],
        ),
        if (signedIn && !done) _DoneButton(part: part, label: button),
      ],
    );
  }
}

/// The dhikr, with a counter to tap through the number the Sunnah names.
class _DhikrCard extends ConsumerStatefulWidget {
  const _DhikrCard({required this.dhikr, required this.done, required this.signedIn, required this.isDark});

  final DeedDhikr dhikr;
  final bool done;
  final bool signedIn;
  final bool isDark;

  @override
  ConsumerState<_DhikrCard> createState() => _DhikrCardState();
}

class _DhikrCardState extends ConsumerState<_DhikrCard> {
  int _count = 0;

  Future<void> _tap() async {
    if (_count >= widget.dhikr.count) return;
    setState(() => _count++);
    HapticFeedback.selectionClick();
    if (_count == widget.dhikr.count && widget.signedIn && !widget.done) {
      try {
        await ref.read(dailyDeedActionsProvider)('dhikr');
      } catch (_) {
        // The Done button below remains as a fallback.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.isDark;
    final x = widget.dhikr;
    final complete = _count >= x.count;
    return _Frame(
      label: 'Remember Allah',
      done: widget.done,
      isDark: d,
      children: [
        _arabic(x.arabic, d),
        const SizedBox(height: 6),
        Text(x.transliteration, style: TextStyle(fontStyle: FontStyle.italic, color: _muted(d))),
        const SizedBox(height: 6),
        Text(x.translation, style: TextStyle(fontSize: 15, height: 1.55, color: _ink(d))),
        const SizedBox(height: 8),
        Text('${x.virtue} (${x.source})', style: TextStyle(fontSize: 13, height: 1.45, color: _muted(d))),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: complete ? null : _tap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            foregroundColor: _accent(d),
            side: BorderSide(color: _accent(d)),
          ),
          child: Text(complete ? 'Completed $_count of ${x.count}' : 'Tap to count  $_count / ${x.count}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        if (widget.signedIn && !widget.done && !complete) const _DoneButton(part: 'dhikr', label: 'I said it'),
      ],
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.month, required this.date, required this.isDark});

  final DeedMonth month;
  final String date;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final d = isDark;
    final today = DateTime.tryParse(date) ?? DateTime.now();
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card(d), borderRadius: BorderRadius.circular(16), border: Border.all(color: _line(d))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(month.label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink(d))),
          const SizedBox(height: 4),
          Text(
            'Something on ${month.activeDays} of ${month.daysSoFar} days, all three on ${month.completeDays}. A missed day takes nothing away. Only you can see this.',
            style: TextStyle(fontSize: 13, height: 1.45, color: _muted(d)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var day = 1; day <= daysInMonth; day++)
                Builder(builder: (_) {
                  final key = localDate(DateTime(today.year, today.month, day));
                  final parts = month.partsByDate[key] ?? 0;
                  return Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      color: parts == 3
                          ? AppColors.emerald700
                          : parts > 0
                              ? (d ? AppColors.emerald900 : AppColors.emerald100)
                              : (d ? AppColors.slateLine : AppColors.creamDeep),
                    ),
                    child: Text('$day',
                        style: TextStyle(fontSize: 11, color: parts == 3 ? Colors.white : _muted(d))),
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatefulWidget {
  const _ReminderCard({required this.isDark});

  final bool isDark;

  @override
  State<_ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<_ReminderCard> {
  String? _choice;

  @override
  void initState() {
    super.initState();
    DeedReminder.load().then((c) {
      if (mounted) setState(() => _choice = c);
    });
  }

  Future<void> _set(String choice) async {
    setState(() => _choice = choice);
    final ok = await DeedReminder.save(choice);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? (choice == 'Off' ? 'Reminder off.' : 'You will be reminded ${choice.toLowerCase()}, in sha Allah.')
          : 'Set your location in Prayer Times first, so the reminder follows your prayer times.'),
      action: ok ? null : SnackBarAction(label: 'Open', onPressed: () => context.push('/islamic-tools/prayer-times')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.isDark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card(d), borderRadius: BorderRadius.circular(16), border: Border.all(color: _line(d))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Remind me', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink(d))),
          const SizedBox(height: 4),
          Text('Tie it to a prayer you already pray. The reminder comes 20 minutes after it, on your own prayer times.',
              style: TextStyle(fontSize: 13, height: 1.45, color: _muted(d))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: deedReminderChoices.keys
                .map((c) => ChoiceChip(label: Text(c), selected: _choice == c, onSelected: (_) => _set(c)))
                .toList(),
          ),
        ],
      ),
    );
  }
}
