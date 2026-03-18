import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ehsan_pathways/config/app_config.dart';

// ---------------------------------------------------------------
// Data Models  (match the Laravel HomeController JSON exactly)
// ---------------------------------------------------------------

class ScholarSummary {
  final String slug;
  final String name;
  final String? photoUrl;
  final int? videoCount;

  const ScholarSummary({
    required this.slug,
    required this.name,
    this.photoUrl,
    this.videoCount,
  });

  factory ScholarSummary.fromJson(Map<String, dynamic> json) {
    return ScholarSummary(
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      videoCount: json['video_count'] as int?,
    );
  }
}

class _ScholarRef {
  final String slug;
  final String name;

  const _ScholarRef({required this.slug, required this.name});

  factory _ScholarRef.fromJson(Map<String, dynamic> json) {
    return _ScholarRef(
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class FeaturedVideo {
  final String uuid;
  final String slug;
  final String title;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final _ScholarRef scholar;

  const FeaturedVideo({
    required this.uuid,
    required this.slug,
    required this.title,
    this.thumbnailUrl,
    this.durationSeconds,
    required this.scholar,
  });

  factory FeaturedVideo.fromJson(Map<String, dynamic> json) {
    return FeaturedVideo(
      uuid: json['uuid'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      thumbnailUrl: json['thumbnail_url'] as String?,
      durationSeconds: json['duration_seconds'] as int?,
      scholar: _ScholarRef.fromJson(json['scholar'] as Map<String, dynamic>),
    );
  }

  String get formattedDuration {
    if (durationSeconds == null) return '';
    final m = durationSeconds! ~/ 60;
    final s = durationSeconds! % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class VideoSummary {
  final String uuid;
  final String slug;
  final String title;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final _ScholarRef scholar;

  const VideoSummary({
    required this.uuid,
    required this.slug,
    required this.title,
    this.thumbnailUrl,
    this.durationSeconds,
    required this.scholar,
  });

  factory VideoSummary.fromJson(Map<String, dynamic> json) {
    return VideoSummary(
      uuid: json['uuid'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      thumbnailUrl: json['thumbnail_url'] as String?,
      durationSeconds: json['duration_seconds'] as int?,
      scholar: _ScholarRef.fromJson(json['scholar'] as Map<String, dynamic>),
    );
  }

  String get formattedDuration {
    if (durationSeconds == null) return '';
    final m = durationSeconds! ~/ 60;
    final s = durationSeconds! % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class ArticleSummary {
  final String slug;
  final String title;
  final String? featuredImageUrl;
  final int? readingTimeMinutes;
  final _ScholarRef scholar;

  const ArticleSummary({
    required this.slug,
    required this.title,
    this.featuredImageUrl,
    this.readingTimeMinutes,
    required this.scholar,
  });

  factory ArticleSummary.fromJson(Map<String, dynamic> json) {
    return ArticleSummary(
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      featuredImageUrl: json['featured_image_url'] as String?,
      readingTimeMinutes: json['reading_time_minutes'] as int?,
      scholar: _ScholarRef.fromJson(json['scholar'] as Map<String, dynamic>),
    );
  }
}

class PodcastSummary {
  final String slug;
  final String title;
  final String? coverImageUrl;
  final int? durationSeconds;
  final _ScholarRef scholar;

  const PodcastSummary({
    required this.slug,
    required this.title,
    this.coverImageUrl,
    this.durationSeconds,
    required this.scholar,
  });

  factory PodcastSummary.fromJson(Map<String, dynamic> json) {
    return PodcastSummary(
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      coverImageUrl: json['cover_image_url'] as String?,
      durationSeconds: json['duration_seconds'] as int?,
      scholar: _ScholarRef.fromJson(json['scholar'] as Map<String, dynamic>),
    );
  }

  String get formattedDuration {
    if (durationSeconds == null) return '';
    final m = durationSeconds! ~/ 60;
    final s = durationSeconds! % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class CategorySummary {
  final String slug;
  final String name;
  final String? icon;

  const CategorySummary({
    required this.slug,
    required this.name,
    this.icon,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String?,
    );
  }
}

// ---------------------------------------------------------------
// Aggregate Home Data
// ---------------------------------------------------------------

class HomeData {
  final FeaturedVideo? featuredVideo;
  final List<VideoSummary> recentVideos;
  final List<ArticleSummary> recentArticles;
  final List<PodcastSummary> recentPodcasts;
  final List<CategorySummary> categories;
  final List<ScholarSummary> scholars;

  const HomeData({
    this.featuredVideo,
    this.recentVideos = const [],
    this.recentArticles = const [],
    this.recentPodcasts = const [],
    this.categories = const [],
    this.scholars = const [],
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return HomeData(
      featuredVideo: data['featured_video'] != null
          ? FeaturedVideo.fromJson(data['featured_video'] as Map<String, dynamic>)
          : null,
      recentVideos: (data['recent_videos'] as List<dynamic>? ?? [])
          .map((e) => VideoSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentArticles: (data['recent_articles'] as List<dynamic>? ?? [])
          .map((e) => ArticleSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentPodcasts: (data['recent_podcasts'] as List<dynamic>? ?? [])
          .map((e) => PodcastSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      categories: (data['categories'] as List<dynamic>? ?? [])
          .map((e) => CategorySummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      scholars: (data['scholars'] as List<dynamic>? ?? [])
          .map((e) => ScholarSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------
// Dio Client Provider
// ---------------------------------------------------------------

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: Duration(milliseconds: AppConfig.connectTimeout),
    receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
    sendTimeout: Duration(milliseconds: AppConfig.sendTimeout),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  return dio;
});

// ---------------------------------------------------------------
// Home Data Provider
// ---------------------------------------------------------------

final homeDataProvider = FutureProvider.autoDispose<HomeData>((ref) async {
  final dio = ref.watch(dioProvider);

  // Try the dedicated /home endpoint first
  try {
    final response = await dio.get('/home');
    if (response.statusCode == 200) {
      final body = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;
      return HomeData.fromJson(body);
    }
  } catch (_) {
    // /home not available – fall through to build from individual endpoints
  }

  // Fallback: build home data from /videos + /scholars
  final results = await Future.wait([
    dio.get('/videos', queryParameters: {'per_page': 10}),
    dio.get('/scholars'),
  ]);

  final videosBody = results[0].data as Map<String, dynamic>;
  final scholarsBody = results[1].data as Map<String, dynamic>;

  final videosList = (videosBody['data'] as List<dynamic>? ?? [])
      .map((e) => e as Map<String, dynamic>)
      .toList();

  // First video becomes featured, rest become recent
  FeaturedVideo? featured;
  final recentVideos = <VideoSummary>[];

  for (var i = 0; i < videosList.length; i++) {
    final v = videosList[i];
    // Ensure a scholar map exists for the model constructors
    final scholarMap = v['scholar'] as Map<String, dynamic>? ??
        {'slug': '', 'name': 'Unknown'};
    v['scholar'] = scholarMap;

    if (i == 0) {
      featured = FeaturedVideo.fromJson(v);
    } else {
      recentVideos.add(VideoSummary.fromJson(v));
    }
  }

  // Collect unique categories from videos
  final seenCategorySlugs = <String>{};
  final categories = <CategorySummary>[];
  for (final v in videosList) {
    final cat = v['category'] as Map<String, dynamic>?;
    if (cat != null) {
      final slug = cat['slug'] as String? ?? '';
      if (slug.isNotEmpty && seenCategorySlugs.add(slug)) {
        categories.add(CategorySummary.fromJson(cat));
      }
    }
  }

  final scholars = (scholarsBody['data'] as List<dynamic>? ?? [])
      .map((e) => ScholarSummary.fromJson(e as Map<String, dynamic>))
      .toList();

  return HomeData(
    featuredVideo: featured,
    recentVideos: recentVideos,
    categories: categories,
    scholars: scholars,
  );
});
