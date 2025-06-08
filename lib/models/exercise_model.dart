class Exercise {
  final String id;
  final String themeId;
  final String question;
  final String correctAnswer;
  final String? explanation;
  final String exerciseType;
  final int? orderIndex;

  Exercise({
    required this.id,
    required this.themeId,
    required this.question,
    required this.correctAnswer,
    this.explanation,
    this.exerciseType = 'text_input',
    this.orderIndex,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      themeId: json['theme_id'] as String,
      question: json['question'] as String,
      correctAnswer: json['correct_answer'] as String,
      explanation: json['explanation'] as String?,
      exerciseType: json['exercise_type'] as String,
      orderIndex: json['order_index'] as int?,
    );
  }
}
