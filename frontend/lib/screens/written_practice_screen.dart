import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/brand_navigation.dart';
import 'mobile_dashboard.dart';

class WrittenPracticeScreen extends ConsumerStatefulWidget {
  const WrittenPracticeScreen({
    super.key,
    required this.topicId,
    required this.topicName,
    this.setId,
    this.startInExamMode = false,
  });

  final String topicId;
  final String topicName;
  final String? setId;
  final bool startInExamMode;

  @override
  ConsumerState<WrittenPracticeScreen> createState() => _WrittenPracticeScreenState();
}

class _WrittenPracticeScreenState extends ConsumerState<WrittenPracticeScreen> {
  late Future<List<WrittenQuestion>> _questions;
  final _answers = <String, TextEditingController>{};
  late bool _examMode;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _examMode = widget.startInExamMode;
    _questions = WrittenQuestionService(apiClient).list(
      topicId: widget.topicId,
      setId: widget.setId,
      includeChildren: true,
    );
  }

  @override
  void dispose() {
    for (final controller in _answers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppConstants.background,
        drawer: const DashboardDrawer(),
        appBar: BrandHeader(showNotifications: false),
        body: FutureBuilder<List<WrittenQuestion>>(
          future: _questions,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Written প্রশ্ন লোড করা যায়নি: ${snapshot.error}'));
            }
            final questions = snapshot.data ?? const <WrittenQuestion>[];
            for (final question in questions) {
              _answers.putIfAbsent(question.id, TextEditingController.new);
            }
            final groups = _groupQuestions(questions);
            if (questions.isEmpty) {
              return const Center(child: Text('এই বিষয়ে এখনো Written প্রশ্ন যোগ করা হয়নি।'));
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(widget.topicName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, icon: Icon(Icons.menu_book_outlined), label: Text('পড়ুন')),
                          ButtonSegment(value: true, icon: Icon(Icons.edit_note), label: Text('পরীক্ষা')),
                        ],
                        selected: {_examMode},
                        onSelectionChanged: (selection) => setState(() => _examMode = selection.first),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return _examMode
                          ? _WrittenAnswerGroupCard(
                              index: index + 1,
                              group: group,
                              controllers: {
                                for (final question in group.questions)
                                  question.id: _answers[question.id]!,
                              },
                            )
                          : _WrittenReadGroupCard(index: index + 1, group: group);
                    },
                  ),
                ),
                if (_examMode)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : () => _submit(questions),
                        icon: _submitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.task_alt),
                        label: Text(_submitting ? 'জমা হচ্ছে...' : 'লিখিত উত্তর জমা দিন'),
                        style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
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

  Future<void> _submit(List<WrittenQuestion> questions) async {
    final answers = [
      for (final question in questions)
        if (_answers[question.id]!.text.trim().isNotEmpty)
          {
            'questionId': question.id,
            'response': _answers[question.id]!.text.trim(),
          },
    ];
    if (answers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('জমা দেওয়ার আগে অন্তত একটি উত্তর লিখুন')),
      );
      return;
    }
    final auth = ref.read(authNotifierProvider);
    final userId = auth.user?.userId ?? apiClient.authToken;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('পরীক্ষা জমা দিতে আবার sign in করুন')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await WrittenQuestionService(apiClient).submit(
        topicId: widget.topicId,
        userId: userId,
        answers: answers,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('উত্তর জমা হয়েছে'),
          content: const Text('Written উত্তরে স্বয়ংক্রিয় score নেই। পড়ুন tab থেকে নমুনা উত্তরের সঙ্গে মিলিয়ে নিন।'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ঠিক আছে'),
            ),
          ],
        ),
      );
      if (mounted) setState(() => _examMode = false);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('উত্তর জমা হয়নি: $error')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  List<_WrittenQuestionGroup> _groupQuestions(List<WrittenQuestion> questions) {
    final groups = <String, List<WrittenQuestion>>{};
    for (final question in questions) {
      final key = question.setId ?? 'single:${question.id}';
      groups.putIfAbsent(key, () => []).add(question);
    }
    return [
      for (final entry in groups.entries)
        _WrittenQuestionGroup(
          format: entry.value.first.format,
          title: entry.value.first.setTitle,
          stimulus: entry.value.first.stimulus,
          questions: entry.value,
        ),
    ];
  }
}

class _WrittenQuestionGroup {
  const _WrittenQuestionGroup({
    required this.format,
    required this.title,
    required this.stimulus,
    required this.questions,
  });

  final String format;
  final String title;
  final String stimulus;
  final List<WrittenQuestion> questions;
}

class _WrittenReadGroupCard extends StatefulWidget {
  const _WrittenReadGroupCard({required this.index, required this.group});

  final int index;
  final _WrittenQuestionGroup group;

  @override
  State<_WrittenReadGroupCard> createState() => _WrittenReadGroupCardState();
}

class _WrittenReadGroupCardState extends State<_WrittenReadGroupCard> {
  final _shownAnswers = <String>{};

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.group.title.isNotEmpty)
                Text(widget.group.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              if (widget.group.format == 'cq' && widget.group.stimulus.isNotEmpty) ...[
                Text('CQ সেট ${widget.index}', style: const TextStyle(color: AppConstants.mutedText, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppConstants.background, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('উদ্দীপক', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      Text(widget.group.stimulus, style: const TextStyle(height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              for (final question in widget.group.questions) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.group.format == 'cq'
                            ? 'প্রশ্ন ${question.itemOrder}'
                            : question.itemOrder > 1 || widget.group.questions.length > 1
                                ? 'প্রশ্ন ${question.itemOrder}'
                                : 'প্রশ্ন ${widget.index}',
                        style: const TextStyle(color: AppConstants.mutedText, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text('${question.marks.toStringAsFixed(question.marks % 1 == 0 ? 0 : 1)} নম্বর'),
                  ],
                ),
                const SizedBox(height: 6),
                Text(question.questionText, style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w700)),
                if (question.modelAnswer.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      if (!_shownAnswers.add(question.id)) _shownAnswers.remove(question.id);
                    }),
                    icon: Icon(_shownAnswers.contains(question.id) ? Icons.visibility_off : Icons.visibility),
                    label: Text(_shownAnswers.contains(question.id) ? 'নমুনা উত্তর লুকান' : 'নমুনা উত্তর দেখুন'),
                  ),
                  if (_shownAnswers.contains(question.id))
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppConstants.primary.withValues(alpha: .06), borderRadius: BorderRadius.circular(8)),
                      child: Text(question.modelAnswer, style: const TextStyle(height: 1.5)),
                    ),
                ],
                if (question != widget.group.questions.last) const Divider(height: 24),
              ],
            ],
          ),
        ),
      );
}

class _WrittenAnswerGroupCard extends StatelessWidget {
  const _WrittenAnswerGroupCard({
    required this.index,
    required this.group,
    required this.controllers,
  });

  final int index;
  final _WrittenQuestionGroup group;
  final Map<String, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (group.title.isNotEmpty)
                Text(group.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              if (group.format == 'cq' && group.stimulus.isNotEmpty) ...[
                Text('CQ সেট $index', style: const TextStyle(color: AppConstants.mutedText, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppConstants.background, borderRadius: BorderRadius.circular(8)),
                  child: Text(group.stimulus, style: const TextStyle(height: 1.5)),
                ),
                const SizedBox(height: 10),
              ],
              for (final question in group.questions) ...[
              Row(
                children: [
                  Expanded(child: Text('প্রশ্ন ${question.itemOrder}', style: const TextStyle(color: AppConstants.mutedText, fontWeight: FontWeight.w700))),
                  Text('${question.marks.toStringAsFixed(question.marks % 1 == 0 ? 0 : 1)} নম্বর'),
                ],
              ),
              const SizedBox(height: 8),
              Text(question.questionText, style: const TextStyle(fontSize: 17, height: 1.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: controllers[question.id],
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'আপনার উত্তর',
                  hintText: 'এখানে লিখুন...',
                ),
              ),
              if (question != group.questions.last) const Divider(height: 28),
              ],
            ],
          ),
        ),
      );
}