class UserAnswer {
  final String id;
  final String userId;
  final String exerciseId;
  final String userAnswer;
  final bool isCorrect;
  final DateTime answeredAt;

  UserAnswer({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.userAnswer,
    required this.isCorrect,
    required this.answeredAt,
  });

  factory UserAnswer.fromJson(Map<String, dynamic> json) {
    return UserAnswer(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      exerciseId: json['exercise_id'] as String,
      userAnswer: json['user_answer'] as String,
      isCorrect: json['is_correct'] as bool,
      answeredAt: DateTime.parse(json['answered_at'] as String),
    );
  }
}
