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

class UserProfile {
  const UserProfile({
    required this.id,
    required this.phoneNumber,
    required this.displayName,
    this.email,
    this.profileImageUrl,
    this.preparationCategories = const [],
    this.notificationsEnabled = true,
    this.preferredLanguage = 'বাংলা',
  });

  final String id;
  final String phoneNumber;
  final String displayName;
  final String? email;
  final String? profileImageUrl;
  final List<String> preparationCategories;
  final bool notificationsEnabled;
  final String preferredLanguage;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        phoneNumber: json['phone_number'] as String? ?? '',
        displayName: json['display_name'] as String? ?? 'শিক্ষার্থী',
        email: json['email'] as String?,
        profileImageUrl: json['profile_image_url'] as String?,
        preparationCategories:
            (json['preparation_categories'] as List<dynamic>? ?? const [])
                .map((item) => item.toString())
                .toList(),
        notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
        preferredLanguage: json['preferred_language'] as String? ?? 'বাংলা',
      );
}

class ProfileStats {
  const ProfileStats({
    required this.totalExams,
    required this.totalQuestionsRead,
    required this.totalPracticeExams,
    required this.totalLiveExams,
    required this.totalPassedExams,
    required this.failedOrIncompleteExams,
    required this.totalRightAnswers,
    required this.totalWrongAnswers,
    required this.totalSkippedAnswers,
    required this.totalStudyMinutes,
    required this.totalContribution,
    this.overallRank,
  });

  final int totalExams;
  final int totalQuestionsRead;
  final int totalPracticeExams;
  final int totalLiveExams;
  final int totalPassedExams;
  final int failedOrIncompleteExams;
  final int totalRightAnswers;
  final int totalWrongAnswers;
  final int totalSkippedAnswers;
  final int totalStudyMinutes;
  final int totalContribution;
  final int? overallRank;

  factory ProfileStats.fromJson(Map<String, dynamic> json) => ProfileStats(
        totalExams: (json['total_exams'] as num?)?.toInt() ?? 0,
        totalQuestionsRead:
            (json['total_questions_read'] as num?)?.toInt() ?? 0,
        totalPracticeExams: (json['total_practice_exams'] as num?)?.toInt() ?? 0,
        totalLiveExams: (json['total_live_exams'] as num?)?.toInt() ?? 0,
        totalPassedExams: (json['total_passed_exams'] as num?)?.toInt() ?? 0,
        failedOrIncompleteExams:
          (json['failed_or_incomplete_exams'] as num?)?.toInt() ?? 0,
        totalRightAnswers:
          (json['total_right_answers'] as num?)?.toInt() ?? 0,
        totalWrongAnswers:
          (json['total_wrong_answers'] as num?)?.toInt() ?? 0,
        totalSkippedAnswers:
          (json['total_skipped_answers'] as num?)?.toInt() ?? 0,
        totalStudyMinutes:
          (json['total_study_minutes'] as num?)?.toInt() ?? 0,
        totalContribution:
          (json['total_contribution'] as num?)?.toInt() ?? 0,
        overallRank: (json['overall_rank'] as num?)?.toInt(),
      );
}

class RoutinePlan {
  const RoutinePlan({
    required this.id,
    required this.title,
    required this.category,
    required this.subject,
    required this.minutes,
    required this.date,
    required this.note,
    this.done = false,
  });

  final String id;
  final String title;
  final String category;
  final String subject;
  final int minutes;
  final DateTime date;
  final String note;
  final bool done;

  factory RoutinePlan.fromJson(Map<String, dynamic> json) => RoutinePlan(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        subject: json['subject'] as String,
        minutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
        date: DateTime.parse(json['scheduled_date'] as String),
        note: json['note'] as String? ?? '',
        done: json['completed'] as bool? ?? false,
      );
}

class RecentActivity {
  const RecentActivity({
    required this.type,
    required this.activityId,
    required this.relatedId,
    required this.title,
    required this.activityAt,
    this.correctCount,
    this.wrongCount,
    this.totalMarks,
    this.isLive,
    this.questionCount,
  });

  final String type;
  final String activityId;
  final String relatedId;
  final String title;
  final DateTime activityAt;
  final int? correctCount;
  final int? wrongCount;
  final double? totalMarks;
  final bool? isLive;
  final int? questionCount;

  factory RecentActivity.fromJson(Map<String, dynamic> json) => RecentActivity(
        type: json['activity_type'] as String,
        activityId: json['activity_id'] as String,
        relatedId: json['related_id'] as String,
        title: json['title'] as String,
        activityAt: DateTime.parse(json['activity_at'] as String).toLocal(),
        correctCount: (json['correct_count'] as num?)?.toInt(),
        wrongCount: (json['wrong_count'] as num?)?.toInt(),
        totalMarks: (json['total_marks'] as num?)?.toDouble(),
        isLive: json['is_live'] as bool?,
        questionCount: (json['question_count'] as num?)?.toInt(),
      );
}

class TopicNode {
  const TopicNode({
    required this.id,
    required this.name,
    this.parentId,
    this.questionType = 'mcq',
    this.children = const [],
  });

  final String id;
  final String name;
  final String? parentId;
  final String questionType;
  final List<TopicNode> children;

  factory TopicNode.fromJson(Map<String, dynamic> json) {
    return TopicNode(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parent_id'] as String?,
      questionType: json['question_type'] as String? ?? 'mcq',
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

class WrittenQuestion {
  const WrittenQuestion({
    required this.id,
    required this.topicId,
    required this.questionText,
    required this.modelAnswer,
    required this.marks,
    this.format = 'written',
    this.stimulus = '',
    this.setId,
    this.setTitle = '',
    this.itemOrder = 1,
    this.topicName,
    this.examType,
    this.questionSet,
  });

  final String id;
  final String topicId;
  final String questionText;
  final String modelAnswer;
  final double marks;
  final String format;
  final String stimulus;
  final String? setId;
  final String setTitle;
  final int itemOrder;
  final String? topicName;
  final String? examType;
  final String? questionSet;

  factory WrittenQuestion.fromJson(Map<String, dynamic> json) => WrittenQuestion(
        id: json['id'] as String,
        topicId: json['topic_id'] as String,
        questionText: json['question_text'] as String,
        modelAnswer: json['model_answer'] as String? ?? '',
        marks: double.tryParse((json['marks'] ?? 10).toString()) ?? 10,
        format: json['format'] as String? ?? 'written',
        stimulus: json['stimulus'] as String? ?? '',
        setId: json['set_id'] as String?,
        setTitle: json['set_title'] as String? ?? '',
        itemOrder: (json['item_order'] as num?)?.toInt() ?? 1,
        topicName: json['topic_name'] as String?,
        examType: json['exam_type'] as String?,
        questionSet: json['question_set'] as String?,
      );
}

class Exam {
  const Exam({
    required this.id,
    required this.title,
    required this.totalMarks,
    required this.passMark,
    required this.negativeMarking,
    required this.durationMinutes,
    required this.isLive,
    this.topicId,
    this.topicName,
    this.startsAt,
    this.endsAt,
    this.questions = const [],
    this.questionCount,
  });

  final String id;
  final String title;
  final String? topicId;
  final String? topicName;
  final double totalMarks;
  final double passMark;
  final double negativeMarking;
  final int durationMinutes;
  final bool isLive;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final List<Question> questions;
  final int? questionCount;

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] as String,
      title: json['title'] as String,
      topicId: json['topic_id'] as String?,
      topicName: json['topic_name'] as String?,
      startsAt: _parseDate(json['starts_at']),
      endsAt: _parseDate(json['ends_at']),
      totalMarks: double.parse((json['total_marks'] ?? 0).toString()),
      passMark: double.parse((json['pass_mark'] ?? 0).toString()),
      negativeMarking:
          double.parse((json['negative_marking_per_wrong'] ?? 0).toString()),
      durationMinutes: json['duration_minutes'] as int,
      isLive: json['is_live'] as bool? ?? false,
      questions: (json['questions'] as List<dynamic>? ?? const [])
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList(),
        questionCount: (json['question_count'] as num?)?.toInt(),
    );
  }

  Exam copyWith({
    String? id,
    String? title,
    String? topicId,
    String? topicName,
    double? totalMarks,
    double? passMark,
    double? negativeMarking,
    int? durationMinutes,
    bool? isLive,
    DateTime? startsAt,
    DateTime? endsAt,
    List<Question>? questions,
    int? questionCount,
  }) {
    return Exam(
      id: id ?? this.id,
      title: title ?? this.title,
      topicId: topicId ?? this.topicId,
      topicName: topicName ?? this.topicName,
      totalMarks: totalMarks ?? this.totalMarks,
      passMark: passMark ?? this.passMark,
      negativeMarking: negativeMarking ?? this.negativeMarking,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isLive: isLive ?? this.isLive,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      questions: questions ?? this.questions,
      questionCount: questionCount ?? this.questionCount,
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
