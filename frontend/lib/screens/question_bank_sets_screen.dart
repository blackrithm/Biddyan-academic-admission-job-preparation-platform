import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/brand_navigation.dart';
import '../widgets/interactive_question_card.dart';

class QuestionBankSetsScreen extends StatefulWidget {
  const QuestionBankSetsScreen({super.key, required this.category});

  final String category;

  @override
  State<QuestionBankSetsScreen> createState() => _QuestionBankSetsScreenState();
}

class _QuestionBankSetsScreenState extends State<QuestionBankSetsScreen> {
  late Future<_QuestionBankPageData> _data;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_QuestionBankPageData> _load() async {
    final topics = await TopicService(apiClient).getTree();
    final questions = await QuestionService(apiClient).list();
    final topicIds = <String>{};
    final target = _alias(widget.category).toLowerCase();

    void collect(TopicNode node) {
      topicIds.add(node.id);
      for (final child in node.children) {
        collect(child);
      }
    }

    void visit(List<TopicNode> nodes) {
      for (final node in nodes) {
        if (node.name.toLowerCase() == target) collect(node);
        visit(node.children);
      }
    }

    visit(topics);
    final categoryName = target.toLowerCase();
    final filtered = questions.where((question) {
      return topicIds.contains(question.topicId) ||
          question.topicName?.toLowerCase() == categoryName;
    }).toList();
    return _QuestionBankPageData(questions: filtered);
  }

  String _alias(String category) {
    return switch (category) {
      'BCS প্রস্তুতি' => 'BCS',
      'ব্যাংক জব' => 'Bank',
      _ => category,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        title: Text('${widget.category} Question Bank'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<_QuestionBankPageData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final questions = snapshot.data?.questions ?? const <Question>[];
          final sets = <String, List<Question>>{};
          for (final question in questions) {
            final name = question.questionSet?.trim();
            if (name != null && name.isNotEmpty) {
              sets.putIfAbsent(name, () => []).add(question);
            }
          }
          final query = _search.trim().toLowerCase();
          final visibleSets = sets.entries
              .where((entry) => entry.key.toLowerCase().contains(query))
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 24),
            children: [
              Card(
                color: AppConstants.primary,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    '${widget.category} Question Sets',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Color(0xFFEFF3F9)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('${widget.category} Question Sets',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (value) => setState(() => _search = value),
                      decoration: const InputDecoration(
                        hintText: 'Search question set...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${visibleSets.length}টি question set পাওয়া গেছে',
                        style: const TextStyle(color: AppConstants.mutedText)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (visibleSets.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('এই category-তে কোনো question set পাওয়া যায়নি।'),
                  ),
                )
              else
                for (final entry in visibleSets)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(entry.key,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 5),
                          Text('প্রশ্ন ব্যাংক: ${entry.value.length}টি প্রশ্ন',
                              style: const TextStyle(color: AppConstants.mutedText)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: FilledButton(
                                    onPressed: () => _openSet(context, entry.key, entry.value),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFDCD9FF),
                                      foregroundColor: const Color(0xFF202938),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text('Read Question'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: FilledButton(
                                    onPressed: () => _startExam(
                                      context,
                                      entry.key,
                                      entry.value,
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFE2E7EF),
                                      foregroundColor: const Color(0xFF202938),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text('Start Exam'),
                                  ),
                                ),
                              ),
                            ],
                            ),
                        ],
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
      bottomNavigationBar: BrandBottomNavigation(
        selectedIndex: 1,
        onSelected: (index) => BrandBottomNavigation.navigate(context, index),
      ),
    );
  }

  void _openSet(BuildContext context, String name, List<Question> questions) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _QuestionSetReaderPage(name: name, questions: questions),
      ),
    );
  }

  Future<void> _startExam(
    BuildContext context,
    String name,
    List<Question> questions,
  ) async {
    if (questions.isEmpty) return;
    try {
      final exam = await ExamService(apiClient).createFromQuestionSet(
        title: '${widget.category} - $name',
        topicId: questions.first.topicId,
        questionIds: questions.map((question) => question.id).toList(),
        totalMarks: questions.length.toDouble(),
        duration: questions.length,
      );
      if (context.mounted) context.push('/exam/${exam.id}');
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exam শুরু করা যায়নি: $error')),
        );
      }
    }
  }
}

class _QuestionSetReaderPage extends StatelessWidget {
  const _QuestionSetReaderPage({required this.name, required this.questions});

  final String name;
  final List<Question> questions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(title: Text(name)),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 24),
        itemCount: questions.length,
        itemBuilder: (context, index) => InteractiveQuestionCard(
          index: index + 1,
          question: questions[index],
        ),
      ),
    );
  }
}

class _QuestionBankPageData {
  const _QuestionBankPageData({required this.questions});

  final List<Question> questions;
}

