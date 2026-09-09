import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/brand_navigation.dart';

class SubjectPracticeScreen extends StatefulWidget {
  const SubjectPracticeScreen({super.key, this.topicId, this.topicName});

  final String? topicId;
  final String? topicName;

  @override
  State<SubjectPracticeScreen> createState() => _SubjectPracticeScreenState();
}

class _SubjectPracticeScreenState extends State<SubjectPracticeScreen> {
  late Future<List<Question>> _questions;

  static const _sections = [
    ('Previous Question Bank', 'বিগত বছরের প্রশ্ন', Color(0xFF7B1FA2)),
    ('অধ্যায়ভিত্তিক অনুশীলন', 'একেক অধ্যায়', Color(0xFF29B6E6)),
    ('সম্পূর্ণ সিলেবাস অনুশীলন', 'সবগুলো অধ্যায়', Color(0xFF18B447)),
    ('নির্বাচনী পরীক্ষা প্রস্তুতি', 'কমনের নিশ্চয়তা', Color(0xFF29B6E6)),
    ('ফাইনাল পরীক্ষা প্রস্তুতি', 'কমনের নিশ্চয়তা', Color(0xFF18B447)),
    ('পরীক্ষার আগে শর্ট সাজেশন', 'কমনের নিশ্চয়তা', Color(0xFFF39C12)),
  ];

  @override
  void initState() {
    super.initState();
    _questions = QuestionService(apiClient).list(topicId: widget.topicId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        title: Text(widget.topicName ?? 'Exam Type'),
      ),
      body: FutureBuilder<List<Question>>(
        future: _questions,
        builder: (context, snapshot) {
          final questions = snapshot.data ?? const <Question>[];
          final examTypes = <String, int>{};
          final sets = <String, int>{};
          for (final question in questions) {
            final type = question.examType;
            final set = question.questionSet;
            if (type != null && type.isNotEmpty) {
              examTypes[type] = (examTypes[type] ?? 0) + 1;
            }
            if (set != null && set.isNotEmpty) {
              sets[set] = (sets[set] ?? 0) + 1;
            }
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              if (examTypes.isNotEmpty) ...[
                const Text('এই বিষয়ের Exam Type',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                for (final entry in examTypes.entries)
                  _PracticeCard(
                    title: entry.key,
                    tag: '${entry.value}টি প্রশ্ন',
                    color: AppConstants.primary,
                    onTap: () => _showQuestionSet(context, entry.key),
                  ),
                const SizedBox(height: 8),
                if (sets.isNotEmpty)
                  Text(
                      'Question Set: ${sets.entries.map((e) => '${e.key} (${e.value})').join(', ')}',
                      style: const TextStyle(color: AppConstants.mutedText)),
                const SizedBox(height: 16),
              ],
              for (final section in _sections)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PracticeCard(
                    title: section.$1,
                    tag: section.$2,
                    color: section.$3,
                    onTap: () {
                      if (section.$1 == 'Previous Question Bank') {
                        context.push('/previous-question-bank');
                      } else {
                        _showComingSoon(context, section.$1);
                      }
                    },
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: BrandBottomNavigation(
        selectedIndex: 2,
        onSelected: (index) => BrandBottomNavigation.navigate(context, index),
      ),
    );
  }

  void _showQuestionSet(BuildContext context, String examType) {
    final questions = QuestionService(apiClient).list(
      topicId: widget.topicId,
      examType: examType,
    );
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => FutureBuilder<List<Question>>(
        future: questions,
        builder: (context, snapshot) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(examType,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            for (final question in snapshot.data ?? const <Question>[])
              ListTile(
                leading: const Icon(Icons.quiz),
                title: Text(question.questionText),
                subtitle: Text(question.questionSet ?? ''),
              ),
          ],
        ),
      ),
    );
  }

  static void _showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title শীঘ্রই শুরু হবে।')),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    required this.title,
    required this.tag,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String tag;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 82,
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  color: color,
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
