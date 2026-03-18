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
      videosWatched: json['videos_watched'] as int? ?? 0,
      bookmarks: json['bookmarks'] as int? ?? 0,
      notes: json['notes'] as int? ?? 0,
      pathwaysEnrolled: json['pathways_enrolled'] as int? ?? 0,
    );
  }

  static const empty = UserStatsModel(
    videosWatched: 0,
    bookmarks: 0,
    notes: 0,
    pathwaysEnrolled: 0,
  );
}
