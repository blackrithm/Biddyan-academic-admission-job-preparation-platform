import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../providers/providers.dart';
import '../widgets/brand_navigation.dart';
import 'mobile_dashboard.dart';
import 'exam_room_widgets.dart';

/// Live Exam Room.
///
/// Sticky top AppBar with a real-time HH:MM:SS countdown chip, question
/// counter and submit action; red negative-marking warning banner; current
/// question with Bengali option cards (ক, খ, গ, ঘ); question palette rail.
class ExamRoomScreen extends ConsumerStatefulWidget {
  const ExamRoomScreen({super.key, required this.examId});

  /// The exam id captured from the `:examId` path parameter.
  final String examId;

  @override
  ConsumerState<ExamRoomScreen> createState() => _ExamRoomScreenState();
}

class _ExamRoomScreenState extends ConsumerState<ExamRoomScreen> {
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(examSessionNotifierProvider);
    final notifier = ref.read(examSessionNotifierProvider.notifier);
    final compactAppBar = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      drawer: const DashboardDrawer(),
      appBar: BrandHeader(
        showNotifications: false,
        extraActions: [
          if (session.exam != null) ...[
            if (compactAppBar)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _MobileCountdown(seconds: session.secondsLeft),
              )
            else
              Chip(
                avatar: _CountdownClock(seconds: session.secondsLeft),
                label: Text(_formatHms(session.secondsLeft)),
              ),
            IconButton(
              tooltip: 'সাবমিট',
              icon: const Icon(Icons.task_alt),
              onPressed: () => _submit(notifier),
            ),
          ],
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (session.exam == null)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: _ExamBody(
                session: session,
                notifier: notifier,
                onSubmit: () => _submit(notifier),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BrandBottomNavigation(
        selectedIndex: 2,
        onSelected: (index) => BrandBottomNavigation.navigate(context, index),
      ),
    );
  }

  Future<void> _submit(ExamSessionNotifier notifier) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('আপনার উত্তর সাবমিট হচ্ছে...')),
    );
    final result = await notifier.submit();
    if (!mounted) return;
    context.go('/result/${result.attemptId}');
  }
}

String _formatHms(int totalSeconds) {
  final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
  final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
  final s = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

class _CountdownClock extends StatelessWidget {
  const _CountdownClock({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final danger = seconds <= 60;
    return Icon(
      Icons.timer,
      size: 18,
      color: danger ? const Color(0xFFD32F2F) : AppConstants.primary,
    );
  }
}

class _MobileCountdown extends StatelessWidget {
  const _MobileCountdown({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final danger = seconds <= 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: danger ? const Color(0xFFFFEBEE) : const Color(0xFFE8F3F1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: danger ? const Color(0xFFD32F2F) : AppConstants.primary),
          const SizedBox(width: 5),
          Text(
            _formatHms(seconds),
            style: TextStyle(
              color: danger ? const Color(0xFFD32F2F) : AppConstants.primary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _NegativeMarkingBanner extends StatelessWidget {
  const _NegativeMarkingBanner({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: const BoxDecoration(color: Color(0xFFFFEBEE)),
      child: Row(
        children: [
          const Icon(Icons.priority_high, color: Color(0xFFD32F2F), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'সতর্কতা: প্রতিটি ভুল উত্তরের জন্য ${_formatNegativeMark(value)} নম্বর কাটা যাবে',
              style: const TextStyle(
                color: Color(0xFFD32F2F),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatNegativeMark(double value) =>
    value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');

class _ExamBody extends ConsumerStatefulWidget {
  const _ExamBody({
    required this.session,
    required this.notifier,
    required this.onSubmit,
  });

  final ExamSessionState session;
  final ExamSessionNotifier notifier;
  final VoidCallback onSubmit;

  @override
  ConsumerState<_ExamBody> createState() => _ExamBodyState();
}

class _ExamBodyState extends ConsumerState<_ExamBody> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.session.secondsLeft <= 0) {
        _ticker?.cancel();
        _ticker = null;
        return;
      }
      widget.notifier.tick();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.session.exam!;
    final questions = exam.questions;
    final hasWarning = exam.negativeMarking > 0;
    final submitIndex = questions.length + (hasWarning ? 1 : 0);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: submitIndex + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == submitIndex) {
          return FilledButton.icon(
            onPressed: widget.onSubmit,
            icon: const Icon(Icons.task_alt),
            label: const Text('পরীক্ষা জমা দিন'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          );
        }
        if (hasWarning && index == 0) {
          return _NegativeMarkingBanner(value: exam.negativeMarking);
        }
        final questionIndex = hasWarning ? index - 1 : index;
        final question = questions[questionIndex];
        return QuestionCard(
          index: questionIndex,
          question: question,
          selectedOption: widget.session.selectedAnswers[question.id],
          onSelect: (option) =>
              widget.notifier.selectAnswer(question.id, option),
        );
      },
    );
  }
}
