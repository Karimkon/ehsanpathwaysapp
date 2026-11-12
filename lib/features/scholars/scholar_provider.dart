import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ehsan_pathways/core/json_read.dart';
import 'package:ehsan_pathways/core/services/api_service.dart';

// ---------------------------------------------------------------------------
// Scholar Model
// ---------------------------------------------------------------------------

class Scholar {
  final String slug;
  final String name;
  final String? title;
  final String? bio;
  final String? photoUrl;
  final int videoCount;
  final int articleCount;
  final int podcastCount;

  const Scholar({
    required this.slug,
    required this.name,
    this.title,
    this.bio,
    this.photoUrl,
    this.videoCount = 0,
    this.articleCount = 0,
    this.podcastCount = 0,
  });

  /// Total content items across all types.
  int get totalContent => videoCount + articleCount + podcastCount;

  factory Scholar.fromJson(Map<String, dynamic> json) {
    return Scholar(
      slug: jStr(json['slug']) ?? '',
      name: jStr(json['name']) ?? 'Unknown',
      title: jStr(json['title']),
      bio: jStr(json['bio']),
      photoUrl: jStr(json['photo_url']),
      videoCount: (jNum(json['video_count']))?.toInt() ?? 0,
      articleCount: (jNum(json['article_count']))?.toInt() ?? 0,
      podcastCount: (jNum(json['podcast_count']))?.toInt() ?? 0,
    );
  }
}

// ---------------------------------------------------------------------------
// Scholar Content Item (for detail tabs)
// ---------------------------------------------------------------------------

class ScholarContentItem {
  final String identifier;
  final String title;
  final String? imageUrl;
  final String? duration;
  final String type;

  const ScholarContentItem({
    required this.identifier,
    required this.title,
    this.imageUrl,
    this.duration,
    required this.type,
  });

  factory ScholarContentItem.fromJson(Map<String, dynamic> json) {
    return ScholarContentItem(
      identifier: (json['uuid'] ?? json['slug'] ?? '') as String,
      title: jStr(json['title']) ?? '',
      imageUrl: (json['thumbnail_url'] ?? json['featured_image_url'] ?? json['cover_image_url']) as String?,
      duration: jStr(json['duration_formatted']),
      type: jStr(json['type']) ?? 'video',
    );
  }
}

// ---------------------------------------------------------------------------
// Dio provider
// ---------------------------------------------------------------------------

/// The shared client: one base URL, and the sign-in token on every request.
final _dioProvider = Provider<Dio>((ref) => ref.watch(apiProvider));

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Fetches the full list of scholars from GET /scholars.
final scholarsListProvider = FutureProvider<List<Scholar>>((ref) async {
  final dio = ref.read(_dioProvider);
  final response = await dio.get('/scholars');
  final data = response.data as Map<String, dynamic>;
  final list = data['data'] as List<dynamic>? ?? [];
  return list
      .map((e) => Scholar.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Fetches a single scholar by slug from GET /scholars/{slug}.
final scholarDetailProvider =
    FutureProvider.family<Scholar, String>((ref, slug) async {
  final dio = ref.read(_dioProvider);
  final response = await dio.get('/scholars/$slug');
  final data = response.data as Map<String, dynamic>;
  return Scholar.fromJson(data['data'] as Map<String, dynamic>);
});

/// Fetches a scholar's videos from GET /scholars/{slug}/videos.
final scholarVideosProvider =
    FutureProvider.family<List<ScholarContentItem>, String>((ref, slug) async {
  final dio = ref.read(_dioProvider);
  final response = await dio.get('/scholars/$slug/videos');
  final data = response.data as Map<String, dynamic>;
  final list = data['data'] as List<dynamic>? ?? [];
  return list
      .map((e) => ScholarContentItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Fetches a scholar's articles from GET /scholars/{slug}/articles.
final scholarArticlesProvider =
    FutureProvider.family<List<ScholarContentItem>, String>((ref, slug) async {
  final dio = ref.read(_dioProvider);
  final response = await dio.get('/scholars/$slug/articles');
  final data = response.data as Map<String, dynamic>;
  final list = data['data'] as List<dynamic>? ?? [];
  return list
      .map((e) => ScholarContentItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Fetches a scholar's podcasts from GET /scholars/{slug}/podcasts.
final scholarPodcastsProvider =
    FutureProvider.family<List<ScholarContentItem>, String>((ref, slug) async {
  final dio = ref.read(_dioProvider);
  final response = await dio.get('/scholars/$slug/podcasts');
  final data = response.data as Map<String, dynamic>;
  final list = data['data'] as List<dynamic>? ?? [];
  return list
      .map((e) => ScholarContentItem.fromJson(e as Map<String, dynamic>))
      .toList();
});
