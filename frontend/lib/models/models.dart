/// Serializable domain models for the Biddyan client.
///
/// All models mirror the JSON payloads produced by the Node.js/Express
/// backend (see `backend/src/controllers/*`).
library;

class AuthUser {
  const AuthUser({
    required this.token,
    required this.userId,
    required this.phoneNumber,
    required this.displayName,
    this.role = 'student',
    this.email,
  });

  final String token;
  final String userId;
  final String phoneNumber;
  final String displayName;
  final String role;
  final String? email;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    return AuthUser(
      token: json['token'] as String,
      userId: json['userId'] as String,
      phoneNumber: (user['phoneNumber'] as String?) ?? '',
      displayName: (user['displayName'] as String?) ??
          (user['email'] as String?) ??
          'Biddyan User',
      role: (user['role'] as String?) ?? 'student',
      email: user['email'] as String?,
    );
  }
}

class TopicNode {
  const TopicNode({
    required this.id,
    required this.name,
    this.parentId,
    this.children = const [],
  });

  final String id;
  final String name;
  final String? parentId;
  final List<TopicNode> children;

  factory TopicNode.fromJson(Map<String, dynamic> json) {
    return TopicNode(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parent_id'] as String?,
      children: (json['children'] as List<dynamic>? ?? const [])
          .map((e) => TopicNode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Question {
  const Question({
    required this.id,
    required this.topicId,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    this.correctOption,
    this.explanation,
    this.previousYears = const [],
    this.difficultyLevel = 'medium',
    this.topicName,
    this.examType,
    this.questionSet,
    this.source = 'admin',
  });

  final String id;
  final String topicId;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String? correctOption;
  final String? explanation;
  final List<String> previousYears;
  final String difficultyLevel;
  final String? topicName;
  final String? examType;
  final String? questionSet;
  final String source;

  List<String> get options => [optionA, optionB, optionC, optionD];

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      topicId: json['topic_id'] as String,
      questionText: json['question_text'] as String,
      optionA: json['option_a'] as String? ?? '',
      optionB: json['option_b'] as String? ?? '',
      optionC: json['option_c'] as String? ?? '',
      optionD: json['option_d'] as String? ?? '',
      correctOption: json['correct_option'] as String?,
      explanation: json['explanation'] as String?,
      previousYears: (json['previous_years'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      difficultyLevel: (json['difficulty_level'] as String?) ?? 'medium',
      topicName: json['topic_name'] as String?,
      examType: json['exam_type'] as String?,
      questionSet: json['question_set'] as String?,
      source: (json['source'] as String?) ?? 'admin',
    );
  }
}

class Exam {
  const Exam({
    required this.id,
    required this.title,
    required this.totalMarks,
    required this.negativeMarking,
    required this.durationMinutes,
    required this.isLive,
    this.topicId,
    this.topicName,
    this.startsAt,
    this.endsAt,
    this.questions = const [],
  });

  final String id;
  final String title;
  final String? topicId;
  final String? topicName;
  final double totalMarks;
  final double negativeMarking;
  final int durationMinutes;
  final bool isLive;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final List<Question> questions;

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] as String,
      title: json['title'] as String,
      topicId: json['topic_id'] as String?,
      topicName: json['topic_name'] as String?,
      startsAt: _parseDate(json['starts_at']),
      endsAt: _parseDate(json['ends_at']),
      totalMarks: double.parse((json['total_marks'] ?? 0).toString()),
      negativeMarking:
          double.parse((json['negative_marking_per_wrong'] ?? 0).toString()),
      durationMinutes: json['duration_minutes'] as int,
      isLive: json['is_live'] as bool? ?? false,
      questions: (json['questions'] as List<dynamic>? ?? const [])
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Exam copyWith({
    String? id,
    String? title,
    String? topicId,
    String? topicName,
    double? totalMarks,
    double? negativeMarking,
    int? durationMinutes,
    bool? isLive,
    DateTime? startsAt,
    DateTime? endsAt,
    List<Question>? questions,
  }) {
    return Exam(
      id: id ?? this.id,
      title: title ?? this.title,
      topicId: topicId ?? this.topicId,
      topicName: topicName ?? this.topicName,
      totalMarks: totalMarks ?? this.totalMarks,
      negativeMarking: negativeMarking ?? this.negativeMarking,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isLive: isLive ?? this.isLive,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      questions: questions ?? this.questions,
    );
  }

  static DateTime? _parseDate(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.score,
    required this.rank,
  });

  final String userId;
  final double score;
  final int rank;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String,
      score: double.parse(json['score'].toString()),
      rank: json['rank'] as int,
    );
  }
}

class AttemptResult {
  const AttemptResult({
    required this.attemptId,
    required this.score,
    required this.correctCount,
    required this.wrongCount,
    required this.rank,
    required this.totalExaminees,
    this.breakdown = const [],
  });

  final String attemptId;
  final double score;
  final int correctCount;
  final int wrongCount;
  final int? rank;
  final int totalExaminees;
  final List<AnswerBreakdown> breakdown;

  factory AttemptResult.fromJson(Map<String, dynamic> json) {
    return AttemptResult(
      attemptId: json['attemptId'] as String,
      score: double.parse(json['score'].toString()),
      correctCount: json['correctCount'] as int,
      wrongCount: json['wrongCount'] as int,
      rank: json['rank'] as int?,
      totalExaminees: json['totalExaminees'] as int? ?? 0,
      breakdown: (json['breakdown'] as List<dynamic>? ?? const [])
          .map((e) => AnswerBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AnswerBreakdown {
  const AnswerBreakdown({
    required this.questionId,
    required this.selectedOption,
    required this.isCorrect,
    required this.explanation,
  });

  final String questionId;
  final String selectedOption;
  final bool isCorrect;
  final String explanation;

  factory AnswerBreakdown.fromJson(Map<String, dynamic> json) {
    return AnswerBreakdown(
      questionId: json['questionId'] as String,
      selectedOption: json['selectedOption'] as String,
      isCorrect: json['isCorrect'] as bool,
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

/// Payload sent when a user submits an exam.
class AnswerSubmission {
  const AnswerSubmission({
    required this.questionId,
    required this.selectedOption,
  });

  final String questionId;
  final String selectedOption;

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'selectedOption': selectedOption,
      };
}
