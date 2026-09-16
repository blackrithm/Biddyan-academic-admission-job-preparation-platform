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

class ExamService {
  const ExamService(this.client);

  final ApiClient client;

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
    try {
      final json = await client.post('exams/generate-dynamic', body: {
        'topicId': topicId,
        'questionCount': questionCount,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        'title': title,
      });
      return Exam.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      return MockData.mockExam.copyWith(title: title);
    }
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
