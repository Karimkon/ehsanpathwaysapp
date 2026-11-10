import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ehsan_pathways/config/app_config.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class VideoScholar {
  final String slug;
  final String name;
  final String? avatarUrl;

  const VideoScholar({
    required this.slug,
    required this.name,
    this.avatarUrl,
  });

  factory VideoScholar.fromJson(Map<String, dynamic> json) {
    return VideoScholar(
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class VideoCategory {
  final String? slug;
  final String name;

  const VideoCategory({this.slug, required this.name});

  factory VideoCategory.fromJson(Map<String, dynamic> json) {
    return VideoCategory(
      slug: json['slug'] as String?,
      name: json['name'] as String? ?? '',
    );
  }
}

class VideoTag {
  final String name;
  final String slug;

  const VideoTag({required this.name, required this.slug});

  factory VideoTag.fromJson(Map<String, dynamic> json) {
    return VideoTag(
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }
}

class Video {
  final int? id;
  final String uuid;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String? youtubeUrl;
  final String? durationFormatted;
  final int viewCount;
  final VideoScholar? scholar;
  final VideoCategory? category;
  final List<VideoTag> tags;
  final List<Video> relatedVideos;

  const Video({
    this.id,
    required this.uuid,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.youtubeUrl,
    this.durationFormatted,
    this.viewCount = 0,
    this.scholar,
    this.category,
    this.tags = const [],
    this.relatedVideos = const [],
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: (json['id'] as num?)?.toInt(),
      uuid: json['uuid'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      youtubeUrl: json['youtube_url'] as String? ?? json['video_url'] as String?,
      durationFormatted: json['duration_formatted'] as String?,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      scholar: json['scholar'] != null
          ? VideoScholar.fromJson(json['scholar'] as Map<String, dynamic>)
          : null,
      category: json['category'] != null
          ? VideoCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => VideoTag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      relatedVideos: (json['related_videos'] as List<dynamic>?)
              ?.map((e) => Video.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PaginatedVideos {
  final List<Video> data;
  final int currentPage;
  final int lastPage;
  final int total;

  const PaginatedVideos({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;

  factory PaginatedVideos.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? json;
    return PaginatedVideos(
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => Video.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One page of the cursor feed.
///
/// There is no page number and no total, on purpose. A cursor is "the last row
/// you saw", so a video published while somebody is scrolling does not shift
/// everything below it -- which is how page numbers repeat and skip rows. And
/// the total is the expensive part: counting the filtered set measured 50
/// seconds at a million rows on the server.
class VideoFeedPage {
  final List<Video> data;
  final String? nextCursor;
  final bool hasMore;

  const VideoFeedPage({
    required this.data,
    this.nextCursor,
    this.hasMore = false,
  });

  factory VideoFeedPage.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    final cursor = meta['next_cursor'] as String?;

    return VideoFeedPage(
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => Video.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      nextCursor: cursor,
      // Trust the cursor over the flag: no cursor means there is nowhere to go
      // even if the server said otherwise.
      hasMore: (meta['has_more'] as bool? ?? false) && cursor != null,
    );
  }
}

// ---------------------------------------------------------------------------
// Filter state
// ---------------------------------------------------------------------------

class VideoFilter {
  final int page;
  final String? categorySlug;
  final String? scholarSlug;
  final String? search;

  const VideoFilter({
    this.page = 1,
    this.categorySlug,
    this.scholarSlug,
    this.search,
  });

  VideoFilter copyWith({
    int? page,
    String? categorySlug,
    String? scholarSlug,
    String? search,
    bool clearCategory = false,
    bool clearScholar = false,
    bool clearSearch = false,
  }) {
    return VideoFilter(
      page: page ?? this.page,
      categorySlug: clearCategory ? null : (categorySlug ?? this.categorySlug),
      scholarSlug: clearScholar ? null : (scholarSlug ?? this.scholarSlug),
      search: clearSearch ? null : (search ?? this.search),
    );
  }
}

// ---------------------------------------------------------------------------
// Dio provider
// ---------------------------------------------------------------------------

final _dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: Duration(milliseconds: AppConfig.connectTimeout),
    receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));
});

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Holds the current filter state. UI updates this, and the videos list reacts.
class VideoFilterNotifier extends Notifier<VideoFilter> {
  @override
  VideoFilter build() {
    return const VideoFilter();
  }

  void update(VideoFilter filter) {
    state = filter;
  }
}

final videoFilterProvider =
    NotifierProvider<VideoFilterNotifier, VideoFilter>(VideoFilterNotifier.new);

/// Fetches a paginated list of videos based on the current filter.
final videosProvider = FutureProvider<PaginatedVideos>((ref) async {
  final dio = ref.read(_dioProvider);
  final filter = ref.watch(videoFilterProvider);

  final queryParams = <String, dynamic>{
    'page': filter.page,
  };
  if (filter.categorySlug != null) queryParams['category'] = filter.categorySlug;
  if (filter.scholarSlug != null) queryParams['scholar'] = filter.scholarSlug;
  if (filter.search != null && filter.search!.isNotEmpty) {
    queryParams['search'] = filter.search;
  }

  final response = await dio.get('/videos', queryParameters: queryParams);
  return PaginatedVideos.fromJson(response.data as Map<String, dynamic>);
});

/// Fetches a single video by UUID.
final videoDetailProvider =
    FutureProvider.family<Video, String>((ref, uuid) async {
  final dio = ref.read(_dioProvider);
  final response = await dio.get('/videos/$uuid');
  final data = response.data as Map<String, dynamic>;
  return Video.fromJson(data['data'] as Map<String, dynamic>);
});

/// Tracks accumulated video list across pages for infinite scroll.
class VideoListState {
  final List<Video> videos;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final String? categorySlug;
  final String? search;

  /// Where the next page starts. Null means the beginning, or the end -- which
  /// of the two is what [hasMore] is for.
  final String? cursor;

  /// The extra filters the cursor feed understands.
  final String? scholarSlug;
  final String? language;
  final List<int> durationBuckets;
  final List<String> types;
  final String sort;

  const VideoListState({
    this.videos = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
    this.categorySlug,
    this.search,
    this.cursor,
    this.scholarSlug,
    this.language,
    this.durationBuckets = const [],
    this.types = const [],
    this.sort = 'latest',
  });

  /// Is anything narrowing the feed?
  bool get isFiltered =>
      (search != null && search!.isNotEmpty) ||
      categorySlug != null ||
      scholarSlug != null ||
      language != null ||
      durationBuckets.isNotEmpty ||
      types.isNotEmpty;

  VideoListState copyWith({
    List<Video>? videos,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    String? categorySlug,
    String? search,
    String? cursor,
    String? scholarSlug,
    String? language,
    List<int>? durationBuckets,
    List<String>? types,
    String? sort,
    bool clearError = false,
    bool clearCategory = false,
    bool clearSearch = false,
    bool clearCursor = false,
  }) {
    return VideoListState(
      videos: videos ?? this.videos,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: clearError ? null : (error ?? this.error),
      categorySlug:
          clearCategory ? null : (categorySlug ?? this.categorySlug),
      search: clearSearch ? null : (search ?? this.search),
      // Explicit clearing, because `cursor ?? this.cursor` can never set it
      // back to null -- and reaching the end of the feed has to do exactly
      // that, or loadMore would keep refetching the last page.
      cursor: clearCursor ? null : (cursor ?? this.cursor),
      scholarSlug: scholarSlug ?? this.scholarSlug,
      language: language ?? this.language,
      durationBuckets: durationBuckets ?? this.durationBuckets,
      types: types ?? this.types,
      sort: sort ?? this.sort,
    );
  }
}

class VideoListNotifier extends Notifier<VideoListState> {
  @override
  VideoListState build() {
    return const VideoListState();
  }

  Future<void> loadInitial({
    String? categorySlug,
    String? search,
    String? scholarSlug,
    String? language,
    List<int> durationBuckets = const [],
    List<String> types = const [],
    String sort = 'latest',
  }) async {
    state = VideoListState(
      isLoading: true,
      categorySlug: categorySlug,
      search: search,
      scholarSlug: scholarSlug,
      language: language,
      durationBuckets: durationBuckets,
      types: types,
      sort: sort,
    );

    try {
      final result = await _fetch(null);
      state = state.copyWith(
        videos: result.data,
        isLoading: false,
        hasMore: result.hasMore,
        cursor: result.nextCursor,
        currentPage: 1,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    // No cursor means the end, whatever hasMore says.
    if (state.isLoadingMore || !state.hasMore || state.cursor == null) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await _fetch(state.cursor);

      // Guard against a repeat: if the server ever hands back a page we have
      // already shown, stop rather than append duplicates forever.
      final known = state.videos.map((v) => v.uuid).toSet();
      final fresh = result.data.where((v) => !known.contains(v.uuid)).toList();

      state = state.copyWith(
        videos: [...state.videos, ...fresh],
        isLoadingMore: false,
        hasMore: result.hasMore && fresh.isNotEmpty,
        cursor: result.nextCursor,
        clearCursor: result.nextCursor == null,
        currentPage: state.currentPage + 1,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// Change the sort without losing the filters, starting from the top.
  Future<void> setSort(String sort) async {
    if (sort == state.sort) return;

    await loadInitial(
      categorySlug: state.categorySlug,
      search: state.search,
      scholarSlug: state.scholarSlug,
      language: state.language,
      durationBuckets: state.durationBuckets,
      types: state.types,
      sort: sort,
    );
  }

  Future<VideoFeedPage> _fetch(String? cursor) async {
    final dio = ref.read(_dioProvider);

    final queryParams = <String, dynamic>{
      'per_page': 24,
      'sort': state.sort,
      if (cursor != null) 'cursor': cursor,
      if (state.categorySlug != null) 'category': state.categorySlug,
      if (state.scholarSlug != null) 'scholar': state.scholarSlug,
      if (state.language != null) 'language': state.language,
      if (state.search != null && state.search!.isNotEmpty) 'q': state.search,
      if (state.durationBuckets.isNotEmpty) 'duration[]': state.durationBuckets,
      if (state.types.isNotEmpty) 'type[]': state.types,
    };

    final response = await dio.get('/videos/feed', queryParameters: queryParams);
    return VideoFeedPage.fromJson(response.data as Map<String, dynamic>);
  }
}

final videoListProvider =
    NotifierProvider<VideoListNotifier, VideoListState>(VideoListNotifier.new);
