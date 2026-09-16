import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../screens/admin_screen.dart';
import '../screens/exam_calendar_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/exam_room_screen.dart';
import '../screens/mobile_dashboard.dart';
import '../screens/result_screen.dart';
import '../screens/subject_practice_screen.dart';
import '../screens/subject_catalog_screen.dart';
import '../screens/app_section_screen.dart';
import '../screens/previous_question_bank_screen.dart';
import '../screens/question_bank_sets_screen.dart';
import '../screens/biddyan_ai_screen.dart';
import '../services/services.dart';

/// Declarative GoRouter configuration.
///
/// Web URLs are deep-linkable: `/`, `/exam/:examId`, `/result/:attemptId`
/// and `/admin`.
final router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (context, state) => const _HomeGate(),
    ),
    GoRoute(
      path: '/exam/:examId',
      builder: (context, state) =>
          _ExamGate(examId: state.pathParameters['examId']!),
    ),
    GoRoute(
      path: '/result/:attemptId',
      builder: (context, state) =>
          ResultScreen(attemptId: state.pathParameters['attemptId']!),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const _AdminGate(),
    ),
    GoRoute(
      path: '/subject-practice',
      builder: (context, state) => SubjectPracticeScreen(
        topicId: state.uri.queryParameters['topicId'],
        topicName: state.uri.queryParameters['topicName'],
        showAll: state.uri.queryParameters['mode'] == 'all',
      ),
    ),
    GoRoute(
      path: '/subject-catalog',
      builder: (context, state) => SubjectCatalogScreen(
        categoryName: state.uri.queryParameters['category'],
      ),
    ),
    GoRoute(
      path: '/previous-question-bank',
      builder: (context, state) => const PreviousQuestionBankScreen(),
    ),
    GoRoute(
      path: '/question-bank',
      builder: (context, state) => QuestionBankSetsScreen(
        category: state.uri.queryParameters['category'] ?? 'Question Bank',
      ),
    ),
    GoRoute(
      path: '/exam-calendar',
      builder: (context, state) => const ExamCalendarScreen(),
    ),
    GoRoute(
      path: '/routine',
      builder: (context, state) => const AppSectionScreen(
        title: 'রুটিন',
        message: 'আপনার পড়াশোনার রুটিন এখানে দেখা যাবে।',
        icon: Icons.edit_calendar,
        selectedIndex: 3,
      ),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const MobileDashboard(initialIndex: 2),
    ),
    GoRoute(
      path: '/account',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/biddyan-ai',
      builder: (context, state) => const BiddyanAiScreen(),
    ),
  ],
);

/// Shows the auth screen until logged in, then the dashboard.
class _HomeGate extends ConsumerWidget {
  const _HomeGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    if (!authState.canEnterApp) {
      return const AuthScreen();
    }
    return const MobileDashboard();
  }
}

class _AdminGate extends ConsumerWidget {
  const _AdminGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    if (authState.user?.role != 'admin') {
      return const AuthScreen();
    }
    return const AdminScreen();
  }
}

/// Loads the exam with [examId] into the session notifier, then renders the
/// live exam room.
class _ExamGate extends ConsumerStatefulWidget {
  const _ExamGate({required this.examId});

  final String examId;

  @override
  ConsumerState<_ExamGate> createState() => _ExamGateState();
}

class _ExamGateState extends ConsumerState<_ExamGate> {
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loadedExamId = ref.read(examSessionNotifierProvider).exam?.id;
    if (_error == null && loadedExamId != widget.examId) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final exam = await ExamService(apiClient).getById(widget.examId);
      ref.read(examSessionNotifierProvider.notifier).start(exam);
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('পরীক্ষা লোড করা যায়নি: $_error')),
      );
    }
    return ExamRoomScreen(examId: widget.examId);
  }
}
