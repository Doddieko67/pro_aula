class UserFormSubmission {
  final String id;
  final String userId;
  final String formId;
  final Map<String, dynamic> answers; // JSONB
  final double? score;
  final DateTime submittedAt;

  UserFormSubmission({
    required this.id,
    required this.userId,
    required this.formId,
    required this.answers,
    this.score,
    required this.submittedAt,
  });

  factory UserFormSubmission.fromJson(Map<String, dynamic> json) {
    return UserFormSubmission(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      formId: json['form_id'] as String,
      answers: json['answers'] as Map<String, dynamic>,
      score: (json['score'] as num?)?.toDouble(),
      submittedAt: DateTime.parse(json['submitted_at'] as String),
    );
  }
}
