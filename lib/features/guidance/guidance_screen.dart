import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/core/providers/auth_provider.dart';
import 'package:ehsan_pathways/features/guidance/guidance_provider.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';

Future<void> _call() async {
  final uri = Uri(scheme: 'tel', path: guidancePhone);
  if (await canLaunchUrl(uri)) await launchUrl(uri);
}

Color _ground(bool d) => d ? AppColors.slate : AppColors.cream;
Color _card(bool d) => d ? AppColors.slateCard : AppColors.card;
Color _line(bool d) => d ? AppColors.slateLine : AppColors.sand;
Color _ink(bool d) => d ? AppColors.onDark : AppColors.ink;
Color _muted(bool d) => d ? AppColors.onDarkMuted : AppColors.muted;
Color _accent(bool d) => d ? AppColors.emerald400 : AppColors.emerald700;

AppBar _bar(BuildContext context, String title, bool d) => AppBar(
      title: Text(title, style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.w700)),
      centerTitle: false,
      backgroundColor: _ground(d),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.canPop() ? context.pop() : context.go('/'),
      ),
    );

// ===========================================================================
// Landing: what would you like guidance about?
// ===========================================================================

class GuidanceScreen extends ConsumerWidget {
  const GuidanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final signedIn = ref.watch(authProvider).status == AuthStatus.authenticated;

    return Scaffold(
      backgroundColor: _ground(d),
      appBar: _bar(context, 'Seek Guidance', d),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myGuidanceProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            _Hero(),
            const SizedBox(height: 24),
            Text('What would you like guidance about?',
                style: GoogleFonts.lora(fontSize: 19, fontWeight: FontWeight.w700, color: _ink(d))),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.45,
              children: [
                for (final t in guidanceTopics)
                  _TopicTile(topic: t, isDark: d, onTap: () => context.push('/guidance/new?topic=${t.key}')),
              ],
            ),
            const SizedBox(height: 20),
            _Panel(
              isDark: d,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Need personal guidance?',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _ink(d))),
                  const SizedBox(height: 6),
                  Text(
                    'Submit your concern privately. Our team will review it and direct you to an appropriate person for assistance.',
                    style: TextStyle(fontSize: 14, height: 1.45, color: _muted(d)),
                  ),
                  const SizedBox(height: 10),
                  const _Pill('No payment required'),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/guidance/new'),
                      icon: const Icon(Icons.lock_outline_rounded, size: 18),
                      label: const Text('Submit privately'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emerald700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _call,
                      icon: const Icon(Icons.call_outlined, size: 18),
                      label: const Text('Prefer to talk? 0727 184 694'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _accent(d),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (signedIn) ...[
              const SizedBox(height: 24),
              Text('Your requests', style: GoogleFonts.lora(fontSize: 19, fontWeight: FontWeight.w700, color: _ink(d))),
              const SizedBox(height: 10),
              const _MyRequests(),
            ],
            const SizedBox(height: 24),
            _HowItWorks(isDark: d),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.emerald900, AppColors.emerald700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("You don't have to navigate life's challenges alone.",
              style: GoogleFonts.lora(fontSize: 22, height: 1.25, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 10),
          Text(
            "Find guidance through the Qur'an and authentic Sunnah, supported by knowledgeable and trusted people.",
            style: TextStyle(fontSize: 14.5, height: 1.45, color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 12),
          const _Pill('Always free', onDark: true),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {this.onDark = false});
  final String text;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.12) : AppColors.emerald50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: onDark ? AppColors.emerald300 : AppColors.emerald700)),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.isDark, required this.child});
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _line(isDark)),
        ),
        child: child,
      );
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.topic, required this.isDark, required this.onTap});
  final GuidanceTopic topic;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _card(isDark),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _line(isDark)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(topic.icon, color: _accent(isDark), size: 22),
              Text(topic.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, height: 1.2, color: _ink(isDark))),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyRequests extends ConsumerWidget {
  const _MyRequests();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final async = ref.watch(myGuidanceProvider);

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _Panel(
        isDark: d,
        child: Row(children: [
          Expanded(child: Text(guidanceError(e), style: TextStyle(color: _muted(d)))),
          TextButton(onPressed: () => ref.invalidate(myGuidanceProvider), child: const Text('Retry')),
        ]),
      ),
      data: (items) => items.isEmpty
          ? _Panel(isDark: d, child: Text("You haven't asked for guidance yet.", style: TextStyle(color: _muted(d))))
          : Column(
              children: [
                for (final g in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: _card(d),
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: _line(d)),
                        ),
                        leading: Icon(topicFor(g.topic).icon, color: _accent(d)),
                        title: Text('${g.topicLabel} · ${g.reference}',
                            style: TextStyle(fontWeight: FontWeight.w600, color: _ink(d), fontSize: 14.5)),
                        subtitle: Text(g.concern, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: _muted(d))),
                        trailing: _StateChip(g),
                        onTap: () => context.push('/guidance/r/${g.uuid}'),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip(this.g);
  final GuidanceRequest g;

  @override
  Widget build(BuildContext context) {
    final waiting = g.awaitingAdviser && !g.isClosed;
    final bg = g.isClosed ? AppColors.sand : (waiting ? AppColors.goldTint : AppColors.emerald50);
    final fg = g.isClosed ? AppColors.muted : (waiting ? AppColors.goldDeep : AppColors.emerald700);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(waiting ? 'Waiting' : g.stateLabel,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.isDark});
  final bool isDark;

  static const _steps = [
    'You submit a concern privately.',
    'You choose a written answer or a private discussion.',
    'It is assigned to a suitable scholar or trained adviser.',
    'The adviser responds using appropriate Islamic evidence.',
    'Where necessary, you are referred to a qualified professional.',
    'You can always ask further questions in the same conversation.',
  ];

  @override
  Widget build(BuildContext context) {
    return _Panel(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How it works', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink(isDark))),
          const SizedBox(height: 10),
          for (var i = 0; i < _steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: AppColors.emerald50,
                    child: Text('${i + 1}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.emerald700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_steps[i], style: TextStyle(height: 1.4, color: _muted(isDark)))),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            "Funded by Ehsan's voluntary donations and supported by volunteers. Advisers give guidance, not binding fatwa.",
            style: TextStyle(fontSize: 12, color: _muted(isDark)),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// The private form
// ===========================================================================

class GuidanceFormScreen extends ConsumerStatefulWidget {
  const GuidanceFormScreen({super.key, this.initialTopic});
  final String? initialTopic;

  @override
  ConsumerState<GuidanceFormScreen> createState() => _GuidanceFormScreenState();
}

class _GuidanceFormScreenState extends ConsumerState<GuidanceFormScreen> {
  final _form = GlobalKey<FormState>();
  final _concern = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? _topic;
  String _mode = 'written';
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final t = widget.initialTopic;
    if (t != null && guidanceTopics.any((x) => x.key == t)) _topic = t;
  }

  @override
  void dispose() {
    _concern.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final g = await ref.read(guidanceRepositoryProvider).submit(
            topic: _topic!,
            responseMode: _mode,
            concern: _concern.text.trim(),
            name: _name.text.trim(),
            phone: _phone.text.trim(),
          );
      ref.invalidate(myGuidanceProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JazakAllahu khayran. Your reference is ${g.reference}.')),
      );
      context.pushReplacement('/guidance/r/${g.uuid}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(guidanceError(e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  InputDecoration _deco(bool d, String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: _card(d),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authProvider);

    if (auth.status != AuthStatus.authenticated) {
      return Scaffold(
        backgroundColor: _ground(d),
        appBar: _bar(context, 'Seek Guidance', d),
        body: const LoginPrompt(feature: 'guidance requests'),
      );
    }

    return Scaffold(
      backgroundColor: _ground(d),
      appBar: _bar(context, 'Private request', d),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _topic,
              decoration: _deco(d, 'Topic'),
              items: [
                for (final t in guidanceTopics) DropdownMenuItem(value: t.key, child: Text(t.label)),
              ],
              onChanged: (v) => setState(() => _topic = v),
              validator: (v) => v == null ? 'Choose a topic' : null,
            ),
            if (_topic == 'struggles') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: d ? AppColors.dangerDeep : AppColors.dangerTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "If you are thinking of harming yourself, or someone is hurting you, please don't wait for a reply. "
                  'Call emergency services (999 or 112 in Uganda) or someone you trust now.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: d ? AppColors.dangerOnDark : AppColors.danger),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text('How would you like to be helped?',
                style: TextStyle(fontWeight: FontWeight.w600, color: _ink(d))),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'written', label: Text('Written answer'), icon: Icon(Icons.edit_note_rounded)),
                ButtonSegment(value: 'discussion', label: Text('Private talk'), icon: Icon(Icons.forum_outlined)),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _concern,
              minLines: 6,
              maxLines: 12,
              maxLength: 5000,
              decoration: _deco(d, 'Your concern',
                  hint: 'Share as much as you are comfortable with. Only the advisers handling it will read it.'),
              validator: (v) => (v == null || v.trim().length < 20) ? 'Please write at least 20 characters' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _name,
              maxLength: 100,
              decoration: _deco(d, 'Name (optional)', hint: 'First name is fine'),
            ),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              maxLength: 32,
              decoration: _deco(d, _mode == 'discussion' ? 'Phone / WhatsApp (to arrange the talk)' : 'Phone / WhatsApp (optional)'),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return null;
                return RegExp(r'^[0-9+()\s-]{7,32}$').hasMatch(s) ? null : 'Enter a valid phone number';
              },
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _sending ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald700,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: _sending
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit privately'),
            ),
            const SizedBox(height: 10),
            Text('Free and private. Replies appear in this app under Seek Guidance.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: _muted(d))),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// The conversation
// ===========================================================================

class GuidanceThreadScreen extends ConsumerStatefulWidget {
  const GuidanceThreadScreen({super.key, required this.uuid});
  final String uuid;

  @override
  ConsumerState<GuidanceThreadScreen> createState() => _GuidanceThreadScreenState();
}

class _GuidanceThreadScreenState extends ConsumerState<GuidanceThreadScreen> {
  final _reply = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _reply.text.trim();
    if (body.length < 2) return;
    setState(() => _sending = true);
    try {
      await ref.read(guidanceRepositoryProvider).reply(widget.uuid, body);
      _reply.clear();
      ref.invalidate(guidanceThreadProvider(widget.uuid));
      ref.invalidate(myGuidanceProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(guidanceError(e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final async = ref.watch(guidanceThreadProvider(widget.uuid));

    return Scaffold(
      backgroundColor: _ground(d),
      appBar: _bar(context, 'Your request', d),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(guidanceError(e), textAlign: TextAlign.center, style: TextStyle(color: _muted(d))),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(guidanceThreadProvider(widget.uuid)),
                child: const Text('Try again'),
              ),
            ]),
          ),
        ),
        data: (g) => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(guidanceThreadProvider(widget.uuid)),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [
                    _Panel(
                      isDark: d,
                      child: Row(children: [
                        Icon(topicFor(g.topic).icon, color: _accent(d)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(g.topicLabel, style: TextStyle(fontWeight: FontWeight.w700, color: _ink(d))),
                            Text(
                              '${g.reference} · ${g.responseMode == 'discussion' ? 'Private discussion' : 'Written answer'} · ${DateFormat('d MMM y').format(g.createdAt)}',
                              style: TextStyle(fontSize: 12, color: _muted(d)),
                            ),
                          ]),
                        ),
                        _StateChip(g),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    _Bubble(mine: true, author: 'You', body: g.concern, at: g.createdAt, isDark: d),
                    for (final m in g.messages)
                      _Bubble(
                        mine: !m.fromAdviser,
                        author: m.fromAdviser ? '${m.author} (adviser)' : 'You',
                        body: m.body,
                        at: m.createdAt,
                        isDark: d,
                      ),
                    if (g.messages.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text('An adviser will reply here, in sha Allah. Pull down to refresh.',
                            textAlign: TextAlign.center, style: TextStyle(color: _muted(d))),
                      ),
                    if (g.status == 'referred' && (g.referralNote ?? '').isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.sapphireTint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('You have been referred:\n${g.referralNote}',
                            style: const TextStyle(color: AppColors.sapphire, height: 1.4)),
                      ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(color: _card(d), border: Border(top: BorderSide(color: _line(d)))),
                child: g.isClosed
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text('This conversation is closed. Start a new request if you need more help.',
                            style: TextStyle(color: _muted(d))),
                      )
                    : Row(children: [
                        Expanded(
                          child: TextField(
                            controller: _reply,
                            minLines: 1,
                            maxLines: 5,
                            maxLength: 5000,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Ask a follow-up question…',
                              counterText: '',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Call 0727 184 694',
                          onPressed: _call,
                          icon: Icon(Icons.call_outlined, color: _muted(d)),
                        ),
                        IconButton.filled(
                          onPressed: _sending ? null : _send,
                          style: IconButton.styleFrom(backgroundColor: AppColors.emerald700),
                          icon: _sending
                              ? const SizedBox(
                                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_rounded, color: Colors.white),
                        ),
                      ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.mine, required this.author, required this.body, required this.at, required this.isDark});
  final bool mine;
  final String author;
  final String body;
  final DateTime at;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = mine ? AppColors.emerald700 : (isDark ? AppColors.slateRaised : AppColors.creamDeep);
    final fg = mine ? Colors.white : _ink(isDark);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            SelectableText(body, style: TextStyle(color: fg, height: 1.45, fontSize: 14.5)),
            const SizedBox(height: 4),
            Text('$author · ${DateFormat('d MMM, HH:mm').format(at)}',
                style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}
