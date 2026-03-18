import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ehsan_pathways/config/app_config.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class ArticleScholar {
  final String slug;
  final String name;
  final String? avatarUrl;

  const ArticleScholar({
    required this.slug,
    required this.name,
    this.avatarUrl,
  });

  factory ArticleScholar.fromJson(Map<String, dynamic> json) {
    return ArticleScholar(
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class ArticleCategory {
  final String slug;
  final String name;

  const ArticleCategory({required this.slug, required this.name});

  factory ArticleCategory.fromJson(Map<String, dynamic> json) {
    return ArticleCategory(
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class ArticleTag {
  final String name;
  final String slug;

  const ArticleTag({required this.name, required this.slug});

  factory ArticleTag.fromJson(Map<String, dynamic> json) {
    return ArticleTag(
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }
}

class Article {
  final String slug;
  final String title;
  final String? description;
  final String? content;
  final String? featuredImageUrl;
  final int? readingTimeMinutes;
  final DateTime? publishedAt;
  final ArticleScholar? scholar;
  final ArticleCategory? category;
  final List<ArticleTag> tags;
  final List<Article> relatedArticles;

  const Article({
    required this.slug,
    required this.title,
    this.description,
    this.content,
    this.featuredImageUrl,
    this.readingTimeMinutes,
    this.publishedAt,
    this.scholar,
    this.category,
    this.tags = const [],
    this.relatedArticles = const [],
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      content: (json['body_content'] ?? json['content']) as String?,
      featuredImageUrl: json['featured_image_url'] as String?,
      readingTimeMinutes: (json['reading_time_minutes'] as num?)?.toInt(),
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
      scholar: json['scholar'] != null
          ? ArticleScholar.fromJson(json['scholar'] as Map<String, dynamic>)
          : null,
      category: json['category'] != null
          ? ArticleCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => ArticleTag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      relatedArticles: (json['related_articles'] as List<dynamic>?)
              ?.map((e) => Article.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PaginatedArticles {
  final List<Article> data;
  final int currentPage;
  final int lastPage;
  final int total;

  const PaginatedArticles({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;

  factory PaginatedArticles.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? json;
    return PaginatedArticles(
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => Article.fromJson(e as Map<String, dynamic>))
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

class ArticleFilter {
  final int page;
  final String? categorySlug;
  final String? search;

  const ArticleFilter({
    this.page = 1,
    this.categorySlug,
    this.search,
  });

  ArticleFilter copyWith({
    int? page,
    String? categorySlug,
    String? search,
    bool clearCategory = false,
    bool clearSearch = false,
  }) {
    return ArticleFilter(
      page: page ?? this.page,
      categorySlug:
          clearCategory ? null : (categorySlug ?? this.categorySlug),
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

/// Holds the current filter state. UI updates this, and the articles list reacts.
class ArticleFilterNotifier extends Notifier<ArticleFilter> {
  @override
  ArticleFilter build() => const ArticleFilter();

  void update(ArticleFilter filter) {
    state = filter;
  }
}

final articleFilterProvider =
    NotifierProvider<ArticleFilterNotifier, ArticleFilter>(
        ArticleFilterNotifier.new);

/// Fetches a paginated list of articles based on the current filter.
final articlesProvider = FutureProvider<PaginatedArticles>((ref) async {
  final dio = ref.read(_dioProvider);
  final filter = ref.watch(articleFilterProvider);

  final queryParams = <String, dynamic>{
    'page': filter.page,
  };
  if (filter.categorySlug != null) {
    queryParams['category'] = filter.categorySlug;
  }
  if (filter.search != null && filter.search!.isNotEmpty) {
    queryParams['search'] = filter.search;
  }

  final response = await dio.get('/articles', queryParameters: queryParams);
  return PaginatedArticles.fromJson(response.data as Map<String, dynamic>);
});

/// Fetches a single article by slug.
final articleDetailProvider =
    FutureProvider.family<Article, String>((ref, slug) async {
  final dio = ref.read(_dioProvider);
  final response = await dio.get('/articles/$slug');
  final data = response.data as Map<String, dynamic>;
  return Article.fromJson(data['data'] as Map<String, dynamic>);
});

// ---------------------------------------------------------------------------
// List state + notifier (infinite scroll)
// ---------------------------------------------------------------------------

class ArticleListState {
  final List<Article> articles;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final String? categorySlug;
  final String? search;

  const ArticleListState({
    this.articles = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
    this.categorySlug,
    this.search,
  });

  ArticleListState copyWith({
    List<Article>? articles,
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
    return ArticleListState(
      articles: articles ?? this.articles,
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

/// Tracks accumulated article list across pages for infinite scroll.
class ArticleListNotifier extends Notifier<ArticleListState> {
  @override
  ArticleListState build() => const ArticleListState();

  Future<void> loadInitial({String? categorySlug, String? search}) async {
    state = ArticleListState(
      isLoading: true,
      categorySlug: categorySlug,
      search: search,
    );
    try {
      final result = await _fetchPage(
        1,
        categorySlug: categorySlug,
        search: search,
      );
      state = state.copyWith(
        articles: result.data,
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
        articles: [...state.articles, ...result.data],
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

  Future<PaginatedArticles> _fetchPage(
    int page, {
    String? categorySlug,
    String? search,
  }) async {
    final dio = ref.read(_dioProvider);
    final queryParams = <String, dynamic>{'page': page};
    if (categorySlug != null) queryParams['category'] = categorySlug;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await dio.get('/articles', queryParameters: queryParams);
    return PaginatedArticles.fromJson(response.data as Map<String, dynamic>);
  }
}

final articleListProvider =
    NotifierProvider<ArticleListNotifier, ArticleListState>(
        ArticleListNotifier.new);
