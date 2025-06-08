class UserProgress {
  final String id;
  final String userId;
  final String courseId;
  final String themeId;
  final double progressPercentage;
  final bool isCompleted;
  final DateTime lastViewedAt;

  UserProgress({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.themeId,
    required this.progressPercentage,
    required this.isCompleted,
    required this.lastViewedAt,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      courseId: json['course_id'] as String,
      themeId: json['theme_id'] as String,
      progressPercentage: (json['progress_percentage'] as num).toDouble(),
      isCompleted: json['is_completed'] as bool,
      lastViewedAt: DateTime.parse(json['last_viewed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'course_id': courseId,
      'theme_id': themeId,
      'progress_percentage': progressPercentage,
      'is_completed': isCompleted,
      'last_viewed_at': lastViewedAt.toIso8601String(),
    };
  }
}
