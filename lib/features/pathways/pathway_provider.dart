import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ehsan_pathways/core/services/api_service.dart';
import 'package:ehsan_pathways/core/json_read.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class Pathway {
  final int id;
  final String slug;
  final String title;
  final String? description;
  final String? difficultyLevel;
  final String? thumbnailUrl;
  final int totalItems;
  final double? estimatedHours;
  final int stagesCount;

  const Pathway({
    required this.id,
    required this.slug,
    required this.title,
    this.description,
    this.difficultyLevel,
    this.thumbnailUrl,
    this.totalItems = 0,
    this.estimatedHours,
    this.stagesCount = 0,
  });

  factory Pathway.fromJson(Map<String, dynamic> json) {
    return Pathway(
      id: jInt(json['id']) ?? 0,
      slug: jStr(json['slug']) ?? '',
      title: jStr(json['title']) ?? 'Untitled Pathway',
      description: jStr(json['description']),
      difficultyLevel: jStr(json['difficulty_level']),
      thumbnailUrl: jStr(json['thumbnail_url']),
      totalItems: jInt(json['total_items']) ??
          jInt(json['items_count']) ??
          0,
      estimatedHours: jDouble(json['estimated_hours']),
      stagesCount: jInt(json['stages_count']) ?? 0,
    );
  }

  /// "14h" or "1.5h"; the server sends a decimal.
  String? get hoursLabel {
    final h = estimatedHours;
    if (h == null || h <= 0) return null;
    return '${h == h.roundToDouble() ? h.toInt() : h}h';
  }

  String get levelLabel {
    switch (difficultyLevel?.toLowerCase()) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return difficultyLevel ?? 'All Levels';
    }
  }
}

class PathwayDetail {
  final Pathway pathway;
  final List<PathwayStage> stages;
  final bool isEnrolled;
  final int completedItems;
  final double progressPercentage;

  const PathwayDetail({
    required this.pathway,
    this.stages = const [],
    this.isEnrolled = false,
    this.completedItems = 0,
    this.progressPercentage = 0,
  });

  factory PathwayDetail.fromJson(Map<String, dynamic> json) {
    final pathwayData = json['pathway'] as Map<String, dynamic>? ?? json;

    return PathwayDetail(
      pathway: Pathway.fromJson(pathwayData),
      stages: (json['stages'] as List<dynamic>? ??
              pathwayData['stages'] as List<dynamic>? ??
              [])
          .map((e) => PathwayStage.fromJson(e as Map<String, dynamic>))
          .toList(),
      isEnrolled: jBool(json['is_enrolled']) ?? false,
      completedItems: jInt(json['completed_items']) ?? 0,
      progressPercentage:
          (jNum(json['progress_percentage']))?.toDouble() ?? 0,
    );
  }
}

/// One lesson inside a stage: a video, article, podcast, document or khutbah.
class PathwayLesson {
  final int id;
  final String type;
  final String key;
  final String title;
  final int? minutes;
  final bool completed;

  const PathwayLesson({
    required this.id,
    required this.type,
    required this.key,
    required this.title,
    this.minutes,
    this.completed = false,
  });

  factory PathwayLesson.fromJson(Map<String, dynamic> json) => PathwayLesson(
        id: jInt(json['id']) ?? 0,
        type: jStr(json['type']) ?? '',
        key: jStr(json['key']) ?? '',
        title: jStr(json['title']) ?? 'Untitled',
        minutes: jInt(json['estimated_minutes']),
        completed: jBool(json['completed']) ?? false,
      );

  /// Where tapping the lesson goes in the app, or null if the app has no
  /// screen for that type.
  String? get route => switch (type) {
        'video' => '/videos/$key',
        'article' => '/articles/$key',
        'podcast' => '/podcasts/$key',
        'khutbah' => '/khutbahs/$key',
        _ => null,
      };

  String get typeLabel => switch (type) {
        'video' => 'Video',
        'article' => 'Article',
        'podcast' => 'Podcast',
        'document' => 'Reading',
        'khutbah' => 'Khutbah',
        _ => type,
      };
}

class PathwayStage {
  final int id;
  final int order;
  final String title;
  final String? description;
  final List<PathwayLesson> lessons;

  const PathwayStage({
    required this.id,
    required this.order,
    required this.title,
    this.description,
    this.lessons = const [],
  });

  bool get isComplete => lessons.isNotEmpty && lessons.every((l) => l.completed);

  factory PathwayStage.fromJson(Map<String, dynamic> json) {
    return PathwayStage(
      id: jInt(json['id']) ?? 0,
      order: jInt(json['order']) ?? jInt(json['stage_number']) ?? 0,
      title: jStr(json['title']) ?? 'Stage',
      description: jStr(json['description']),
      lessons: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PathwayLesson.fromJson)
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final pathwayListProvider = FutureProvider.autoDispose<List<Pathway>>((ref) async {
  final dio = ref.read(apiProvider);
  final response = await dio.get('/pathways');

  final body = response.data is String
      ? jsonDecode(response.data as String) as Map<String, dynamic>
      : response.data as Map<String, dynamic>;

  final items = body['data'] as List<dynamic>? ?? [];
  return items
      .map((e) => Pathway.fromJson(e as Map<String, dynamic>))
      .toList();
});

final pathwayDetailProvider =
    FutureProvider.family.autoDispose<PathwayDetail, String>((ref, slug) async {
  final dio = ref.read(apiProvider);
  final response = await dio.get('/pathways/$slug');

  final body = response.data is String
      ? jsonDecode(response.data as String) as Map<String, dynamic>
      : response.data as Map<String, dynamic>;

  final data = body['data'] as Map<String, dynamic>? ?? body;
  return PathwayDetail.fromJson(data);
});

/// Enrol, and mark lessons done. Both return the updated detail and refresh
/// the screen; progress is kept on the server, the same as the website.
class PathwayActions {
  PathwayActions(this.ref);
  final Ref ref;

  Future<void> enroll(String slug) async {
    await ref.read(apiProvider).post('/pathways/$slug/enroll');
    ref.invalidate(pathwayDetailProvider(slug));
  }

  Future<void> complete(String slug, int lessonId) async {
    await ref.read(apiProvider).post('/pathways/$slug/items/$lessonId/complete');
    ref.invalidate(pathwayDetailProvider(slug));
  }
}

final pathwayActionsProvider = Provider<PathwayActions>(PathwayActions.new);
