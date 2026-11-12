import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/core/services/api_service.dart';
import 'package:ehsan_pathways/core/json_read.dart';

/// Ask Ehsan: free answers grounded in the Qur'an and authentic hadith.
///
/// The server (POST /ask) searches our own library first and, when a free
/// model is configured, writes the answer from those sources. Someone in
/// distress is answered with people and phone numbers, never a model.

class AskSource {
  final String type;
  final String title;
  final String arabic;
  final String english;
  final String? grade;
  final String? url;

  const AskSource({
    required this.type,
    required this.title,
    required this.arabic,
    required this.english,
    this.grade,
    this.url,
  });

  factory AskSource.fromJson(Map<String, dynamic> j) => AskSource(
        type: jStr(j['type']) ?? 'quran',
        title: jStr(j['title']) ?? '',
        arabic: jStr(j['arabic']) ?? '',
        english: jStr(j['english']) ?? '',
        grade: jStr(j['grade']),
        url: jStr(j['url']),
      );
}

class AskMessage {
  final bool fromUser;
  final String text;
  final List<AskSource> sources;
  final bool crisis;

  const AskMessage({required this.fromUser, required this.text, this.sources = const [], this.crisis = false});

  factory AskMessage.fromAnswer(Map<String, dynamic> d) => AskMessage(
        fromUser: false,
        text: jStr(d['answer']) ?? '',
        crisis: d['crisis'] == true,
        sources: ((d['sources'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AskSource.fromJson)
            .toList(),
      );
}

const _phone = '0727184694';

class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key, this.initialQuestion});
  final String? initialQuestion;

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<AskMessage> _messages = [];
  bool _loading = false;

  static const _suggestions = [
    'How do I pray Salat al-Istikhara?',
    "What does the Qur'an say about patience?",
    'Is it permissible to take a loan with interest?',
    'ما فضل الصدقة؟',
    'How can I stop feeling anxious?',
  ];

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuestion?.trim();
    if (q != null && q.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _send(q));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? text]) async {
    final q = (text ?? _input.text).trim();
    if (q.isEmpty || _loading) return;

    final history = _messages
        .skip(_messages.length > 6 ? _messages.length - 6 : 0)
        .map((m) => {'role': m.fromUser ? 'user' : 'assistant', 'content': m.text.length > 3000 ? m.text.substring(0, 3000) : m.text})
        .toList();

    setState(() {
      _messages.add(AskMessage(fromUser: true, text: q));
      _input.clear();
      _loading = true;
    });
    _toBottom();

    try {
      final Dio dio = ref.read(apiProvider);
      final r = await dio.post('/ask', data: {'question': q, 'history': history});
      final d = (r.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _messages.add(AskMessage.fromAnswer(d)));
    } catch (e) {
      if (!mounted) return;
      var msg = 'Something went wrong. Please try again.';
      if (e is DioException) {
        if (e.response == null) msg = 'No connection. Check your internet and try again.';
        final data = e.response?.data;
        if (data is Map && data['message'] is String) msg = (jStr(data['message']) ?? '');
      }
      setState(() {
        _messages.removeLast();
        _input.text = q;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
      _toBottom();
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 200,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: _phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final muted = d ? AppColors.onDarkMuted : AppColors.muted;

    return Scaffold(
      backgroundColor: d ? AppColors.slate : AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.emerald900,
        foregroundColor: Colors.white,
        title: Text('Ask Ehsan', style: GoogleFonts.lora(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(tooltip: 'Call 0727 184 694', icon: const Icon(Icons.call_outlined), onPressed: _call),
          if (_messages.isNotEmpty)
            IconButton(
              tooltip: 'New chat',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loading ? null : () => setState(_messages.clear),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text('Ask anything about Islam',
                          style: GoogleFonts.lora(
                              fontSize: 20, fontWeight: FontWeight.w700, color: d ? AppColors.onDark : AppColors.ink)),
                      const SizedBox(height: 6),
                      Text(
                        "Salah, fasting, marriage, a verse, a hadith, a hard moment. Answers come from the Qur'an and authentic Sunnah. "
                        'Prefer a person? Call 0727 184 694.',
                        style: TextStyle(color: muted, height: 1.45),
                      ),
                      const SizedBox(height: 16),
                      for (final s in _suggestions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OutlinedButton(
                            onPressed: () => _send(s),
                            style: OutlinedButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              foregroundColor: d ? AppColors.onDark : AppColors.ink,
                            ),
                            child: Text(s),
                          ),
                        ),
                    ],
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _messages.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                                width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: muted)),
                          ),
                        );
                      }
                      return _Bubble(message: _messages[i], isDark: d);
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: BoxDecoration(
                color: d ? AppColors.slateCard : AppColors.card,
                border: Border(top: BorderSide(color: d ? AppColors.slateLine : AppColors.sand)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 5,
                        maxLength: 1000,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Ask a question… / اسأل سؤالك',
                          counterText: '',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: _loading ? null : _send,
                      style: IconButton.styleFrom(backgroundColor: AppColors.emerald700),
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ]),
                  Text('An AI assistant, not a mufti. Check important rulings with a scholar.',
                      style: TextStyle(fontSize: 11, color: muted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isDark});
  final AskMessage message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final ink = isDark ? AppColors.onDark : AppColors.ink;
    final muted = isDark ? AppColors.onDarkMuted : AppColors.muted;
    final maxW = MediaQuery.of(context).size.width * (m.fromUser ? 0.8 : 0.92);

    if (m.fromUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          constraints: BoxConstraints(maxWidth: maxW),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.emerald700,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16), topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16), bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(m.text, style: const TextStyle(color: Colors.white, height: 1.4)),
        ),
      );
    }

    final bg = m.crisis
        ? (isDark ? AppColors.dangerDeep : AppColors.dangerTint)
        : (isDark ? AppColors.slateCard : AppColors.card);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: maxW),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: isDark ? AppColors.slateLine : AppColors.sand),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4), topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16),
                ),
              ),
              // The model writes light markdown; show it as plain text with
              // the emphasis markers removed rather than raw asterisks.
              child: SelectableText(
                m.text.replaceAll('**', '').replaceAll(RegExp(r'^#+\s*', multiLine: true), ''),
                style: TextStyle(color: ink, height: 1.5, fontSize: 14.5),
              ),
            ),
            for (final s in m.sources)
              Card(
                margin: const EdgeInsets.only(top: 6),
                elevation: 0,
                color: isDark ? AppColors.slateRaised : AppColors.creamDeep,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  dense: true,
                  leading: Icon(s.type == 'quran' ? Icons.menu_book_rounded : Icons.format_quote_rounded,
                      size: 18, color: isDark ? AppColors.emerald400 : AppColors.emerald700),
                  title: Text(
                    '${s.type == 'quran' ? "Qur'an" : 'Hadith'} · ${s.title}${s.grade != null && s.grade!.isNotEmpty ? ' (${s.grade})' : ''}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  children: [
                    if (s.arabic.isNotEmpty)
                      Text(s.arabic,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: AppTheme.quran(size: 20, color: ink, height: 1.9)),
                    if (s.english.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(s.english, style: TextStyle(color: muted, height: 1.45, fontSize: 13.5)),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: InkWell(
                onTap: () => context.push('/guidance'),
                child: Text('Talk to an adviser privately →',
                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.emerald400 : AppColors.emerald700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
