import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/brand_navigation.dart';

/// Result & Analytics Sheet.
///
/// Renders summary cards (Total examinees, pass count, cut mark, user score,
/// rank) plus a detailed subject-wise breakdown table with Correct / Wrong /
/// Marks columns for every answered question.
class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.attemptId});

  /// The attempt id captured from the `:attemptId` path parameter.
  final String attemptId;

  static const int passMark = 40;
  static const int cutMark = 25;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(examSessionNotifierProvider);

    final exam = session.exam;
    final result = session.lastResult;
    final breakdown = session.breakdown;

    return Scaffold(
      appBar: AppBar(title: const Text('রেজাল্ট অ্যানালাইসিস')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const _ScoreHero(),
              const SizedBox(height: 20),
              _SummaryGrid(
                totalExaminees: result?.totalExaminees ?? 1530,
                passCount: 642,
                cutMark: cutMark,
                totalQuestions: exam?.questions.length ?? 0,
                correctCount: result?.correctCount ?? 0,
                wrongCount: result?.wrongCount ?? 0,
                userScore: result?.score ?? 0,
                rank: result?.rank,
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'বিষয়ভিত্তিক বিশ্লেষণ (Correct / Wrong / Marks)',
                child: _BreakdownTable(
                  breakdown: breakdown,
                  exam: exam,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BrandBottomNavigation(
        selectedIndex: 2,
        onSelected: (_) {},
      ),
    );
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero();

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      color: const Color(0xFFEAF4EC),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'অভিনন্দন! আপনার পরীক্ষা সম্পন্ন হয়েছে',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'বিস্তারিত ফলাফল নিচে দেওয়া হলো',
              style: TextStyle(color: AppConstants.mutedText, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.totalExaminees,
    required this.passCount,
    required this.cutMark,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.userScore,
    required this.rank,
  });

  final int totalExaminees;
  final int passCount;
  final int cutMark;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final double userScore;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final unanswered =
        (totalQuestions - correctCount - wrongCount).clamp(0, totalQuestions);
    final stats = [
      (
        label: 'মোট পরীক্ষার্থী',
        value: '$totalExaminees',
        icon: Icons.people,
        emphasized: false
      ),
      (
        label: 'পাশের সংখ্যা',
        value: '$passCount',
        icon: Icons.how_to_reg,
        emphasized: false
      ),
      (
        label: 'কাট-মার্ক',
        value: '$cutMark',
        icon: Icons.filter_alt,
        emphasized: false
      ),
      (
        label: 'মোট প্রশ্ন',
        value: '$totalQuestions',
        icon: Icons.quiz,
        emphasized: false
      ),
      (
        label: 'সঠিক উত্তর',
        value: '$correctCount',
        icon: Icons.check_circle,
        emphasized: true
      ),
      (
        label: 'ভুল উত্তর',
        value: '$wrongCount',
        icon: Icons.cancel,
        emphasized: false
      ),
      (
        label: 'উত্তর দেওয়া হয়নি',
        value: '$unanswered',
        icon: Icons.remove_circle_outline,
        emphasized: false
      ),
      (
        label: 'আপনার স্কোর',
        value: userScore.toStringAsFixed(2),
        icon: Icons.scoreboard,
        emphasized: true
      ),
      (
        label: 'আপনার র‍্যাংক',
        value: rank != null ? '#$rank' : '—',
        icon: Icons.emoji_events,
        emphasized: true
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 3 ? 1.8 : 1.7,
          ),
          itemBuilder: (context, index) {
            final stat = stats[index];
            return _StatCard(
              label: stat.label,
              value: stat.value,
              icon: stat.icon,
              emphasized: stat.emphasized,
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (emphasized ? AppConstants.primary : AppConstants.accent)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: emphasized ? AppConstants.primary : AppConstants.accent,
                size: 20,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color:
                    emphasized ? AppConstants.primary : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppConstants.mutedText,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _BreakdownTable extends StatelessWidget {
  const _BreakdownTable({required this.breakdown, this.exam});

  final List<AnswerBreakdown> breakdown;
  final Exam? exam;

  @override
  Widget build(BuildContext context) {
    if (exam == null || exam!.questions.isEmpty) {
      return const Text(
        'কোনো প্রশ্ন পাওয়া যায়নি',
        style: TextStyle(color: AppConstants.mutedText),
      );
    }

    final answerByQuestion = <String, AnswerBreakdown>{
      for (final answer in breakdown) answer.questionId: answer,
    };
    final questionWeight = exam!.totalMarks / exam!.questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'সঠিক: ${answerByQuestion.values.where((item) => item.isCorrect).length}',
                style: const TextStyle(
                  color: Color(0xFF1B8730),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              'ভুল: ${answerByQuestion.values.where((item) => !item.isCorrect).length}',
              style: const TextStyle(
                color: Color(0xFFC62828),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Divider(height: 24),
        for (final (index, question) in exam!.questions.indexed) ...[
          Builder(
            builder: (context) {
              final item = answerByQuestion[question.id];
              final isUnanswered = item == null;
              final isCorrect = item?.isCorrect ?? false;
              final statusColor = isUnanswered
                  ? AppConstants.mutedText
                  : (isCorrect
                      ? const Color(0xFF1B8730)
                      : const Color(0xFFC62828));
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'প্রশ্ন ${index + 1}: ${question.questionText}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: const SizedBox.shrink(),
                      ),
                      Text(
                        'মার্ক: ${isUnanswered ? '0' : (isCorrect ? questionWeight : -questionWeight * exam!.negativeMarking).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  for (final (optionIndex, option) in question.options.indexed)
                    _ResultOption(
                      label: AppConstants.bengaliOptionLabels[optionIndex],
                      text: option,
                      isCorrect: question.correctOption ==
                          AppConstants.optionKeys[optionIndex],
                      isSelected: item?.selectedOption ==
                          AppConstants.optionKeys[optionIndex],
                    ),
                  const SizedBox(height: 4),
                  if ((item?.explanation ?? question.explanation ?? '')
                      .isNotEmpty)
                    Text(
                      'ব্যাখ্যা: ${item?.explanation ?? question.explanation}',
                      style: const TextStyle(color: AppConstants.mutedText),
                    ),
                ],
              );
            },
          ),
          if (index < exam!.questions.length - 1) const Divider(height: 24),
        ],
      ],
    );
  }
}

class _ResultOption extends StatelessWidget {
  const _ResultOption({
    required this.label,
    required this.text,
    required this.isCorrect,
    required this.isSelected,
  });

  final String label;
  final String text;
  final bool isCorrect;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isWrongSelection = isSelected && !isCorrect;
    final backgroundColor = isCorrect
        ? const Color(0xFFC8E6C9)
        : (isWrongSelection ? const Color(0xFFFFCDD2) : Colors.transparent);
    final foregroundColor = isCorrect
        ? const Color(0xFF1B5E20)
        : (isWrongSelection ? const Color(0xFFB71C1C) : Colors.black87);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: foregroundColor),
            ),
          ),
          if (isCorrect)
            const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18)
          else if (isWrongSelection)
            const Icon(Icons.cancel, color: Color(0xFFC62828), size: 18),
        ],
      ),
    );
  }
}
