import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';

class AdminQuestionBank extends StatefulWidget {
  const AdminQuestionBank({super.key, required this.topics});

  final List<TopicNode> topics;

  @override
  State<AdminQuestionBank> createState() => _AdminQuestionBankState();
}

class _AdminQuestionBankState extends State<AdminQuestionBank> {
  final _setController = TextEditingController();
  final _examTypeController = TextEditingController();
  final _totalMarksController = TextEditingController(text: '50');
  final _passMarksController = TextEditingController(text: '20');
  final _negativeMarksController = TextEditingController(text: '0.25');
  final _durationController = TextEditingController(text: '60');
  final _jsonController = TextEditingController();
  String? _topicId;
  String _difficulty = 'medium';
  bool _saving = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _setController.dispose();
    _examTypeController.dispose();
    _totalMarksController.dispose();
    _passMarksController.dispose();
    _negativeMarksController.dispose();
    _durationController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flatTopics = <({TopicNode node, int depth})>[];
    void walk(List<TopicNode> nodes, int depth) {
      for (final node in nodes) {
        flatTopics.add((node: node, depth: depth));
        walk(node.children, depth + 1);
      }
    }
    walk(widget.topics, 0);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Question Bank Set Upload', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('একটি category নির্বাচন করে একটি সম্পূর্ণ question set upload করুন। এই set-টি Home page-এর Question Bank section-এ দেখা যাবে।', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _topicId,
                      decoration: const InputDecoration(labelText: 'Main category / বিভাগ'),
                      items: [
                        for (final row in flatTopics)
                          DropdownMenuItem(value: row.node.id, child: Text('${'  ' * row.depth}${row.node.name}')),
                      ],
                      onChanged: (value) => setState(() => _topicId = value),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: _setController, decoration: const InputDecoration(labelText: 'Question set name', hintText: 'যেমন: SSC Model Test 1')),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _examTypeController, decoration: const InputDecoration(labelText: 'Exam type'))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _difficulty,
                            decoration: const InputDecoration(labelText: 'কঠিনতা'),
                            items: const [
                              DropdownMenuItem(value: 'easy', child: Text('সহজ')),
                              DropdownMenuItem(value: 'medium', child: Text('মাঝারি')),
                              DropdownMenuItem(value: 'hard', child: Text('কঠিন')),
                            ],
                            onChanged: (value) => setState(() => _difficulty = value ?? 'medium'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passMarksController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'পাস মার্ক'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _totalMarksController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'মোট মার্ক'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _negativeMarksController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'নেগেটিভ মার্ক'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'সময় (মিনিট)'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _jsonController,
                      minLines: 8,
                      maxLines: 14,
                      decoration: const InputDecoration(labelText: 'Question set JSON', hintText: '[{"question_text":"...","option_a":"...","option_b":"...","option_c":"...","option_d":"...","correct_option":"A"}]'),
                    ),
                    const SizedBox(height: 12),
                    if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                    if (_success != null) Text(_success!, style: const TextStyle(color: Colors.green)),
                    const SizedBox(height: 8),
                    FilledButton.icon(onPressed: _saving ? null : _upload, icon: const Icon(Icons.upload_file), label: Text(_saving ? 'Upload হচ্ছে...' : 'Question set upload করুন')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _upload() async {
    if (_topicId == null) {
      setState(() => _error = 'প্রথমে একটি category নির্বাচন করুন');
      return;
    }
    if (_setController.text.trim().isEmpty) {
      setState(() => _error = 'Question set-এর নাম দিন');
      return;
    }
    final totalMarks = double.tryParse(_totalMarksController.text.trim());
    final passMark = double.tryParse(_passMarksController.text.trim());
    if (totalMarks == null || passMark == null ||
        double.tryParse(_negativeMarksController.text.trim()) == null ||
        int.tryParse(_durationController.text.trim()) == null) {
      setState(() => _error = 'মোট মার্ক, পাস মার্ক, নেগেটিভ মার্ক এবং সময় সঠিকভাবে দিন');
      return;
    }
    if (passMark < 0 || passMark > totalMarks) {
      setState(() => _error = 'পাস মার্ক ০ থেকে মোট মার্কের মধ্যে দিন');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      final decoded = jsonDecode(_jsonController.text);
      final rawQuestions = decoded is Map ? decoded['questions'] : decoded;
      if (rawQuestions is! List || rawQuestions.isEmpty) throw const FormatException('questions array দিন');
      final questions = rawQuestions.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      final insertedQuestions = await QuestionService(apiClient).bulkCreateWithQuestions(
        topicId: _topicId!,
        questions: questions,
        defaults: {
          'question_set': _setController.text.trim(),
          'exam_type': _examTypeController.text.trim(),
          'difficulty_level': _difficulty,
          'source': 'question-bank',
        },
      );
      await ExamService(apiClient).createFromQuestionSet(
        title: _setController.text.trim(),
        topicId: _topicId,
        questionIds: insertedQuestions.map((question) => question.id).toList(),
        totalMarks: totalMarks,
        passMark: passMark,
        negativeMarking: double.parse(_negativeMarksController.text.trim()),
        duration: int.parse(_durationController.text.trim()),
      );
      if (mounted) {
        setState(() {
          _jsonController.clear();
          _success = '${insertedQuestions.length}টি প্রশ্নসহ ${_setController.text.trim()} upload হয়েছে';
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Upload ব্যর্থ: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
