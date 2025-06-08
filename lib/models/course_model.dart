import 'package:pro_aula/models/theme_model.dart';

class Course {
  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String difficulty;
  final bool isPublished;
  final List<CourseTheme>?
  themes; // Opcional, para el join en CourseDetailScreen

  Course({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.difficulty,
    this.isPublished = false,
    this.themes,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    List<CourseTheme>? themes;
    if (json['themes'] != null) {
      themes = (json['themes'] as List)
          .map((i) => CourseTheme.fromJson(i as Map<String, dynamic>))
          .toList();
      themes.sort(
        (a, b) => a.orderIndex.compareTo(b.orderIndex),
      ); // Ordenar temas
    }

    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      difficulty: json['difficulty'] as String,
      isPublished: json['is_published'] as bool,
      themes: themes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'difficulty': difficulty,
      'is_published': isPublished,
    };
  }
}
