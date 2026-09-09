import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/brand_navigation.dart';

class PreviousQuestionBankScreen extends StatefulWidget {
  const PreviousQuestionBankScreen({super.key});

  @override
  State<PreviousQuestionBankScreen> createState() =>
      _PreviousQuestionBankScreenState();
}

class _PreviousQuestionBankScreenState
    extends State<PreviousQuestionBankScreen> {
  static const _years = [
    'সব বছর',
    '43rd BCS',
    '44th BCS',
    '45th BCS',
    'Primary 2022',
    'Primary 2023',
    'Bank Job 2023',
  ];

  String _selectedYear = _years.first;
  String _search = '';
  late Future<List<Question>> _questions;

  @override
  void initState() {
    super.initState();
    _questions = _loadQuestions();
  }

  Future<List<Question>> _loadQuestions() {
    return QuestionService(apiClient).list(
      previousYear: _selectedYear == 'সব বছর' ? null : _selectedYear,
    );
  }

  void _selectYear(String year) {
    setState(() {
      _selectedYear = year;
      _questions = _loadQuestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(title: const Text('Previous Question Bank')),
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
          TextField(
            onChanged: (value) => setState(() => _search = value.trim()),
            decoration: const InputDecoration(
              labelText: 'প্রশ্ন খুঁজুন',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _years.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final year = _years[index];
                return ChoiceChip(
                  label: Text(year),
                  selected: year == _selectedYear,
                  onSelected: (_) => _selectYear(year),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<Question>>(
            future: _questions,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('প্রশ্ন লোড করা যায়নি: ${snapshot.error}');
              }
              final questions = (snapshot.data ?? []).where((question) {
                final matchesSearch = _search.isEmpty ||
                    question.questionText
                        .toLowerCase()
                        .contains(_search.toLowerCase());
                final matchesYear = _selectedYear == 'সব বছর' ||
                    question.previousYears.contains(_selectedYear);
                return matchesSearch && matchesYear;
              }).toList();
              if (questions.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                        child: Text('কোনো পূর্ববর্তী প্রশ্ন পাওয়া যায়নি')),
                  ),
                );
              }
              return Column(
                children: [
                  for (var index = 0; index < questions.length; index++)
                    _QuestionCard(index: index + 1, question: questions[index]),
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

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.index, required this.question});

  final int index;
  final Question question;

  @override
  Widget build(BuildContext context) {
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
            if (question.previousYears.isNotEmpty)
              Wrap(
                spacing: 6,
                children: [
                  for (final year in question.previousYears)
                    Chip(label: Text(year)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
