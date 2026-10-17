import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/brand_navigation.dart';
import 'mobile_dashboard.dart';
import '../widgets/interactive_question_card.dart';

class QuestionBankSetsScreen extends StatefulWidget {
  const QuestionBankSetsScreen({super.key, required this.category});

  final String category;

  @override
  State<QuestionBankSetsScreen> createState() => _QuestionBankSetsScreenState();
}

enum _QuestionBankSetType { mcq, written }

const _allSubjectsValue = '__all_subjects__';
const _allYearsValue = '';

class _QuestionBankSetsScreenState extends State<QuestionBankSetsScreen> {
  late Future<_QuestionBankPageData> _data;
  String _search = '';
  String? _selectedSubjectId;
  String _selectedExamYear = _allYearsValue;
  _QuestionBankSetType _selectedSetType = _QuestionBankSetType.mcq;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  @override
  void didUpdateWidget(covariant QuestionBankSetsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _data = _load();
      _selectedSubjectId = null;
      _selectedExamYear = _allYearsValue;
      _search = '';
    }
  }

  Future<_QuestionBankPageData> _load() async {
    final topics = await TopicService(apiClient).getTree();
    final questions = await QuestionService(apiClient).list();
    final writtenQuestions = await WrittenQuestionService(apiClient).list();
    final exams = await ExamService(apiClient).list();
    return _QuestionBankPageData(
      topics: topics,
      questions: questions,
      writtenQuestions: writtenQuestions,
      exams: exams,
    );
  }

  List<_SubjectOption> _subjectOptions(List<TopicNode> roots) {
    final options = <_SubjectOption>[];
    void visit(List<TopicNode> nodes, String? parentPath) {
      for (final topic in nodes) {
        final label = parentPath == null
            ? topic.name
            : '$parentPath / ${topic.name}';
        options.add(_SubjectOption(topic: topic, label: label));
        visit(topic.children, label);
      }
    }

    visit(roots, null);
    return options;
  }

  Set<String> _descendantTopicIds(TopicNode topic) {
    final ids = <String>{topic.id};
    for (final child in topic.children) {
      ids.addAll(_descendantTopicIds(child));
    }
    return ids;
  }

  String _normalizeSubject(String subject) => switch (subject.trim().toLowerCase()) {
        'bcs প্রস্তুতি' => 'bcs',
        'ব্যাংক জব' => 'bank',
        _ => subject.trim().toLowerCase(),
      };

  _SubjectOption? _defaultSubject(List<_SubjectOption> subjects) {
    final target = _normalizeSubject(widget.category);
    for (final subject in subjects) {
      if (_normalizeSubject(subject.topic.name) == target) return subject;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      drawer: const DashboardDrawer(),
      appBar: const BrandHeader(),
      body: FutureBuilder<_QuestionBankPageData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final questions = data.questions;
          final writtenQuestions = data.writtenQuestions;
          final exams = data.exams;
          final subjects = _subjectOptions(data.topics);
          final defaultSubject = _defaultSubject(subjects);
          final selectedSubjectId = _selectedSubjectId ??
              defaultSubject?.topic.id ??
              _allSubjectsValue;
          _SubjectOption? selectedSubject;
          for (final subject in subjects) {
            if (subject.topic.id == selectedSubjectId) {
              selectedSubject = subject;
              break;
            }
          }
          final selectedTopicIds = selectedSubject == null
              ? null
              : _descendantTopicIds(selectedSubject.topic);
          final subjectQuestions = questions.where((question) =>
              selectedTopicIds == null ||
              selectedTopicIds.contains(question.topicId));
          final subjectWrittenQuestions = writtenQuestions.where((question) =>
              selectedTopicIds == null ||
              selectedTopicIds.contains(question.topicId));
          final examYears = <String>{
            if (_selectedSetType == _QuestionBankSetType.mcq)
              for (final question in subjectQuestions)
                ...question.previousYears.where((year) => year.trim().isNotEmpty),
            if (_selectedSetType == _QuestionBankSetType.written)
              for (final question in subjectWrittenQuestions)
                ...question.previousYears.where((year) => year.trim().isNotEmpty),
          }.toList()
            ..sort();
          final selectedExamYear = examYears.contains(_selectedExamYear)
              ? _selectedExamYear
              : _allYearsValue;
          final filteredQuestions = subjectQuestions.where((question) =>
              selectedExamYear == _allYearsValue ||
              question.previousYears.contains(selectedExamYear));
          final filteredWrittenQuestions = subjectWrittenQuestions.where((question) =>
              selectedExamYear == _allYearsValue ||
              question.previousYears.contains(selectedExamYear));
          final sets = <String, List<Question>>{};
          for (final question in filteredQuestions) {
            final name = question.questionSet?.trim();
            if (name != null && name.isNotEmpty) {
              sets.putIfAbsent(name, () => []).add(question);
            }
          }
          final writtenSets = <String, List<WrittenQuestion>>{};
          for (final question in filteredWrittenQuestions) {
            final key = question.setId ??
                'legacy:${question.topicId}:${question.questionSet ?? question.id}';
            writtenSets.putIfAbsent(key, () => []).add(question);
          }
          final query = _search.trim().toLowerCase();
            final matchingMcqSets = sets.entries
              .where((entry) => entry.key.toLowerCase().contains(query))
              .toList();
            final matchingWrittenSets = writtenSets.entries.where((entry) {
            final question = entry.value.first;
            final title = question.setTitle.isNotEmpty
                ? question.setTitle
                : question.questionSet ?? 'Written set';
            return title.toLowerCase().contains(query);
          }).toList();
            final visibleSets = _selectedSetType == _QuestionBankSetType.mcq
              ? matchingMcqSets
              : const <MapEntry<String, List<Question>>>[];
            final visibleWrittenSets =
              _selectedSetType == _QuestionBankSetType.written
                ? matchingWrittenSets
                : const <MapEntry<String, List<WrittenQuestion>>>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 24),
            children: [
              Card(
                color: AppConstants.primary,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    '${selectedSubject?.label ?? 'All Subjects'} Question Sets',
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final subjectField = DropdownButtonFormField<String>(
                          value: selectedSubjectId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Subject Name',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: _allSubjectsValue,
                              child: Text('All Subjects'),
                            ),
                            for (final subject in subjects)
                              DropdownMenuItem(
                                value: subject.topic.id,
                                child: Text(
                                  subject.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) => setState(() {
                            _selectedSubjectId = value;
                            _selectedExamYear = _allYearsValue;
                          }),
                        );
                        final questionTypeField = SegmentedButton<_QuestionBankSetType>(
                          segments: const [
                            ButtonSegment(
                              value: _QuestionBankSetType.mcq,
                              label: Text('MCQ Set'),
                            ),
                            ButtonSegment(
                              value: _QuestionBankSetType.written,
                              label: Text('Written Set'),
                            ),
                          ],
                          selected: {_selectedSetType},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) => setState(() {
                            _selectedSetType = selection.first;
                            _selectedExamYear = _allYearsValue;
                          }),
                        );
                        final yearField = DropdownButtonFormField<String>(
                          value: selectedExamYear,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Exam Year',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: _allYearsValue,
                              child: Text('All Years'),
                            ),
                            for (final year in examYears)
                              DropdownMenuItem(
                                value: year,
                                child: Text(year),
                              ),
                          ],
                          onChanged: (value) => setState(
                            () => _selectedExamYear = value ?? _allYearsValue,
                          ),
                        );

                        if (constraints.maxWidth < 560) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              subjectField,
                              const SizedBox(height: 10),
                              questionTypeField,
                              const SizedBox(height: 10),
                              yearField,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(flex: 3, child: subjectField),
                            const SizedBox(width: 10),
                            Expanded(flex: 3, child: questionTypeField),
                            const SizedBox(width: 10),
                            Expanded(flex: 2, child: yearField),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (value) => setState(() => _search = value),
                      decoration: const InputDecoration(
                        hintText: 'Search question set...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${visibleSets.length + visibleWrittenSets.length}টি question set পাওয়া গেছে',
                        style: const TextStyle(color: AppConstants.mutedText)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (visibleSets.isEmpty && visibleWrittenSets.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('এই filter-এ কোনো question set পাওয়া যায়নি।'),
                  ),
                ),
              for (final entry in visibleSets)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(entry.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 5),
                        Text('প্রশ্ন ব্যাংক: ${entry.value.length}টি প্রশ্ন', style: const TextStyle(color: AppConstants.mutedText)),
                        if (_examForSet(
                              exams,
                              entry.key,
                              selectedSubject?.topic.name ?? widget.category,
                            )
                            case final exam?)
                          Text(
                            'মোট ${exam.totalMarks.toStringAsFixed(0)} নম্বর • ভুল উত্তরে ${exam.negativeMarking} কাটা যাবে',
                            style: const TextStyle(color: AppConstants.mutedText),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: FilledButton(
                                  onPressed: () => _openSet(context, entry.key, entry.value),
                                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDCD9FF), foregroundColor: const Color(0xFF202938), elevation: 0),
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
                                    selectedSubject?.topic.name ?? widget.category,
                                    entry.key,
                                    entry.value,
                                  ),
                                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE2E7EF), foregroundColor: const Color(0xFF202938), elevation: 0),
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
              if (visibleWrittenSets.isNotEmpty) ...[
                  const SizedBox(height: 12),
                for (final entry in visibleWrittenSets)
                  _WrittenSetCard(
                    questions: entry.value,
                    title: entry.value.first.setTitle.isNotEmpty
                        ? entry.value.first.setTitle
                        : entry.value.first.questionSet ?? 'Written set',
                    onRead: () => _openWrittenSet(context, entry.value, examMode: false),
                    onExam: () => _openWrittenSet(context, entry.value, examMode: true),
                  ),
              ],
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

  void _openSet(BuildContext context, String name, List<Question> questions) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _QuestionSetReaderPage(name: name, questions: questions),
      ),
    );
  }

  void _openWrittenSet(
    BuildContext context,
    List<WrittenQuestion> questions, {
    required bool examMode,
  }) {
    final first = questions.first;
    final query = <String, String>{
      'topicId': first.topicId,
      'topicName': first.setTitle.isNotEmpty ? first.setTitle : first.topicName ?? 'Written প্রশ্ন',
      if (first.setId != null) 'setId': first.setId!,
      if (examMode) 'mode': 'exam',
    };
    context.push('/written-practice?${Uri(queryParameters: query).query}');
  }

  Future<void> _startExam(
    BuildContext context,
    String subjectName,
    String name,
    List<Question> questions,
  ) async {
    if (questions.isEmpty) return;
    try {
      final existingExam = _examForSet(
        (await ExamService(apiClient).list()),
        name,
        subjectName,
      );
      if (existingExam != null && context.mounted) {
        context.push('/exam/${existingExam.id}');
        return;
      }
      final exam = await ExamService(apiClient).createFromQuestionSet(
        title: '$subjectName - $name',
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

  Exam? _examForSet(List<Exam> exams, String name, String subjectName) {
    for (final exam in exams) {
      if (exam.title == name || exam.title == '$subjectName - $name') {
        return exam;
      }
    }
    return null;
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
  const _QuestionBankPageData({
    required this.topics,
    required this.questions,
    required this.writtenQuestions,
    required this.exams,
  });

  final List<TopicNode> topics;
  final List<Question> questions;
  final List<WrittenQuestion> writtenQuestions;
  final List<Exam> exams;
}

class _SubjectOption {
  const _SubjectOption({required this.topic, required this.label});

  final TopicNode topic;
  final String label;
}

class _WrittenSetCard extends StatelessWidget {
  const _WrittenSetCard({
    required this.questions,
    required this.title,
    required this.onRead,
    required this.onExam,
  });

  final List<WrittenQuestion> questions;
  final String title;
  final VoidCallback onRead;
  final VoidCallback onExam;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                '${questions.first.format == 'cq' ? 'CQ' : 'Written'} • ${questions.length}টি প্রশ্ন • ${questions.fold<double>(0, (sum, question) => sum + question.marks).toStringAsFixed(0)} নম্বর',
                style: const TextStyle(color: AppConstants.mutedText),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: OutlinedButton.icon(onPressed: onRead, icon: const Icon(Icons.menu_book_outlined), label: const Text('পড়ুন'))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton.icon(onPressed: onExam, icon: const Icon(Icons.edit_note), label: const Text('Written exam'))),
                ],
              ),
            ],
          ),
        ),
      );
}

