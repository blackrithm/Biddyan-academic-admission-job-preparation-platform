import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/brand_navigation.dart';
import 'mobile_dashboard.dart';

class ExamReadModeScreen extends StatelessWidget {
  const ExamReadModeScreen({super.key, required this.examId});

  final String examId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      drawer: const DashboardDrawer(),
      appBar: const BrandHeader(showNotifications: false),
      body: FutureBuilder<Exam>(
        future: ExamService(apiClient).getById(examId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text('প্রশ্নগুলো লোড করা যায়নি: ${snapshot.error ?? ''}'));
          }
          final exam = snapshot.data!;
          if (exam.questions.isEmpty) {
            return const Center(child: Text('এই পরীক্ষায় কোনো প্রশ্ন নেই।'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            children: [
              Text(exam.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('${exam.questions.length}টি প্রশ্ন • Read-only review'),
              const SizedBox(height: 14),
              for (var index = 0; index < exam.questions.length; index++)
                _ReadQuestionCard(index: index, question: exam.questions[index]),
            ],
          );
        },
      ),
    );
  }
}

class _ReadQuestionCard extends StatelessWidget {
  const _ReadQuestionCard({required this.index, required this.question});

  final int index;
  final Question question;

  @override
  Widget build(BuildContext context) {
    final correct = question.correctOption;
    final options = [question.optionA, question.optionB, question.optionC, question.optionD];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('প্রশ্ন ${index + 1}', style: const TextStyle(color: AppConstants.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          Text(question.questionText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          for (var optionIndex = 0; optionIndex < options.length; optionIndex++)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: correct == AppConstants.optionKeys[optionIndex] ? const Color(0xFFE5F5E9) : const Color(0xFFF5F7F7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: correct == AppConstants.optionKeys[optionIndex] ? Colors.green : Colors.transparent),
              ),
              child: Text('${AppConstants.bengaliOptionLabels[optionIndex]}. ${options[optionIndex]}'),
            ),
          if (question.explanation?.isNotEmpty == true) ...[
            const SizedBox(height: 5),
            Text('ব্যাখ্যা: ${question.explanation}', style: const TextStyle(color: AppConstants.mutedText)),
          ],
        ]),
      ),
    );
  }
}
