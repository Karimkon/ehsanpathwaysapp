import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/features/islamic_tools/islamic_tools_provider.dart';

class DuaCategoryScreen extends ConsumerWidget {
  final String categoryId;
  const DuaCategoryScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duaAsync = ref.watch(duaCategoryProvider(categoryId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: AppTheme.accentGold,
        foregroundColor: Colors.white,
        title: duaAsync.when(
          loading: () => const Text('Duas'),
          error: (_, __) => const Text('Duas'),
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.category.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text(data.category.arabic,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontFamily: 'Amiri')),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.invalidate(duaCategoryProvider(categoryId)),
          ),
        ],
      ),
      body: duaAsync.when(
        loading: () => _buildShimmer(),
        error: (e, _) =>
            _buildError(() => ref.invalidate(duaCategoryProvider(categoryId))),
        data: (data) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.duas.length,
          itemBuilder: (context, index) => _DuaCard(dua: data.duas[index]),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E7EB),
      highlightColor: const Color(0xFFF9FAFB),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          height: 200,
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
        const Text('Failed to load duas',
            style: TextStyle(color: Color(0xFF6B7280))),
        const SizedBox(height: 12),
        TextButton(onPressed: retry, child: const Text('Retry')),
      ]),
    );
  }
}

class _DuaCard extends StatelessWidget {
  final DuaItem dua;
  const _DuaCard({required this.dua});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    dua.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  onPressed: () {
                    final text = '${dua.arabic}\n\n${dua.english}';
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Dua copied'),
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
          // Arabic text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: AppTheme.accentGold.withOpacity(0.05),
            child: Text(
              dua.arabic,
              style: const TextStyle(
                fontSize: 20,
                height: 1.9,
                fontFamily: 'Amiri',
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
          // Latin transliteration
          if (dua.latin.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Text(
                dua.latin,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.accentGold,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ),
            ),
          // English translation
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Text(
              dua.english,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Color(0xFF374151),
              ),
            ),
          ),
          // Footer: ref + count
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (dua.ref.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.menu_book_rounded,
                          size: 12, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Text(
                        dua.ref,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                if (dua.count.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      dua.count,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
