import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/shared/widgets/reading_width.dart';
import 'package:ehsan_pathways/features/islamic_tools/hadith/hadith_library_provider.dart';
import 'package:ehsan_pathways/features/islamic_tools/hadith/widgets/hadith_card.dart';

/// Searches the hadith text — English through the full-text index, Arabic by
/// matching the script directly.
class HadithSearchScreen extends ConsumerStatefulWidget {
  const HadithSearchScreen({super.key, this.bookSlug});

  /// When set, the search is confined to one collection.
  final String? bookSlug;

  @override
  ConsumerState<HadithSearchScreen> createState() => _HadithSearchScreenState();
}

class _HadithSearchScreenState extends ConsumerState<HadithSearchScreen> {
  final _field = TextEditingController();
  final _focus = FocusNode();

  static const _suggestions = [
    'intention',
    'kindness to parents',
    'seeking knowledge',
    'charity',
    'patience',
    'prayer',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _run(String term) {
    _field.text = term;
    _focus.unfocus();
    ref
        .read(hadithSearchProvider.notifier)
        .search(term, bookSlug: widget.bookSlug);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hadithSearchProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight;

    return Scaffold(
      appBar: AppBar(title: const Text('Search Hadith')),
      body: Column(
        children: [
          Padding(
            padding: readingInsets(context, horizontal: 18, top: 4, bottom: 12),
            child: TextField(
              controller: _field,
              focusNode: _focus,
              textInputAction: TextInputAction.search,
              onSubmitted: _run,
              decoration: InputDecoration(
                hintText: widget.bookSlug == null
                    ? 'Search all collections…'
                    : 'Search this collection…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: state.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _field.clear();
                          ref.read(hadithSearchProvider.notifier).clear();
                          _focus.requestFocus();
                        },
                      ),
              ),
            ),
          ),

          if (state.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  state.error!,
                  style: AppTheme.ui(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
            ),

          Expanded(
            child: Builder(
              builder: (context) {
                if (state.loading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                  );
                }

                if (!state.searched) {
                  return _Suggestions(onPick: _run, muted: muted);
                }

                if (state.results.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(34),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 40,
                            color: muted,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Nothing found for “${state.query}”',
                            textAlign: TextAlign.center,
                            style: AppTheme.ui(
                              size: 15,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Try a different word. English searches match the '
                            'translation; Arabic searches match the original text.',
                            textAlign: TextAlign.center,
                            style: AppTheme.ui(
                              size: 13,
                              weight: FontWeight.w500,
                              color: muted,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: readingInsets(
                    context,
                    horizontal: 18,
                    top: 4,
                    bottom: 28,
                  ),
                  itemCount: state.results.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          '${state.total} result${state.total == 1 ? '' : 's'} '
                          'for “${state.query}”'
                          '${state.total > state.results.length ? ' · showing the first ${state.results.length}' : ''}',
                          style: AppTheme.ui(
                            size: 12.5,
                            weight: FontWeight.w600,
                            color: muted,
                          ),
                        ),
                      );
                    }

                    return HadithCard(
                      hadith: state.results[i - 1],
                      showSource: true,
                      highlight: state.query,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.onPick, required this.muted});

  final ValueChanged<String> onPick;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: readingInsets(context, horizontal: 18, top: 10, bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TRY SEARCHING FOR', style: AppTheme.eyebrow(muted)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: _HadithSearchScreenState._suggestions
                .map(
                  (s) => ActionChip(
                    label: Text(s),
                    onPressed: () => onPick(s),
                    backgroundColor: AppTheme.primaryGreen.withValues(
                      alpha: 0.10,
                    ),
                    side: BorderSide.none,
                    labelStyle: AppTheme.ui(
                      size: 13,
                      weight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
