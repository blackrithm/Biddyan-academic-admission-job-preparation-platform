import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/brand_navigation.dart';

class SubjectPracticeScreen extends StatefulWidget {
  const SubjectPracticeScreen({super.key, this.topicId, this.topicName, this.showAll = false});

  final String? topicId;
  final String? topicName;
  final bool showAll;

  @override
  State<SubjectPracticeScreen> createState() => _SubjectPracticeScreenState();
}

class _SubjectPracticeScreenState extends State<SubjectPracticeScreen> {
  late Future<List<Question>> _questions;

  @override
  void initState() {
    super.initState();
    _questions = _loadTopicQuestions();
  }

  Future<List<Question>> _loadTopicQuestions() async {
    if (widget.topicId == null) return QuestionService(apiClient).list();
    final topics = await TopicService(apiClient).getTree();
    TopicNode? find(List<TopicNode> nodes) {
      for (final node in nodes) {
        if (node.id == widget.topicId) return node;
        final match = find(node.children);
        if (match != null) return match;
      }
      return null;
    }
    final topic = find(topics);
    if (topic == null) return QuestionService(apiClient).list(topicId: widget.topicId);
    final ids = <String>{};
    void collect(TopicNode node) {
      ids.add(node.id);
        for (final child in node.children) {
          collect(child);
        }
    }
    collect(topic);
    final allQuestions = await QuestionService(apiClient).list();
    return allQuestions.where((question) => ids.contains(question.topicId)).toList();
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
          if (questions.isNotEmpty && examTypes.isEmpty) {
            return _QuestionSetSheetContent(
              title: widget.topicName ?? 'প্রশ্ন অনুশীলন',
              questions: Future.value(questions),
              showClose: false,
            );
          }
          if (widget.showAll) {
            return _QuestionSetSheetContent(
              title: widget.topicName ?? 'প্রশ্ন অনুশীলন',
              questions: Future.value(questions),
              showClose: false,
            );
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
              if (examTypes.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('এই বিষয়ে এখনো কোনো Exam Type যোগ করা হয়নি।'),
                    ),
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuestionSetSheet(
        title: examType,
        questions: questions,
      ),
    );
  }

}

class _QuestionSetSheet extends StatelessWidget {
  const _QuestionSetSheet({required this.title, required this.questions});

  final String title;
  final Future<List<Question>> questions;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, controller) => Material(
        color: AppConstants.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: _QuestionSetSheetContent(
          title: title,
          questions: questions,
          scrollController: controller,
        ),
      ),
    );
  }
}

class _QuestionSetSheetContent extends StatelessWidget {
  const _QuestionSetSheetContent({
    required this.title,
    required this.questions,
    this.scrollController,
    this.showClose = true,
  });

  final String title;
  final Future<List<Question>> questions;
  final ScrollController? scrollController;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Question>>(
          future: questions,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('প্রশ্ন লোড করা যায়নি: ${snapshot.error}'));
            }
            final rows = snapshot.data ?? const <Question>[];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppConstants.primary,
                          ),
                        ),
                      ),
                      Text('${rows.length}টি প্রশ্ন',
                          style: const TextStyle(color: AppConstants.mutedText)),
                      if (showClose) IconButton(
                        tooltip: 'বন্ধ করুন',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: rows.isEmpty
                      ? const Center(child: Text('এই Exam Type-এ কোনো প্রশ্ন নেই'))
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
                          itemCount: rows.length,
                          itemBuilder: (context, index) => _InteractiveQuestionCard(
                            index: index + 1,
                            question: rows[index],
                          ),
                        ),
                ),
              ],
            );
          },
        );
  }
}

class _InteractiveQuestionCard extends StatefulWidget {
  const _InteractiveQuestionCard({required this.index, required this.question});

  final int index;
  final Question question;

  @override
  State<_InteractiveQuestionCard> createState() =>
      _InteractiveQuestionCardState();
}

class _InteractiveQuestionCardState extends State<_InteractiveQuestionCard> {
  bool _showAnswer = false;
  bool _showExplanation = false;
  bool _bookmarked = false;
  String? _selectedOption;

  static const _labels = ['ক', 'খ', 'গ', 'ঘ'];
  static const _keys = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'প্রশ্ন ${widget.index}\n${question.questionText}',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _bookmarked ? 'বুকমার্ক সরান' : 'বুকমার্ক করুন',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _bookmarked = !_bookmarked),
                  icon: Icon(
                    _bookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _bookmarked
                        ? AppConstants.accent
                        : AppConstants.mutedText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < question.options.length; index++)
              _OptionRow(
                label: _labels[index],
                text: question.options[index],
                selected: _selectedOption == _keys[index],
                correct: _showAnswer && question.correctOption == _keys[index],
                incorrect: _showAnswer &&
                    _selectedOption == _keys[index] &&
                    question.correctOption != _keys[index],
                onTap: () => setState(() => _selectedOption = _keys[index]),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _ActionChip(
                  icon: _showAnswer ? Icons.visibility_off : Icons.visibility,
                  label: _showAnswer ? 'উত্তর লুকান' : 'উত্তর দেখুন',
                  onPressed: () => setState(() => _showAnswer = !_showAnswer),
                ),
                if (question.explanation?.trim().isNotEmpty == true)
                  _ActionChip(
                    icon: Icons.lightbulb_outline,
                    label: 'ব্যাখ্যা',
                    onPressed: () => setState(
                        () => _showExplanation = !_showExplanation),
                  ),
              ],
            ),
            if (_showExplanation && question.explanation?.trim().isNotEmpty == true)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('ব্যাখ্যা: ${question.explanation}'),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.text,
    required this.selected,
    required this.correct,
    required this.incorrect,
    required this.onTap,
  });

  final String label;
  final String text;
  final bool selected;
  final bool correct;
  final bool incorrect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = correct
        ? Colors.green
        : incorrect
            ? AppConstants.accent
            : selected
                ? AppConstants.primary
                : Colors.transparent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: correct || incorrect || selected ? 0.1 : 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color == Colors.transparent ? const Color(0xFFE5E8E7) : color),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: color == Colors.transparent
                    ? const Color(0xFF9DEBF6)
                    : color,
                child: Text(label,
                    style: TextStyle(
                        color: color == Colors.transparent ? AppConstants.primary : Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(text)),
              if (correct) const Icon(Icons.check_circle, color: Colors.green, size: 20),
              if (incorrect) const Icon(Icons.cancel, color: AppConstants.accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppConstants.primary),
      label: Text(label),
      onPressed: onPressed,
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
