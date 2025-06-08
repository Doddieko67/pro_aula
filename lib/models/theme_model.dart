class CourseTheme {
  final String id;
  final String courseId;
  final String title;
  final Map<String, dynamic> content; // JSONB
  final int orderIndex;
  final List<String> exerciseIds; // Para saber qué ejercicios tiene este tema
  final List<String> formIds; // Para saber qué formularios tiene este tema

  CourseTheme({
    required this.id,
    required this.courseId,
    required this.title,
    required this.content,
    required this.orderIndex,
    this.exerciseIds = const [],
    this.formIds = const [],
  });

  factory CourseTheme.fromJson(Map<String, dynamic> json) {
    // Asegúrate de que los campos 'exercises' y 'forms' existan y sean arrays
    final List<String> exercises =
        (json['exercises'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final List<String> forms =
        (json['forms'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return CourseTheme(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      title: json['title'] as String,
      content:
          json['content']
              as Map<String, dynamic>, // Cast directamente si es JSONB
      orderIndex: json['order_index'] as int,
      exerciseIds: exercises,
      formIds: forms,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'content': content,
      'order_index': orderIndex,
      'exercises': exerciseIds,
      'forms': formIds,
    };
  }
}
