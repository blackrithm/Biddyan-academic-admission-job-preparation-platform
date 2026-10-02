import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'api_client.dart';
import '../providers/providers.dart';
import '../screens/admin_screen.dart';
import '../screens/admin_management_pages.dart';
import '../screens/exam_calendar_screen.dart';
import '../screens/exam_batches_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/exam_room_screen.dart';
import '../screens/exam_read_mode_screen.dart';
import '../screens/exam_participants_screen.dart';
import '../screens/mobile_dashboard.dart';
import '../screens/result_screen.dart';
import '../screens/subject_practice_screen.dart';
import '../screens/written_practice_screen.dart';
import '../screens/subject_catalog_screen.dart';
import '../screens/previous_question_bank_screen.dart';
import '../screens/question_bank_sets_screen.dart';
import '../screens/biddyan_ai_screen.dart';
import '../screens/books_screen.dart';
import '../screens/routine_screen.dart';
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
      builder: (context, state) => _HomeGate(
        showNotices: state.uri.queryParameters['notice'] == '1',
      ),
    ),
    GoRoute(
      path: '/exam/:examId',
      builder: (context, state) =>
          _ExamGate(examId: state.pathParameters['examId']!),
    ),
    GoRoute(
      path: '/exam/:examId/read',
      builder: (context, state) => ExamReadModeScreen(
        examId: state.pathParameters['examId']!,
      ),
    ),
    GoRoute(
      path: '/result/:attemptId',
      builder: (context, state) =>
          ResultScreen(attemptId: state.pathParameters['attemptId']!),
    ),
    GoRoute(
      path: '/exam/:examId/participants',
      builder: (context, state) => ExamParticipantsScreen(
        examId: state.pathParameters['examId']!,
      ),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const _AdminGate(),
    ),
    GoRoute(
      path: '/admin/exams',
      builder: (context, state) => const _AdminSectionGate(child: AdminExamManagementPage()),
    ),
    GoRoute(
      path: '/admin/exam-batches',
      builder: (context, state) => const _AdminSectionGate(child: AdminExamBatchesScreen()),
    ),
    GoRoute(
      path: '/admin/media',
      builder: (context, state) => const _AdminSectionGate(child: AdminMediaPage()),
    ),
    GoRoute(
      path: '/admin/mcqs',
      builder: (context, state) => const _AdminSectionGate(child: AdminMcqPage()),
    ),
    GoRoute(
      path: '/admin/notifications',
      builder: (context, state) => const _AdminSectionGate(child: AdminNotificationsPage()),
    ),
    GoRoute(
      path: '/admin/materials',
      builder: (context, state) => const _AdminSectionGate(child: AdminMaterialsPage()),
    ),
    GoRoute(
      path: '/admin/question-bank',
      builder: (context, state) => const _AdminSectionGate(child: AdminQuestionBankPage()),
    ),
    GoRoute(
      path: '/admin/results',
      builder: (context, state) => const _AdminSectionGate(child: AdminResultsPage()),
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
      path: '/written-practice',
      builder: (context, state) => WrittenPracticeScreen(
        topicId: state.uri.queryParameters['topicId'] ?? '',
        topicName: state.uri.queryParameters['topicName'] ?? 'Written প্রশ্ন',
        setId: state.uri.queryParameters['setId'],
        startInExamMode: state.uri.queryParameters['mode'] == 'exam',
      ),
    ),
    GoRoute(
      path: '/subject-catalog',
      builder: (context, state) => SubjectCatalogScreen(
        categoryName: state.uri.queryParameters['category'],
        createExam: state.uri.queryParameters['create'] == '1',
      ),
    ),
    GoRoute(
      path: '/preparation',
      builder: (context, state) => const PreparationScreen(),
    ),
    GoRoute(
      path: '/books',
      builder: (context, state) => const BooksScreen(),
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
      path: '/exam-batches',
      builder: (context, state) => const ExamBatchesScreen(),
    ),
    GoRoute(
      path: '/exam-batches/:batchId',
      builder: (context, state) => ExamBatchDetailScreen(
        batchId: state.pathParameters['batchId']!,
        autoEnroll: state.uri.queryParameters['enroll'] == '1',
      ),
    ),
    GoRoute(
      path: '/routine',
      builder: (context, state) => const RoutineScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const MobileDashboard(initialIndex: 2),
    ),
    GoRoute(
      path: '/account',
      builder: (context, state) => AuthScreen(redirectTo: state.uri.queryParameters['redirect']),
    ),
    GoRoute(
      path: '/biddyan-ai',
      builder: (context, state) => const BiddyanAiScreen(),
    ),
  ],
);

/// Shows the auth screen until logged in, then the dashboard.
class _HomeGate extends ConsumerWidget {
  const _HomeGate({this.showNotices = false});

  final bool showNotices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    if (!authState.canEnterApp) {
      return const AuthScreen();
    }
    return MobileDashboard(initialIndex: showNotices ? 1 : 0);
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

class _AdminSectionGate extends ConsumerWidget {
  const _AdminSectionGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    if (authState.user?.role != 'admin') {
      return const AuthScreen();
    }
    return child;
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
      final service = ExamService(apiClient);
      var examId = widget.examId;
      // Older offline links used a non-database placeholder ID. Resolve those
      // links to a real exam before querying PostgreSQL.
      if (examId == 'mock-exam-id') {
        final exams = await service.list();
        if (exams.isEmpty) {
          throw ApiException('কোনো পরীক্ষা পাওয়া যায়নি');
        }
        examId = exams.first.id;
      }
      final exam = await service.getById(examId);
      if (!mounted) return;
      final shouldStart = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(exam.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.assignment_rounded, size: 48, color: Color(0xFF00343A)),
              const SizedBox(height: 12),
              _ExamDetailRow(label: 'প্রশ্ন', value: '${exam.questions.length}টি'),
              _ExamDetailRow(label: 'মোট নম্বর', value: exam.totalMarks.toStringAsFixed(0)),
              _ExamDetailRow(label: 'সময়', value: '${exam.durationMinutes} মিনিট'),
              if (exam.negativeMarking > 0)
                _ExamDetailRow(
                  label: 'নেগেটিভ মার্কিং',
                  value: '${_formatExamNumber(exam.negativeMarking)} নম্বর',
                ),
              const SizedBox(height: 10),
              const Text(
                'পরীক্ষা শুরু করলে সময় গণনা শুরু হবে। সঠিক উত্তর পরীক্ষা চলাকালীন দেখানো হবে না।',
                style: TextStyle(color: Color(0xFF687477)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('বাতিল'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.play_arrow),
              label: const Text('পরীক্ষা শুরু করুন'),
            ),
          ],
        ),
      );
      if (shouldStart != true) {
        if (mounted) context.pop();
        return;
      }
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

class _ExamDetailRow extends StatelessWidget {
  const _ExamDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF687477))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

String _formatExamNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
