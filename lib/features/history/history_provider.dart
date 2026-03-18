import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ehsan_pathways/core/services/api_service.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class WatchHistoryItem {
  final int id;
  final String videoUuid;
  final String title;
  final String? thumbnailUrl;
  final String? scholarName;
  final String? scholarAvatarUrl;
  final String? durationFormatted;
  final int watchedSeconds;
  final int totalSeconds;
  final DateTime watchedAt;

  const WatchHistoryItem({
    required this.id,
    required this.videoUuid,
    required this.title,
    this.thumbnailUrl,
    this.scholarName,
    this.scholarAvatarUrl,
    this.durationFormatted,
    required this.watchedSeconds,
    required this.totalSeconds,
    required this.watchedAt,
  });

  /// 0.0 – 1.0 watch progress.
  double get progressPercent =>
      totalSeconds > 0 ? (watchedSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;

  /// True when ≥ 90% watched.
  bool get isCompleted => progressPercent >= 0.9;

  /// Human-friendly resume label.
  String get resumeLabel {
    if (watchedSeconds <= 5) return 'Watch';
    final m = watchedSeconds ~/ 60;
    final s = watchedSeconds % 60;
    return 'Resume ${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get timeAgoLabel {
    final diff = DateTime.now().difference(watchedAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
    return '${diff.inDays ~/ 30}mo ago';
  }

  factory WatchHistoryItem.fromJson(Map<String, dynamic> json) {
    final video = json['video'] as Map<String, dynamic>? ?? {};
    final scholar = video['scholar'] as Map<String, dynamic>?;
    return WatchHistoryItem(
      id: (json['id'] as num? ?? 0).toInt(),
      videoUuid: (json['video_uuid'] as String?) ??
          (video['uuid'] as String?) ??
          '',
      title: (video['title'] as String?) ??
          (json['title'] as String?) ??
          'Unknown Video',
      thumbnailUrl: video['thumbnail_url'] as String?,
      scholarName: scholar?['name'] as String?,
      scholarAvatarUrl: scholar?['avatar_url'] as String?,
      durationFormatted: video['duration_formatted'] as String?,
      watchedSeconds: (json['watched_seconds'] as num? ?? 0).toInt(),
      totalSeconds: (json['total_seconds'] as num? ?? 0).toInt(),
      watchedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

// ─── State ────────────────────────────────────────────────────────────────────

class HistoryState {
  final List<WatchHistoryItem> items;
  final bool isLoading;
  final bool isClearing;
  final String? error;

  const HistoryState({
    this.items = const [],
    this.isLoading = false,
    this.isClearing = false,
    this.error,
  });

  /// Items started but not finished — shown in "Continue Watching".
  List<WatchHistoryItem> get continueWatching =>
      items.where((i) => !i.isCompleted && i.watchedSeconds > 5).toList();

  HistoryState copyWith({
    List<WatchHistoryItem>? items,
    bool? isLoading,
    bool? isClearing,
    String? error,
    bool clearError = false,
  }) {
    return HistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isClearing: isClearing ?? this.isClearing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class HistoryNotifier extends Notifier<HistoryState> {
  @override
  HistoryState build() => const HistoryState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = ref.read(apiProvider);
      final response = await dio.get('/history');
      final body = response.data as Map<String, dynamic>;
      final rawList = (body['data'] ?? body) as List<dynamic>;
      final items = rawList
          .map((e) => WatchHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> clearAll() async {
    state = state.copyWith(isClearing: true);
    try {
      final dio = ref.read(apiProvider);
      await dio.delete('/history/clear');
      state = state.copyWith(items: [], isClearing: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isClearing: false, error: e.toString());
    }
  }

  /// Optimistic remove — reverts on API failure.
  Future<void> remove(int id) async {
    final saved = List<WatchHistoryItem>.from(state.items);
    state = state.copyWith(
      items: saved.where((i) => i.id != id).toList(),
    );
    try {
      final dio = ref.read(apiProvider);
      await dio.delete('/history/$id');
    } catch (_) {
      state = state.copyWith(items: saved);
    }
  }

  /// Called from the video player to persist watch position.
  Future<void> updateProgress({
    required String uuid,
    required int watchedSeconds,
    required int totalSeconds,
  }) async {
    try {
      final dio = ref.read(apiProvider);
      await dio.post('/history/progress/$uuid', data: {
        'watched_seconds': watchedSeconds,
        'total_seconds': totalSeconds,
      });
    } catch (_) {
      // Silent — progress is best-effort
    }
  }
}

final historyProvider =
    NotifierProvider<HistoryNotifier, HistoryState>(HistoryNotifier.new);

/// Fetches the resume point for a specific video (seconds watched).
/// Returns 0 if no history exists.
final resumePointProvider =
    FutureProvider.family<int, String>((ref, uuid) async {
  try {
    final dio = ref.read(apiProvider);
    final response = await dio.get('/history/resume/$uuid');
    final data = response.data as Map<String, dynamic>?;
    return (data?['data']?['watched_seconds'] as num? ?? 0).toInt();
  } catch (_) {
    return 0;
  }
});
