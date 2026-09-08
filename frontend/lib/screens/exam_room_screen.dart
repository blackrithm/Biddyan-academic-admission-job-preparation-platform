import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../providers/providers.dart';
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
      appBar: AppBar(
        title: Text(
          session.exam?.title ?? 'লাইভ পরীক্ষা',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (session.exam != null) ...[
            if (compactAppBar)
              IconButton(
                tooltip: 'সময় ${_formatHms(session.secondsLeft)}',
                icon: _CountdownClock(seconds: session.secondsLeft),
                onPressed: null,
              )
            else
              Chip(
                avatar: _CountdownClock(seconds: session.secondsLeft),
                label: Text(_formatHms(session.secondsLeft)),
              ),
            IconButton(
              tooltip: 'সাবমিট',
              icon: const Icon(Icons.send),
              onPressed: () => _submit(notifier),
            ),
          ],
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _NegativeMarkingBanner(),
          if (session.exam == null)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: _ExamBody(session: session, notifier: notifier),
            ),
        ],
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

class _NegativeMarkingBanner extends StatelessWidget {
  const _NegativeMarkingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: const BoxDecoration(color: Color(0xFFFFEBEE)),
      child: Row(
        children: const [
          Icon(Icons.priority_high, color: Color(0xFFD32F2F), size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'সতর্কতা: প্রতিটি ভুল উত্তরের জন্য ০.২৫ নম্বর কাটা যাবে',
              style: TextStyle(
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

class _ExamBody extends ConsumerStatefulWidget {
  const _ExamBody({required this.session, required this.notifier});

  final ExamSessionState session;
  final ExamSessionNotifier notifier;

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
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final question = questions[index];
        return QuestionCard(
          index: index,
          question: question,
          selectedOption: widget.session.selectedAnswers[question.id],
          onSelect: (option) =>
              widget.notifier.selectAnswer(question.id, option),
        );
      },
    );
  }
}