import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/features/islamic_tools/islamic_tools_provider.dart';

class HadithCollectionScreen extends ConsumerWidget {
  final String collectionId;
  const HadithCollectionScreen({super.key, required this.collectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hadithsAsync = ref.watch(hadithCollectionProvider(collectionId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        title: Text(
          _titleFor(collectionId),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.invalidate(hadithCollectionProvider(collectionId)),
          ),
        ],
      ),
      body: hadithsAsync.when(
        loading: () => _buildShimmer(),
        error: (e, _) => _buildError(
            () => ref.invalidate(hadithCollectionProvider(collectionId))),
        data: (hadiths) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: hadiths.length,
          itemBuilder: (context, index) =>
              _HadithCard(hadith: hadiths[index]),
        ),
      ),
    );
  }

  String _titleFor(String id) {
    switch (id) {
      case 'nawawi40':
        return "Imam Nawawi's 40 Hadith";
      case 'bukhari':
        return 'Sahih al-Bukhari (Selected)';
      case 'qudsi':
        return 'Hadith Qudsi';
      case 'virtues':
        return 'Virtues & Character';
      default:
        return 'Hadith Collection';
    }
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E7EB),
      highlightColor: const Color(0xFFF9FAFB),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          height: 180,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildError(VoidCallback retry) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFD1D5DB)),
        const SizedBox(height: 12),
        const Text('Failed to load hadiths',
            style: TextStyle(color: Color(0xFF6B7280))),
        const SizedBox(height: 12),
        TextButton(onPressed: retry, child: const Text('Retry')),
      ]),
    );
  }
}

class _HadithCard extends StatefulWidget {
  final HadithItem hadith;
  const _HadithCard({required this.hadith});

  @override
  State<_HadithCard> createState() => _HadithCardState();
}

class _HadithCardState extends State<_HadithCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.hadith;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D4ED8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Hadith ${h.no}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
                if (h.topic.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      h.topic,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: h.english));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Hadith copied'),
                          duration: Duration(seconds: 1)),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
          // Arabic
          if (h.arabic.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                h.arabic,
                style: const TextStyle(
                  fontSize: 19,
                  height: 1.9,
                  fontFamily: 'Amiri',
                  color: Color(0xFF111827),
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ),
          const SizedBox(height: 10),
          const Divider(height: 1, indent: 14, endIndent: 14),
          const SizedBox(height: 10),
          // English — collapsible for long text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              firstChild: Text(
                h.english,
                style: const TextStyle(
                    fontSize: 14, height: 1.7, color: Color(0xFF374151)),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: Text(
                h.english,
                style: const TextStyle(
                    fontSize: 14, height: 1.7, color: Color(0xFF374151)),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
            ),
          ),
          // Toggle expand
          if (h.english.length > 200)
            Padding(
              padding: const EdgeInsets.only(left: 14, top: 4),
              child: GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Show less' : 'Read more',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          // Narrator + ref footer
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                if (h.narrator.isNotEmpty)
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 12, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            h.narrator,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF9CA3AF)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (h.ref.isNotEmpty)
                  Text(
                    h.ref,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
