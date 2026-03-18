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

  const VideoListState({
    this.videos = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
    this.categorySlug,
    this.search,
  });

  VideoListState copyWith({
    List<Video>? videos,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    String? categorySlug,
    String? search,
    bool clearError = false,
    bool clearCategory = false,
    bool clearSearch = false,
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
    );
  }
}

class VideoListNotifier extends Notifier<VideoListState> {
  @override
  VideoListState build() {
    return const VideoListState();
  }

  Future<void> loadInitial({String? categorySlug, String? search}) async {
    state = VideoListState(
      isLoading: true,
      categorySlug: categorySlug,
      search: search,
    );
    try {
      final result = await _fetchPage(1, categorySlug: categorySlug, search: search);
      state = state.copyWith(
        videos: result.data,
        isLoading: false,
        hasMore: result.hasMore,
        currentPage: 1,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final result = await _fetchPage(
        nextPage,
        categorySlug: state.categorySlug,
        search: state.search,
      );
      state = state.copyWith(
        videos: [...state.videos, ...result.data],
        isLoadingMore: false,
        hasMore: result.hasMore,
        currentPage: nextPage,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<PaginatedVideos> _fetchPage(
    int page, {
    String? categorySlug,
    String? search,
  }) async {
    final dio = ref.read(_dioProvider);
    final queryParams = <String, dynamic>{'page': page};
    if (categorySlug != null) queryParams['category'] = categorySlug;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await dio.get('/videos', queryParameters: queryParams);
    return PaginatedVideos.fromJson(response.data as Map<String, dynamic>);
  }
}

final videoListProvider =
    NotifierProvider<VideoListNotifier, VideoListState>(VideoListNotifier.new);
