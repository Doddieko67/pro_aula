class FormModel {
  // Renombrado para evitar conflicto con Form de Flutter
  final String id;
  final String courseId;
  final String themeId;
  final String title;
  final List<dynamic> questions; // List of question maps

  FormModel({
    required this.id,
    required this.courseId,
    required this.themeId,
    required this.title,
    required this.questions,
  });

  factory FormModel.fromJson(Map<String, dynamic> json) {
    return FormModel(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      themeId: json['theme_id'] as String,
      title: json['title'] as String,
      questions:
          json['questions'] as List<dynamic>, // Directly cast JSONB array
    );
  }
}
