import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/brand_navigation.dart';
import 'mobile_dashboard.dart';

class PreviousQuestionBankScreen extends StatefulWidget {
  const PreviousQuestionBankScreen({super.key});

  @override
  State<PreviousQuestionBankScreen> createState() =>
      _PreviousQuestionBankScreenState();
}

class _PreviousQuestionBankScreenState
    extends State<PreviousQuestionBankScreen> {
  static const String _allFilter = 'সব';

  String _selectedFilter = _allFilter;
  String _search = '';
  late Future<List<Question>> _questions;
  late Future<List<Exam>> _exams;
  String _examSearch = '';
  String _examYear = 'সব বছর';

  @override
  void initState() {
    super.initState();
    _questions = _loadQuestions();
    _exams = ExamService(apiClient).list();
  }

  /// Loads the complete admin question bank (previous-year tags and
  /// exam_type included) so the filter chips are built from live data —
  /// new MCQs added by the admin show up here automatically.
  Future<List<Question>> _loadQuestions() {
    return QuestionService(apiClient).list();
  }

  /// Auto-builds the chips from admin-added MCQs: every unique previous-year
  /// tag (e.g. "43rd BCS") and every unique exam_type (e.g. "SSC", "Varsity"),
  /// with "সব" always first.
  List<String> _filters(List<Question> questions) {
    final filters = <String>[_allFilter];
    final seen = <String>{_allFilter};
    for (final question in questions) {
      for (final year in question.previousYears) {
        if (seen.add(year)) filters.add(year);
      }
      final type = question.examType;
      if (type != null && type.isNotEmpty && seen.add(type)) {
        filters.add(type);
      }
    }
    return filters;
  }

  bool _matches(Question question, String filter) {
    if (filter == _allFilter) return true;
    return question.previousYears.contains(filter) ||
        question.examType == filter;
  }

  /// Category (বিভাগ) summary for the currently selected exam type / year,
  /// e.g. "বিভাগ: SSC (5টি), Varsity (3টি)".
  String _categorySummary(List<Question> questions) {
    if (questions.isEmpty) return 'কোনো প্রশ্ন নেই';
    final counts = <String, int>{};
    for (final question in questions) {
      final topic =
          (question.topicName ?? '').isEmpty ? 'অন্যান্য' : question.topicName!;
      counts[topic] = (counts[topic] ?? 0) + 1;
    }
    return 'বিভাগ: ${counts.entries.map((e) => '${e.key} (${e.value}টি)').join(', ')}';
  }

  void _selectFilter(String filter) {
    setState(() => _selectedFilter = filter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      drawer: const DashboardDrawer(),
      appBar: const BrandHeader(),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            color: AppConstants.primary,
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.history_edu, color: Colors.white, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'বিগত বছরের গুরুত্বপূর্ণ প্রশ্ন অনুশীলন করুন',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PreviousExamCatalog(
            exams: _exams,
            search: _examSearch,
            year: _examYear,
            onSearch: (value) => setState(() => _examSearch = value),
            onYearChanged: (value) => setState(() => _examYear = value),
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: (value) => setState(() => _search = value.trim()),
            decoration: const InputDecoration(
              labelText: 'প্রশ্ন খুঁজুন',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Question>>(
            future: _questions,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('প্রশ্ন লোড করা যায়নি: ${snapshot.error}');
              }
              final all = snapshot.data ?? const <Question>[];
              final filters = _filters(all);
              final query = _search.trim().toLowerCase();
              final questions = all.where((question) {
                final matchesSearch = query.isEmpty ||
                    question.questionText.toLowerCase().contains(query) ||
                    (question.topicName ?? '').toLowerCase().contains(query) ||
                    (question.examType ?? '').toLowerCase().contains(query);
                return matchesSearch && _matches(question, _selectedFilter);
              }).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final filter = filters[index];
                        return ChoiceChip(
                          label: Text(filter),
                          selected: filter == _selectedFilter,
                          onSelected: (_) => _selectFilter(filter),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$questions.lengthটি প্রশ্ন — ফিল্টার: $_selectedFilter',
                    style: const TextStyle(
                        color: AppConstants.mutedText, fontSize: 12),
                  ),
                  if (_selectedFilter != _allFilter) ...[
                    const SizedBox(height: 4),
                    Text(
                      _categorySummary(questions),
                      style: const TextStyle(
                          color: AppConstants.mutedText, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (questions.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                            child:
                                Text('কোনো পূর্ববর্তী প্রশ্ন পাওয়া যায়নি')),
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (var index = 0; index < questions.length; index++)
                          _QuestionCard(
                              index: index + 1, question: questions[index]),
                      ],
                    ),
                ],
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BrandBottomNavigation(
        selectedIndex: 1,
        onSelected: (index) => BrandBottomNavigation.navigate(context, index),
      ),
    );
  }
}

class _PreviousExamCatalog extends StatelessWidget {
  const _PreviousExamCatalog({
    required this.exams,
    required this.search,
    required this.year,
    required this.onSearch,
    required this.onYearChanged,
  });

  final Future<List<Exam>> exams;
  final String search;
  final String year;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onYearChanged;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Exam>>(
      future: exams,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final all = snapshot.data ?? const <Exam>[];
        final years = <String>{
          'সব বছর',
          for (final exam in all)
            if (exam.startsAt != null) exam.startsAt!.year.toString(),
        }.toList();
        final filtered = all.where((exam) {
          final matchesSearch = search.trim().isEmpty ||
              exam.title.toLowerCase().contains(search.trim().toLowerCase());
          final matchesYear = year == 'সব বছর' ||
              exam.startsAt?.year.toString() == year;
          return matchesSearch && matchesYear;
        }).toList();
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF3F9),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Previous Exam Question Bank',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: onSearch,
                      decoration: const InputDecoration(
                        hintText: 'Search exam...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: years.contains(year) ? year : 'সব বছর',
                    items: [
                      for (final item in years)
                        DropdownMenuItem(value: item, child: Text(item)),
                    ],
                    onChanged: (value) {
                      if (value != null) onYearChanged(value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${filtered.length}টি exam পাওয়া গেছে',
                  style: const TextStyle(color: AppConstants.mutedText)),
              const SizedBox(height: 8),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('কোনো previous exam পাওয়া যায়নি'),
                )
              else
                for (final exam in filtered)
                  _PreviousExamCard(exam: exam),
            ],
          ),
        );
      },
    );
  }
}

class _PreviousExamCard extends StatelessWidget {
  const _PreviousExamCard({required this.exam});

  final Exam exam;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(exam.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(
              'Total marks: ${exam.totalMarks.toStringAsFixed(0)}  •  Duration: ${exam.durationMinutes} minutes',
              style: const TextStyle(color: AppConstants.mutedText),
            ),
            const SizedBox(height: 5),
            Text('প্রশ্ন ব্যাংক: ${exam.questionCount ?? exam.questions.length}টি প্রশ্ন'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _read(context),
                    child: const Text('Read'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => context.push('/exam/${exam.id}'),
                    child: const Text('Exam দিন'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _read(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FutureBuilder<Exam>(
        future: ExamService(apiClient).getById(exam.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
                height: 300, child: Center(child: CircularProgressIndicator()));
          }
          final questions = snapshot.data?.questions ?? const <Question>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(exam.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              for (var index = 0; index < questions.length; index++)
                _QuestionCard(index: index + 1, question: questions[index]),
            ],
          );
        },
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.index, required this.question});

  final int index;
  final Question question;

  @override
  Widget build(BuildContext context) {
    final category = question.topicName;
    final examType = question.examType;
    final questionSet = question.questionSet;
    final hasMeta = (category != null && category.isNotEmpty) ||
        (examType != null && examType.isNotEmpty) ||
        (questionSet != null && questionSet.isNotEmpty);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$index. ${question.questionText}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final option in question.options)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $option'),
              ),
            if (hasMeta) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  if (category != null && category.isNotEmpty)
                    Chip(label: Text('বিভাগ: $category')),
                  if (examType != null && examType.isNotEmpty)
                    Chip(label: Text('পরীক্ষা: $examType')),
                  if (questionSet != null && questionSet.isNotEmpty)
                    Chip(label: Text('Set: $questionSet')),
                ],
              ),
            ],
            if (question.previousYears.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  for (final year in question.previousYears)
                    Chip(label: Text(year)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
