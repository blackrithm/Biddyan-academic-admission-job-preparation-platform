import '../core/api_client.dart';
import '../models/models.dart';
import 'mock_data.dart';

/// Typed API service layer for Biddyan.
///
/// Every method maps 1:1 to a backend REST route exposed by the Express API
/// (`backend/src/routes/api.ts` + `backend/src/controllers/*`).
class AuthService {
  const AuthService(this.client);

  final ApiClient client;
  static const mockOtp = '123456';

  Future<AuthUser> register({
    required String phoneNumber,
    required String password,
    required String role,
    String? guestId,
  }) async {
    final json = await client.post('auth/register', body: {
      'phoneNumber': phoneNumber,
      'password': password,
      'role': role,
      if (guestId != null) 'guestId': guestId,
    });
    return AuthUser.fromJson(json as Map<String, dynamic>);
  }

  Future<AuthUser> login({
    required String phoneNumber,
    required String password,
    required String role,
  }) async {
    final json = await client.post('auth/login', body: {
      'phoneNumber': phoneNumber,
      'password': password,
      'role': role,
    });
    return AuthUser.fromJson(json as Map<String, dynamic>);
  }

  /// POST /api/v1/auth/otp-request
  Future<void> requestOtp(String phoneNumber) async {
    try {
      await client.post('auth/otp-request', body: {
        'phoneNumber': phoneNumber,
      });
    } on ApiException {
      // Keep the local demo usable when the optional backend is offline.
    }
  }

  /// POST /api/v1/auth/otp-verify
  Future<AuthUser> verifyOtp(String phoneNumber, String otp) async {
    try {
      final json = await client.post('auth/otp-verify', body: {
        'phoneNumber': phoneNumber,
        'otp': otp,
      });
      return AuthUser.fromJson(json as Map<String, dynamic>);
    } on ApiException {
      if (otp != mockOtp) {
        throw ApiException('ডেমো মোডে OTP হিসেবে 123456 ব্যবহার করুন');
      }
      return AuthUser(
        token: 'mock-otp-token',
        userId: 'b1dd1a11-0000-4000-8000-000000000001',
        phoneNumber: phoneNumber,
        displayName: 'Biddyan User',
      );
    }
  }
}

class ProfileService {
  const ProfileService(this.client);

  final ApiClient client;

  Future<ProfileStats> getStats() async {
    final json = await client.get('profile/stats');
    return ProfileStats.fromJson(json as Map<String, dynamic>);
  }

  Future<List<RecentActivity>> getRecentActivity() async {
    final json = await client.get('profile/recent-activity');
    return (json as List<dynamic>)
        .map((item) => RecentActivity.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<UserProfile> get() async {
    final json = await client.get('profile');
    return UserProfile.fromJson(json as Map<String, dynamic>);
  }

  Future<UserProfile> update({
    String? displayName,
    String? profileImageUrl,
    List<String>? preparationCategories,
    bool? notificationsEnabled,
    String? preferredLanguage,
  }) async {
    final json = await client.put('profile', body: {
      if (displayName != null) 'displayName': displayName,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (preparationCategories != null)
        'preparationCategories': preparationCategories,
      if (notificationsEnabled != null)
        'notificationsEnabled': notificationsEnabled,
      if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
    });
    return UserProfile.fromJson(json as Map<String, dynamic>);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await client.put('profile/password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}

class RoutineService {
  const RoutineService(this.client);

  final ApiClient client;

  Future<List<RoutinePlan>> list() async {
    final json = await client.get('routine');
    return (json as List<dynamic>)
        .map((item) => RoutinePlan.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<RoutinePlan> create({
    required String title,
    required String category,
    required String subject,
    required int minutes,
    required DateTime date,
    required String note,
  }) async {
    final json = await client.post('routine', body: {
      'title': title,
      'category': category,
      'subject': subject,
      'durationMinutes': minutes,
      'scheduledDate': _dateOnly(date),
      'note': note,
    });
    return RoutinePlan.fromJson(json as Map<String, dynamic>);
  }

  Future<RoutinePlan> update(String id, Map<String, dynamic> values) async {
    final json = await client.put('routine/$id', body: values);
    return RoutinePlan.fromJson(json as Map<String, dynamic>);
  }

  Future<void> remove(String id) => client.delete('routine/$id');

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class TopicService {
  const TopicService(this.client);

  final ApiClient client;

  Future<List<TopicNode>> getTree() async {
    try {
      final json = await client.get('topics/tree');
      return (json as List<dynamic>)
          .map((e) => TopicNode.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return MockData.topicTree;
    }
  }

  Future<TopicNode> create(Map<String, dynamic> body) async {
    final json = await client.post('topics', body: body);
    return TopicNode.fromJson(json as Map<String, dynamic>);
  }

  Future<void> update(String id, Map<String, dynamic> body) async {
    await client.put('topics/$id', body: body);
  }

  Future<void> reorder({
    required String? parentId,
    required List<String> topicIds,
  }) async {
    await client.put('topics/reorder', body: {
      'parentId': parentId,
      'topicIds': topicIds,
    });
  }

  Future<void> move(String id, String? parentId) async {
    await client.put('topics/$id/move', body: {'parentId': parentId});
  }

  Future<Map<String, dynamic>> copySubtopics({
    required String sourceTopicId,
    required String? targetParentId,
    required List<String> childIds,
    required bool copyQuestions,
  }) async {
    final json = await client.post('topics/$sourceTopicId/copy-subtopics', body: {
      'targetParentId': targetParentId,
      'childIds': childIds,
      'copyQuestions': copyQuestions,
    });
    return Map<String, dynamic>.from(json as Map);
  }

  Future<void> delete(String id) async {
    await client.delete('topics/$id');
  }
}

class QuestionService {
  const QuestionService(this.client);

  final ApiClient client;

  Future<List<Question>> list({
    String? topicId,
    String? search,
    String? previousYear,
    String? examType,
    String? questionSet,
  }) async {
    try {
      final json = await client.get(
        'questions',
        query: {
          if (topicId != null) 'topicId': topicId,
          if (search != null) 'search': search,
          if (previousYear != null) 'previousYear': previousYear,
          if (examType != null) 'examType': examType,
          if (questionSet != null) 'questionSet': questionSet,
        },
      );
      return (json as List<dynamic>)
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return MockData.questions.where((question) {
        final matchesTopic = topicId == null || question.topicId == topicId;
        final matchesSearch = search == null ||
            question.questionText.toLowerCase().contains(search.toLowerCase());
        final matchesYear = previousYear == null ||
            question.previousYears.contains(previousYear);
        final matchesExamType = examType == null || question.examType == examType;
        final matchesSet = questionSet == null || question.questionSet == questionSet;
        return matchesTopic &&
            matchesSearch &&
            matchesYear &&
            matchesExamType &&
            matchesSet;
      }).toList();
    }
  }

  Future<Question> create(Map<String, dynamic> body) async {
    final json = await client.post('questions', body: body);
    return Question.fromJson(json as Map<String, dynamic>);
  }

  Future<int> bulkCreate({
    required String topicId,
    required List<Map<String, dynamic>> questions,
    Map<String, dynamic> defaults = const {},
  }) async {
    final inserted = await bulkCreateWithQuestions(
      topicId: topicId,
      questions: questions,
      defaults: defaults,
    );
    return inserted.length;
  }

  Future<List<Question>> bulkCreateWithQuestions({
    required String topicId,
    required List<Map<String, dynamic>> questions,
    Map<String, dynamic> defaults = const {},
  }) async {
    final json = await client.post('questions/bulk', body: {
      'topic_id': topicId,
      'questions': questions,
      'defaults': defaults,
    }) as Map<String, dynamic>;
    return (json['questions'] as List<dynamic>? ?? const [])
        .map((item) => Question.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Question> update(String id, Map<String, dynamic> body) async {
    final json = await client.put('questions/$id', body: body);
    return Question.fromJson(json as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await client.delete('questions/$id');
  }
}

class WrittenQuestionService {
  const WrittenQuestionService(this.client);

  final ApiClient client;

  Future<List<WrittenQuestion>> list({
    String? topicId,
    String? setId,
    bool includeChildren = false,
  }) async {
    final json = await client.get('written-questions', query: {
      if (topicId != null) 'topicId': topicId,
      if (setId != null) 'setId': setId,
      if (includeChildren) 'includeChildren': 'true',
    });
    return (json as List<dynamic>)
        .map((item) => WrittenQuestion.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<WrittenQuestion> create(Map<String, dynamic> body) async {
    final json = await client.post('written-questions', body: body);
    return WrittenQuestion.fromJson(Map<String, dynamic>.from(json as Map));
  }

  Future<Map<String, dynamic>> createSet({
    required String topicId,
    required String format,
    required List<Map<String, dynamic>> questions,
    String title = '',
    String stimulus = '',
    String? examType,
    String? questionSet,
    List<String> previousYears = const [],
    String difficultyLevel = 'medium',
    String source = 'admin',
  }) async {
    final json = await client.post('written-question-sets', body: {
      'topic_id': topicId,
      'format': format,
      'title': title,
      'stimulus': stimulus,
      'exam_type': examType,
      'question_set': questionSet,
      'previous_years': previousYears,
      'difficulty_level': difficultyLevel,
      'source': source,
      'questions': questions,
    });
    return Map<String, dynamic>.from(json as Map);
  }

  Future<Map<String, dynamic>> submit({
    required String topicId,
    required String userId,
    required List<Map<String, String>> answers,
  }) async {
    final json = await client.post('written-exams/$topicId/submit', body: {
      'userId': userId,
      'answers': answers,
    });
    return Map<String, dynamic>.from(json as Map);
  }
}

class ExamService {
  const ExamService(this.client);

  final ApiClient client;

  Future<List<Map<String, dynamic>>> adminResults({String? examId}) async {
    final json = await client.get('admin/exam-results', query: {
      if (examId != null) 'examId': examId,
    });
    return (json as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> updateAdminResult({
    required String attemptId,
    required double score,
    required int correctCount,
    required int wrongCount,
  }) async {
    await client.put('admin/exam-results/$attemptId', body: {
      'score': score,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
    });
  }

  Future<Exam> create(Map<String, dynamic> body) async {
    final json = await client.post('exams', body: body);
    return Exam.fromJson(json as Map<String, dynamic>);
  }

  Future<Exam> createFromQuestionSet({
    required String title,
    required List<String> questionIds,
    String? topicId,
    double totalMarks = 0,
    double passMark = 0,
    double negativeMarking = 0.25,
    int duration = 60,
  }) async {
    final json = await client.post('exams/from-question-set', body: {
      'title': title,
      'topicId': topicId,
      'totalMarks': totalMarks > 0 ? totalMarks : questionIds.length,
        'passMark': passMark > 0
          ? passMark
          : (totalMarks > 0 ? totalMarks : questionIds.length) * 0.4,
      'negativeMarking': negativeMarking,
      'duration': duration,
      'isLive': false,
      'questionIds': questionIds,
    });
    return Exam.fromJson(json as Map<String, dynamic>);
  }

  Future<List<Exam>> list() async {
    try {
      final json = await client.get('exams');
      return (json as List<dynamic>)
          .map((e) => Exam.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return MockData.exams;
    }
  }

  Future<List<Map<String, dynamic>>> batchList() async {
    final json = await client.get('exam-batches');
    return (json as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> myBatches() async {
    final json = await client.get('exam-batches/mine');
    return (json as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> batchDetails(String batchId) async {
    final json = await client.get('exam-batches/$batchId');
    return Map<String, dynamic>.from(json as Map);
  }

  Future<void> enrollInBatch(String batchId) async {
    await client.post('exam-batches/$batchId/enroll');
  }

  Future<void> createBatch({
    required String name,
    required String examType,
    required String description,
    String? imageUrl,
    required List<Map<String, String>> exams,
  }) async {
    await client.post('exam-batches', body: {
      'name': name,
      'examType': examType,
      'description': description,
      'imageUrl': imageUrl,
      'exams': exams,
    });
  }

  Future<void> updateBatch({
    required String batchId,
    required String name,
    required String examType,
    required String description,
    String? imageUrl,
    required List<Map<String, String>> exams,
  }) async {
    await client.put('exam-batches/$batchId', body: {
      'name': name,
      'examType': examType,
      'description': description,
      'imageUrl': imageUrl,
      'exams': exams,
    });
  }

  Future<void> reorderBatches(List<String> batchIds) async {
    await client.put('exam-batches/reorder', body: {'batchIds': batchIds});
  }

  Future<List<Exam>> myCreatedExams() async {
    final json = await client.get('exams/mine');
    return (json as List<dynamic>)
        .map((item) => Exam.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Exam> getById(String id) async {
    try {
      final json = await client.get('exams/$id');
      final payload = json as Map<String, dynamic>;
      final exam = payload['exam'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(payload['exam'] as Map<String, dynamic>)
          : Map<String, dynamic>.from(payload);
      exam['questions'] = payload['questions'] ?? const [];
      return Exam.fromJson(exam);
    } catch (error) {
      throw ApiException('Exam লোড করা যায়নি: $error');
    }
  }

  Future<Exam> generateDynamic({
    required String topicId,
    int questionCount = 10,
    int? durationMinutes,
    String title = 'Instant Practice Exam',
  }) async {
    final json = await client.post('exams/generate-dynamic', body: {
        'topicId': topicId,
        'questionCount': questionCount,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        'title': title,
      });
    final payload = json as Map<String, dynamic>;
    final exam = payload['exam'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(payload['exam'] as Map<String, dynamic>)
        : Map<String, dynamic>.from(payload);
    exam['questions'] = payload['questions'] ?? const [];
    return Exam.fromJson(exam);
  }

  Future<Exam> generateDynamicMulti({
    required List<Map<String, dynamic>> topicQuestions,
    required double perQuestionMark,
    required double? passMark,
    required double negativeMarking,
    required int durationMinutes,
    required String title,
  }) async {
    final json = await client.post('exams/generate-dynamic', body: {
      'topicQuestions': topicQuestions,
      'perQuestionMark': perQuestionMark,
      'passMark': passMark,
      'negativeMarking': negativeMarking,
      'durationMinutes': durationMinutes,
      'title': title,
    });
    final payload = json as Map<String, dynamic>;
    final exam = Map<String, dynamic>.from(payload['exam'] as Map);
    exam['questions'] = payload['questions'] ?? const [];
    return Exam.fromJson(exam);
  }

  Future<List<Map<String, dynamic>>> participants(String examId) async {
    final json = await client.get('exams/$examId/participants');
    return (json as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<AttemptResult> submit({
    required String examId,
    required String userId,
    required List<AnswerSubmission> answers,
    double negativeMarking = 0.25,
  }) async {
    try {
      final json = await client.post('exams/$examId/submit', body: {
        'userId': userId,
        'answers': answers.map((a) => a.toJson()).toList(),
      });
      return AttemptResult.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      if (examId != 'mock-exam-id' && !examId.startsWith('mock-')) rethrow;
      int correct = 0;
      int wrong = 0;
      final breakdown = <AnswerBreakdown>[];
      for (final answer in answers) {
        final question = MockData.questions.firstWhere(
            (q) => q.id == answer.questionId,
            orElse: () => MockData.questions.first);
        final isCorrect = question.correctOption == answer.selectedOption;
        if (isCorrect) {
          correct++;
        } else {
          wrong++;
        }
        breakdown.add(
          AnswerBreakdown(
            questionId: answer.questionId,
            selectedOption: answer.selectedOption,
            isCorrect: isCorrect,
            explanation: question.explanation ?? '',
          ),
        );
      }
      final score = (correct * 1.0) - (wrong * negativeMarking);
      return AttemptResult(
        attemptId: 'mock-${DateTime.now().millisecondsSinceEpoch}',
        score: score,
        correctCount: correct,
        wrongCount: wrong,
        rank: 1,
        totalExaminees: 42,
        breakdown: breakdown,
      );
    }
  }

  Future<(int, List<LeaderboardEntry>)> leaderboard(String examId) async {
    try {
      final json = await client.get('exams/$examId/leaderboard');
      final map = json as Map<String, dynamic>;
      final totalExaminees = map['totalExaminees'] as int? ?? 0;
      final rows = (map['leaderboard'] as List<dynamic>? ?? const [])
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      return (totalExaminees, rows);
    } catch (_) {
      return (42, MockData.leaderboard);
    }
  }
}
