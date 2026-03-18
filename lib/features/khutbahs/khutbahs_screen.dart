import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/core/services/content_service.dart';
import 'package:ehsan_pathways/shared/widgets/badge_chip.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';

// ---------------------------------------------------------------------------
// State & Providers
// ---------------------------------------------------------------------------

final _contentServiceProvider =
    Provider<ContentService>((ref) => ContentService());

class _KhutbahListState {
  final List<Map<String, dynamic>> items;
  final bool isLoading;
  final bool isLoadingMore;
  final int currentPage;
  final int lastPage;
  final String? error;

  const _KhutbahListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.currentPage = 1,
    this.lastPage = 1,
    this.error,
  });

  bool get hasMore => currentPage < lastPage;

  _KhutbahListState copyWith({
    List<Map<String, dynamic>>? items,
    bool? isLoading,
    bool? isLoadingMore,
    int? currentPage,
    int? lastPage,
    String? error,
  }) =>
      _KhutbahListState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        currentPage: currentPage ?? this.currentPage,
        lastPage: lastPage ?? this.lastPage,
        error: error,
      );
}

class _KhutbahListNotifier extends StateNotifier<_KhutbahListState> {
  _KhutbahListNotifier(this._service)
      : super(const _KhutbahListState());

  final ContentService _service;

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _service.fetchKhutbahs(page: 1);
      final items = (data['data'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final meta = data['meta'] as Map<String, dynamic>? ?? {};
      state = state.copyWith(
        items: items,
        isLoading: false,
        currentPage: (meta['current_page'] as int?) ?? 1,
        lastPage: (meta['last_page'] as int?) ?? 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final data = await _service.fetchKhutbahs(page: nextPage);
      final newItems = (data['data'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final meta = data['meta'] as Map<String, dynamic>? ?? {};
      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoadingMore: false,
        currentPage: (meta['current_page'] as int?) ?? nextPage,
        lastPage: (meta['last_page'] as int?) ?? state.lastPage,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final khutbahListProvider =
    StateNotifierProvider<_KhutbahListNotifier, _KhutbahListState>((ref) {
  return _KhutbahListNotifier(ref.watch(_contentServiceProvider));
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class KhutbahsScreen extends ConsumerStatefulWidget {
  const KhutbahsScreen({super.key});

  @override
  ConsumerState<KhutbahsScreen> createState() => _KhutbahsScreenState();
}

class _KhutbahsScreenState extends ConsumerState<KhutbahsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(khutbahListProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(khutbahListProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(khutbahListProvider.notifier).loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(khutbahListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── Gradient header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppTheme.primaryGreenDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF14532D),
                      Color(0xFF15803D),
                      Color(0xFF16A34A),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.mic_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Khutbahs',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Friday sermons and Islamic lectures',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          if (state.isLoading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, __) => const _KhutbahShimmer(),
                childCount: 6,
              ),
            )
          else if (state.error != null && state.items.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.mic_off_rounded,
                title: 'Could not load khutbahs',
                subtitle: 'Please check your connection and try again.',
                actionLabel: 'Retry',
                onAction: _onRefresh,
              ),
            )
          else if (state.items.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.mic_rounded,
                title: 'No khutbahs yet',
                subtitle: 'Khutbahs are being added. Check back soon!',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= state.items.length) {
                    return state.isLoadingMore
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          )
                        : null;
                  }
                  final khutbah = state.items[index];
                  return _KhutbahCard(
                    khutbah: khutbah,
                    isDark: isDark,
                    onTap: () => context.push('/khutbahs/${khutbah['slug']}'),
                  );
                },
                childCount:
                    state.items.length + (state.isLoadingMore ? 1 : 0),
              ),
            ),

          if (!state.isLoading)
            SliverToBoxAdapter(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppTheme.primaryGreen,
                child: const SizedBox.shrink(),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Khutbah card
// ---------------------------------------------------------------------------

class _KhutbahCard extends StatelessWidget {
  const _KhutbahCard({
    required this.khutbah,
    required this.isDark,
    required this.onTap,
  });

  final Map<String, dynamic> khutbah;
  final bool isDark;
  final VoidCallback onTap;

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = khutbah['title'] as String? ?? '';
    final description = khutbah['description'] as String? ?? '';
    final deliveredAt = khutbah['delivered_at'] as String?;
    final mosqueName = khutbah['mosque_name'] as String? ?? '';
    final isJumuah = khutbah['is_jumuah'] as bool? ?? false;
    final scholar = khutbah['scholar'] as Map<String, dynamic>?;
    final scholarName = scholar?['name'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Mic icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.mic_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                            height: 1.35,
                          ),
                        ),
                        if (scholarName.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            scholarName,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFF9CA3AF),
                  ),
                ],
              ),

              if (description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
              ],

              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (isJumuah)
                    const BadgeChip(
                      label: "Jumu'ah",
                      variant: BadgeVariant.green,
                      size: BadgeSize.small,
                      icon: Icons.star_rounded,
                    ),
                  if (mosqueName.isNotEmpty)
                    BadgeChip(
                      label: mosqueName,
                      variant: BadgeVariant.gray,
                      size: BadgeSize.small,
                      icon: Icons.location_on_outlined,
                    ),
                  if (deliveredAt != null)
                    BadgeChip(
                      label: _formatDate(deliveredAt),
                      variant: BadgeVariant.blue,
                      size: BadgeSize.small,
                      icon: Icons.calendar_today_rounded,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer
// ---------------------------------------------------------------------------

class _KhutbahShimmer extends StatelessWidget {
  const _KhutbahShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ShimmerWrap(
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ShimmerBox(width: 42, height: 42, borderRadius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerBox(width: double.infinity, height: 13),
                        SizedBox(height: 6),
                        ShimmerBox(width: 100, height: 11),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const ShimmerBox(width: double.infinity, height: 11),
              const SizedBox(height: 5),
              const ShimmerBox(width: 200, height: 11),
              const SizedBox(height: 10),
              Row(
                children: const [
                  ShimmerBox(width: 70, height: 22, borderRadius: 20),
                  SizedBox(width: 6),
                  ShimmerBox(width: 90, height: 22, borderRadius: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
