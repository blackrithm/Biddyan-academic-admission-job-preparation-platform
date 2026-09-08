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

  Future<List<Question>> list({String? topicId, String? search}) async {
    try {
      final json = await client.get(
        'questions',
        query: {
          if (topicId != null) 'topicId': topicId,
          if (search != null) 'search': search,
        },
      );
      return (json as List<dynamic>)
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return MockData.questions;
    }
  }

  Future<Question> create(Map<String, dynamic> body) async {
    final json = await client.post('questions', body: body);
    return Question.fromJson(json as Map<String, dynamic>);
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
      final exam = Map<String, dynamic>.from(
        payload['exam'] as Map<String, dynamic>,
      );
      exam['questions'] = payload['questions'] ?? const [];
      return Exam.fromJson(exam);
    } catch (_) {
      return MockData.mockExam.copyWith(id: id);
    }
  }

  Future<Exam> generateDynamic({
    required String topicId,
    int questionCount = 10,
    String title = 'Instant Practice Exam',
  }) async {
    try {
      final json = await client.post('exams/generate-dynamic', body: {
        'topicId': topicId,
        'questionCount': questionCount,
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
        final question = MockData.questions
            .firstWhere((q) => q.id == answer.questionId, orElse: () => MockData.questions.first);
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
      final score = (correct * 1.0) - (wrong * 0.25);
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
