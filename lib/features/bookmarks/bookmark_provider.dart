import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ehsan_pathways/core/services/api_service.dart';
import 'package:ehsan_pathways/core/json_read.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class BookmarkItem {
  final String? uuid;
  final String? slug;
  final String title;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final String? difficultyLevel;

  const BookmarkItem({
    this.uuid,
    this.slug,
    required this.title,
    this.thumbnailUrl,
    this.durationSeconds,
    this.difficultyLevel,
  });

  /// The best identifier to use for navigation.
  String get identifier => uuid ?? slug ?? '';

  factory BookmarkItem.fromJson(Map<String, dynamic> json) {
    return BookmarkItem(
      uuid: jStr(json['uuid']),
      slug: jStr(json['slug']),
      title: jStr(json['title']) ?? jStr(json['name']) ?? 'Untitled',
      thumbnailUrl: (json['thumbnail_url'] ?? json['photo_url']) as String?,
      durationSeconds: jInt(json['duration_seconds']),
      difficultyLevel: jStr(json['difficulty_level']),
    );
  }
}

class Bookmark {
  final int id;
  final String type;
  final String? folder;
  final String? notes;
  final DateTime createdAt;
  final BookmarkItem item;

  const Bookmark({
    required this.id,
    required this.type,
    this.folder,
    this.notes,
    required this.createdAt,
    required this.item,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: (jInt(json['id']) ?? 0),
      type: jStr(json['type']) ?? 'video',
      folder: jStr(json['folder']),
      notes: jStr(json['notes']),
      createdAt: DateTime.tryParse(jStr(json['created_at']) ?? '') ??
          DateTime.now(),
      item: BookmarkItem.fromJson(json['item'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// Friendly label for the content type.
  String get typeLabel {
    switch (type) {
      case 'video':
        return 'Video';
      case 'pathway':
        return 'Pathway';
      case 'scholar':
        return 'Scholar';
      case 'khutbah':
        return 'Khutbah';
      case 'arabic_course':
        return 'Arabic';
      default:
        return type;
    }
  }
}

class BookmarkListState {
  final List<Bookmark> bookmarks;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int lastPage;
  final String? filterType;

  const BookmarkListState({
    this.bookmarks = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
    this.filterType,
  });

  BookmarkListState copyWith({
    List<Bookmark>? bookmarks,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? lastPage,
    String? filterType,
  }) {
    return BookmarkListState(
      bookmarks: bookmarks ?? this.bookmarks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      filterType: filterType ?? this.filterType,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class BookmarkListNotifier extends Notifier<BookmarkListState> {
  @override
  BookmarkListState build() {
    // Auto-fetch on creation
    Future.microtask(() => fetchBookmarks());
    return const BookmarkListState(isLoading: true);
  }

  Dio get _dio => ref.read(apiProvider);

  Future<void> fetchBookmarks({String? type, int page = 1}) async {
    state = state.copyWith(isLoading: true, error: null, filterType: type);

    try {
      final query = <String, dynamic>{'page': page};
      if (type != null) query['type'] = type;

      final response = await _dio.get('/bookmarks', queryParameters: query);
      final body = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      final items = (body['data'] as List<dynamic>? ?? [])
          .map((e) => Bookmark.fromJson(e as Map<String, dynamic>))
          .toList();

      final meta = body['meta'] as Map<String, dynamic>? ?? {};

      state = state.copyWith(
        bookmarks: page == 1 ? items : [...state.bookmarks, ...items],
        isLoading: false,
        currentPage: jInt(meta['current_page']) ?? page,
        lastPage: jInt(meta['last_page']) ?? 1,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message']?.toString() ??
            'Failed to load bookmarks',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.currentPage >= state.lastPage) return;
    await fetchBookmarks(
        type: state.filterType, page: state.currentPage + 1);
  }

  Future<bool> toggleBookmark(String type, String id) async {
    try {
      final response = await _dio.post('/bookmarks/toggle', data: {
        'type': type,
        'id': id,
      });
      final body = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      final bookmarked = jBool(body['bookmarked']) ?? false;

      // Refresh list
      await fetchBookmarks(type: state.filterType);
      return bookmarked;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteBookmark(int id) async {
    try {
      await _dio.delete('/bookmarks/$id');
      state = state.copyWith(
        bookmarks: state.bookmarks.where((b) => b.id != id).toList(),
      );
    } catch (_) {
      // silently fail
    }
  }
}

final bookmarkListProvider =
    NotifierProvider<BookmarkListNotifier, BookmarkListState>(
        BookmarkListNotifier.new);

// ---------------------------------------------------------------------------
// Quick check provider (is this item bookmarked?)
// ---------------------------------------------------------------------------

final isBookmarkedProvider =
    FutureProvider.family<bool, ({String type, String id})>((ref, params) async {
  final dio = ref.read(apiProvider);
  try {
    final response = await dio.get('/bookmarks/check', queryParameters: {
      'type': params.type,
      'id': params.id,
    });
    final body = response.data is String
        ? jsonDecode(response.data as String) as Map<String, dynamic>
        : response.data as Map<String, dynamic>;
    return jBool(body['bookmarked']) ?? false;
  } catch (_) {
    return false;
  }
});
