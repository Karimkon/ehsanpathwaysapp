import 'package:ehsan_pathways/core/json_read.dart';
/// Holds user engagement statistics fetched from /user/stats.
class UserStatsModel {
  final int videosWatched;
  final int bookmarks;
  final int notes;
  final int pathwaysEnrolled;

  const UserStatsModel({
    required this.videosWatched,
    required this.bookmarks,
    required this.notes,
    required this.pathwaysEnrolled,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      videosWatched: jInt(json['videos_watched']) ?? 0,
      bookmarks: jInt(json['bookmarks']) ?? 0,
      notes: jInt(json['notes']) ?? 0,
      pathwaysEnrolled: jInt(json['pathways_enrolled']) ?? 0,
    );
  }

  static const empty = UserStatsModel(
    videosWatched: 0,
    bookmarks: 0,
    notes: 0,
    pathwaysEnrolled: 0,
  );
}
