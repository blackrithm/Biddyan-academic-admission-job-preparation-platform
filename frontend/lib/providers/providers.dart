import 'package:flutter_riverpod/legacy.dart';

import '../core/api_client.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Shared singleton [ApiClient] — created once per process and injected into
/// every [StateNotifier] so the auth token stays in sync across screens.
final ApiClient apiClient = ApiClient();

/// ---------------------------------------------------------------------------
/// AUTHENTICATION STATE
/// ---------------------------------------------------------------------------

/// Immutable auth/session state exposed by [AuthNotifier].
class AuthState {
  const AuthState({
    this.user,
    this.isGuest = false,
    this.isLoading = false,
    this.errorMessage,
  });

  final AuthUser? user;
  final bool isGuest;
  final bool isLoading;
  final String? errorMessage;

  bool get canEnterApp => user != null || isGuest;
  bool get isLoggedIn => user != null;

  AuthState copyWith({AuthUser? user, bool? isGuest, bool? isLoading, String? errorMessage}) {
    return AuthState(
      user: user ?? this.user,
      isGuest: isGuest ?? this.isGuest,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Shared auth/session controller. UI calls [loginWithOtp] / [socialLogin] /
/// [logout] through `ref.read(authNotifierProvider.notifier)` and listens to
/// state via `ref.watch(authNotifierProvider)`.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isGuest: true)) {
    continueAsGuest();
  }

  void continueAsGuest() {
    final guestId = 'b1dd1a11-0000-4000-8000-${DateTime.now().microsecondsSinceEpoch.toString().padLeft(12, '0').substring(0, 12)}';
    apiClient.authToken = guestId;
    state = const AuthState(isGuest: true);
  }

  Future<void> register(
    String phoneNumber,
    String password, {
    required String role,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      final user = await AuthService(apiClient).register(
        phoneNumber: phoneNumber,
        password: password,
        role: role,
        guestId: _guestIdFromToken(apiClient.authToken),
      );
      apiClient.authToken = user.token;
      state = AuthState(user: user);
    } catch (error) {
      apiClient.authToken = null;
      state = AuthState(errorMessage: error.toString());
    }
  }

  Future<void> login(
    String phoneNumber,
    String password, {
    required String role,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      final user = await AuthService(apiClient).login(
        phoneNumber: phoneNumber,
        password: password,
        role: role,
      );
      apiClient.authToken = user.token;
      state = AuthState(user: user);
    } catch (error) {
      apiClient.authToken = null;
      state = AuthState(errorMessage: error.toString());
    }
  }

  Future<void> loginWithOtp(String phoneNumber, String otp) async {
    state = const AuthState(isLoading: true);
    try {
      final user = await AuthService(apiClient).verifyOtp(phoneNumber, otp);
      apiClient.authToken = user.token;
      state = AuthState(user: user);
    } catch (error) {
      state = AuthState(errorMessage: error.toString());
    }
  }

  Future<void> requestOtp(String phoneNumber) async {
    await AuthService(apiClient).requestOtp(phoneNumber);
  }

  Future<void> socialLogin(String provider) async {
    state = const AuthState(isLoading: true);
    try {
      final user = AuthUser(
        token: 'mock-social-token',
        userId: 'b1dd1a11-0000-4000-8000-000000000101',
        phoneNumber: '',
        displayName: '$provider User',
        email: 'user@biddyan.id',
      );
      apiClient.authToken = user.token;
      state = AuthState(user: user);
    } catch (error) {
      state = AuthState(errorMessage: error.toString());
    }
  }

  void logout() {
    apiClient.authToken = null;
    state = const AuthState();
  }

  String? _guestIdFromToken(String? token) {
    if (token == null || token.contains('.')) return null;
    return token;
  }
}

/// Riverpod provider exposing [AuthNotifier] and its [AuthState] to consumers.
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((_) => AuthNotifier());
/// ---------------------------------------------------------------------------
/// EXAM SESSION STATE
/// ---------------------------------------------------------------------------

/// Immutable live-exam session state.
class ExamSessionState {
  const ExamSessionState({
    this.exam,
    this.selectedAnswers = const {},
    this.secondsLeft = 0,
    this.isSubmitting = false,
    this.errorMessage,
    this.lastResult,
  });

  final Exam? exam;
  final Map<String, String> selectedAnswers;
  final int secondsLeft;
  final bool isSubmitting;
  final String? errorMessage;
  final AttemptResult? lastResult;

  bool get isLoaded => exam != null;
  int get answeredCount => selectedAnswers.length;

  List<AnswerBreakdown> get breakdown => lastResult?.breakdown ?? const [];

  ExamSessionState copyWith({
    Exam? exam,
    Map<String, String>? selectedAnswers,
    int? secondsLeft,
    bool? isSubmitting,
    String? errorMessage,
    AttemptResult? lastResult,
  }) {
    return ExamSessionState(
      exam: exam ?? this.exam,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

/// Controller for a running exam: holds the fetched [Exam], tracks answer
/// selections, ticks the countdown and submits results.
class ExamSessionNotifier extends StateNotifier<ExamSessionState> {
  ExamSessionNotifier() : super(const ExamSessionState());

  void start(Exam exam) {
    state = ExamSessionState(
      exam: exam,
      secondsLeft: exam.durationMinutes * 60,
    );
  }

  void selectAnswer(String questionId, String optionKey) {
    state = state.copyWith(
      selectedAnswers: {
        ...state.selectedAnswers,
        questionId: optionKey,
      },
    );
  }

  void tick() {
    final next = (state.secondsLeft - 1).clamp(0, state.secondsLeft);
    state = state.copyWith(secondsLeft: next);
  }

  Future<AttemptResult> submit() async {
    final exam = state.exam;
    if (exam == null) {
      throw StateError('Exam not started');
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final answers = state.selectedAnswers.entries
          .map((entry) => AnswerSubmission(
                questionId: entry.key,
                selectedOption: entry.value,
              ))
          .toList();

      final result = await ExamService(apiClient).submit(
        examId: exam.id,
        userId: apiClient.authToken ?? 'mock-user',
        answers: answers,
        negativeMarking: exam.negativeMarking,
      );
      state = state.copyWith(isSubmitting: false, lastResult: result);
      return result;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.toString(),
      );
      rethrow;
    }
  }
}

final examSessionNotifierProvider =
    StateNotifierProvider<ExamSessionNotifier, ExamSessionState>(
      (_) => ExamSessionNotifier(),
    );

/// ---------------------------------------------------------------------------
/// LEADERBOARD STATE
/// ---------------------------------------------------------------------------

/// Immutable leaderboard payload.
class LeaderboardState {
  const LeaderboardState({this.entries = const [], this.totalExaminees = 0});

  final List<LeaderboardEntry> entries;
  final int totalExaminees;
}

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  LeaderboardNotifier() : super(const LeaderboardState());

  Future<void> load(String examId) async {
    final (totalExaminees, rows) =
        await ExamService(apiClient).leaderboard(examId);
    state = LeaderboardState(entries: rows, totalExaminees: totalExaminees);
  }
}

final leaderboardNotifierProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>(
      (_) => LeaderboardNotifier(),
    );