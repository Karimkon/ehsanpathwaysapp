import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ehsan_pathways/core/services/api_service.dart';

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
  final int? estimatedHours;

  const Pathway({
    required this.id,
    required this.slug,
    required this.title,
    this.description,
    this.difficultyLevel,
    this.thumbnailUrl,
    this.totalItems = 0,
    this.estimatedHours,
  });

  factory Pathway.fromJson(Map<String, dynamic> json) {
    return Pathway(
      id: json['id'] as int? ?? 0,
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Pathway',
      description: json['description'] as String?,
      difficultyLevel: json['difficulty_level'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      totalItems: json['total_items'] as int? ??
          json['items_count'] as int? ??
          0,
      estimatedHours: json['estimated_hours'] as int?,
    );
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
      isEnrolled: json['is_enrolled'] as bool? ?? false,
      completedItems: json['completed_items'] as int? ?? 0,
      progressPercentage:
          (json['progress_percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PathwayStage {
  final int id;
  final int order;
  final String title;
  final String? description;
  final String contentType;
  final String? contentId;

  const PathwayStage({
    required this.id,
    required this.order,
    required this.title,
    this.description,
    required this.contentType,
    this.contentId,
  });

  factory PathwayStage.fromJson(Map<String, dynamic> json) {
    return PathwayStage(
      id: json['id'] as int? ?? 0,
      order: json['order'] as int? ?? json['stage_number'] as int? ?? 0,
      title: json['title'] as String? ?? 'Stage',
      description: json['description'] as String?,
      contentType: json['content_type'] as String? ?? '',
      contentId: json['content_id']?.toString(),
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
