import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ehsan_pathways/config/app_config.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class PodcastScholar {
  final String slug;
  final String name;
  final String? avatarUrl;

  const PodcastScholar({
    required this.slug,
    required this.name,
    this.avatarUrl,
  });

  factory PodcastScholar.fromJson(Map<String, dynamic> json) {
    return PodcastScholar(
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class PodcastSeries {
  final String slug;
  final String title;

  const PodcastSeries({
    required this.slug,
    required this.title,
  });

  factory PodcastSeries.fromJson(Map<String, dynamic> json) {
    return PodcastSeries(
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
    );
  }
}

class Podcast {
  final String slug;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final String? audioUrl;
  final int durationSeconds;
  final int? episodeNumber;
  final String? publishedAt;
  final PodcastScholar? scholar;
  final PodcastSeries? series;
  final List<Podcast> relatedPodcasts;

  const Podcast({
    required this.slug,
    required this.title,
    this.description,
    this.coverImageUrl,
    this.audioUrl,
    this.durationSeconds = 0,
    this.episodeNumber,
    this.publishedAt,
    this.scholar,
    this.series,
    this.relatedPodcasts = const [],
  });

  /// Human-readable duration string, e.g. "1h 23m" or "45m 12s".
  String get formattedDuration {
    if (durationSeconds <= 0) return '0:00';
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      audioUrl: json['audio_url'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      episodeNumber: (json['episode_number'] as num?)?.toInt(),
      publishedAt: json['published_at'] as String?,
      scholar: json['scholar'] != null
          ? PodcastScholar.fromJson(json['scholar'] as Map<String, dynamic>)
          : null,
      series: json['series'] != null
          ? PodcastSeries.fromJson(json['series'] as Map<String, dynamic>)
          : null,
      relatedPodcasts: (json['related_podcasts'] as List<dynamic>?)
              ?.map((e) => Podcast.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PaginatedPodcasts {
  final List<Podcast> data;
  final int currentPage;
  final int lastPage;
  final int total;

  const PaginatedPodcasts({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;

  factory PaginatedPodcasts.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? json;
    return PaginatedPodcasts(
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => Podcast.fromJson(e as Map<String, dynamic>))
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

class PodcastFilter {
  final int page;
  final String? seriesSlug;
  final String? scholarSlug;
  final String? search;

  const PodcastFilter({
    this.page = 1,
    this.seriesSlug,
    this.scholarSlug,
    this.search,
  });

  PodcastFilter copyWith({
    int? page,
    String? seriesSlug,
    String? scholarSlug,
    String? search,
    bool clearSeries = false,
    bool clearScholar = false,
    bool clearSearch = false,
  }) {
    return PodcastFilter(
      page: page ?? this.page,
      seriesSlug: clearSeries ? null : (seriesSlug ?? this.seriesSlug),
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

/// Holds the current filter state. UI updates this, and the podcast list reacts.
class PodcastFilterNotifier extends Notifier<PodcastFilter> {
  @override
  PodcastFilter build() => const PodcastFilter();

  void update(PodcastFilter filter) {
    state = filter;
  }
}

final podcastFilterProvider =
    NotifierProvider<PodcastFilterNotifier, PodcastFilter>(
        PodcastFilterNotifier.new);

/// Fetches a paginated list of podcasts based on the current filter.
final podcastsProvider = FutureProvider<PaginatedPodcasts>((ref) async {
  final dio = ref.read(_dioProvider);
  final filter = ref.watch(podcastFilterProvider);

  final queryParams = <String, dynamic>{
    'page': filter.page,
  };
  if (filter.seriesSlug != null) queryParams['series'] = filter.seriesSlug;
  if (filter.scholarSlug != null) queryParams['scholar'] = filter.scholarSlug;
  if (filter.search != null && filter.search!.isNotEmpty) {
    queryParams['search'] = filter.search;
  }

  final response = await dio.get('/podcasts', queryParameters: queryParams);
  return PaginatedPodcasts.fromJson(response.data as Map<String, dynamic>);
});

/// Fetches a single podcast by slug.
final podcastDetailProvider =
    FutureProvider.family<Podcast, String>((ref, slug) async {
  final dio = ref.read(_dioProvider);
  final response = await dio.get('/podcasts/$slug');
  final data = response.data as Map<String, dynamic>;
  return Podcast.fromJson(data['data'] as Map<String, dynamic>);
});

// ---------------------------------------------------------------------------
// List state + notifier (infinite scroll)
// ---------------------------------------------------------------------------

class PodcastListState {
  final List<Podcast> podcasts;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final String? seriesSlug;
  final String? search;

  const PodcastListState({
    this.podcasts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
    this.seriesSlug,
    this.search,
  });

  PodcastListState copyWith({
    List<Podcast>? podcasts,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    String? seriesSlug,
    String? search,
    bool clearError = false,
    bool clearSeries = false,
    bool clearSearch = false,
  }) {
    return PodcastListState(
      podcasts: podcasts ?? this.podcasts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: clearError ? null : (error ?? this.error),
      seriesSlug: clearSeries ? null : (seriesSlug ?? this.seriesSlug),
      search: clearSearch ? null : (search ?? this.search),
    );
  }
}

/// Tracks accumulated podcast list across pages for infinite scroll.
class PodcastListNotifier extends Notifier<PodcastListState> {
  @override
  PodcastListState build() => const PodcastListState();

  Future<void> loadInitial({String? seriesSlug, String? search}) async {
    state = PodcastListState(
      isLoading: true,
      seriesSlug: seriesSlug,
      search: search,
    );
    try {
      final result =
          await _fetchPage(1, seriesSlug: seriesSlug, search: search);
      state = state.copyWith(
        podcasts: result.data,
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
        seriesSlug: state.seriesSlug,
        search: state.search,
      );
      state = state.copyWith(
        podcasts: [...state.podcasts, ...result.data],
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

  Future<PaginatedPodcasts> _fetchPage(
    int page, {
    String? seriesSlug,
    String? search,
  }) async {
    final dio = ref.read(_dioProvider);
    final queryParams = <String, dynamic>{'page': page};
    if (seriesSlug != null) queryParams['series'] = seriesSlug;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await dio.get('/podcasts', queryParameters: queryParams);
    return PaginatedPodcasts.fromJson(response.data as Map<String, dynamic>);
  }
}

final podcastListProvider =
    NotifierProvider<PodcastListNotifier, PodcastListState>(
        PodcastListNotifier.new);
