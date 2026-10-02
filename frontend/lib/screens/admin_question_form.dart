import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import 'admin_form_widgets.dart';

/// MCQ question creation form (Admin Panel, tab 2).
class AdminQuestionForm extends ConsumerStatefulWidget {
  const AdminQuestionForm({super.key, required this.topics});

  final List<TopicNode> topics;

  @override
  ConsumerState<AdminQuestionForm> createState() => _AdminQuestionFormState();
}

class _AdminQuestionFormState extends ConsumerState<AdminQuestionForm> {
  final _textCtrl = TextEditingController();
  final _aCtrl = TextEditingController();
  final _bCtrl = TextEditingController();
  final _cCtrl = TextEditingController();
  final _dCtrl = TextEditingController();
  final _explanationCtrl = TextEditingController();
  final _stimulusCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _bulkJsonCtrl = TextEditingController();
  final _examTypeCtrl = TextEditingController();
  final _questionSetCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController(text: 'admin');

  String? _topicId;
  String _correctOption = 'A';
  String _difficulty = 'medium';
  String _writtenFormat = 'written';
  List<_WrittenDraft> _writtenDrafts = [_WrittenDraft()];
  final List<String> _previousYears = [];
  bool _saving = false;
  String? _error;
  String? _success;

  static const _suggestedTags = [
    '43rd BCS',
    '44th BCS',
    '45th BCS',
    'Primary 2022',
    'Primary 2023',
    'Bank Job 2023',
  ];

  static const _bengaliLabels = ['ক', 'খ', 'গ', 'ঘ'];
  static const _optionKeys = ['A', 'B', 'C', 'D'];

  @override
  void dispose() {
    _textCtrl.dispose();
    _aCtrl.dispose();
    _bCtrl.dispose();
    _cCtrl.dispose();
    _dCtrl.dispose();
    _explanationCtrl.dispose();
    _stimulusCtrl.dispose();
    for (final draft in _writtenDrafts) {
      draft.dispose();
    }
    _tagCtrl.dispose();
    _bulkJsonCtrl.dispose();
    _examTypeCtrl.dispose();
    _questionSetCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  TextEditingController _optionCtrl(int index) {
    switch (index) {
      case 0:
        return _aCtrl;
      case 1:
        return _bCtrl;
      case 2:
        return _cCtrl;
      default:
        return _dCtrl;
    }
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
    final selectedTopic = flatTopics
      .where((row) => row.node.id == _topicId)
      .firstOrNull
      ?.node;
    final isWritten = selectedTopic?.questionType == 'written';

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
                    Text(
                      'নতুন ${isWritten ? 'Written' : 'MCQ'} প্রশ্ন যোগ করুন',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _topicId,
                      decoration: const InputDecoration(
                        labelText: 'বিষয় / সাব-টপিক নির্বাচন করুন',
                      ),
                      items: [
                        for (final row in flatTopics)
                          DropdownMenuItem(
                            value: row.node.id,
                            child: Text(
                              '${'  ' * row.depth}${row.node.name}',
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() => _topicId = value),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'এই বিভাগটি একবার নির্বাচন করলে নিচের সব প্রশ্নে প্রয়োগ হবে।',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _examTypeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Exam type',
                              hintText: 'যেমন: BCS প্রিলিমিনারি',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _questionSetCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Question set',
                              hintText: 'যেমন: Set A / 2024',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _difficulty,
                            decoration: const InputDecoration(
                              labelText: 'কঠিনতার স্তর',
                            ),
                            items: const [
                              DropdownMenuItem(value: 'easy', child: Text('সহজ')),
                              DropdownMenuItem(
                                  value: 'medium', child: Text('মাঝারি')),
                              DropdownMenuItem(value: 'hard', child: Text('কঠিন')),
                            ],
                            onChanged: (value) => setState(
                              () => _difficulty = value ?? 'medium',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _sourceCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Source / উৎস',
                              hintText: 'যেমন: Admin, BCS 2023',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (isWritten) ...[
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'written', label: Text('Written')),
                          ButtonSegment(value: 'cq', label: Text('CQ')),
                        ],
                        selected: {_writtenFormat},
                        onSelectionChanged: (value) => setState(() => _writtenFormat = value.first),
                      ),
                      if (_writtenFormat == 'cq') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _stimulusCtrl,
                          minLines: 3,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            labelText: 'উদ্দীপক',
                            hintText: 'CQ-এর উদ্দীপক লিখুন...',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      for (final (index, draft) in _writtenDrafts.indexed)
                        Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'প্রশ্ন ${index + 1}',
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    if (_writtenDrafts.length > 1)
                                      IconButton(
                                        tooltip: 'প্রশ্ন সরান',
                                        onPressed: () => setState(() {
                                          _writtenDrafts.removeAt(index).dispose();
                                        }),
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      ),
                                  ],
                                ),
                                TextField(
                                  controller: draft.question,
                                  minLines: 2,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    labelText: _writtenFormat == 'cq'
                                        ? 'প্রশ্ন ${index + 1} (যেমন: ক, খ, গ, ঘ)'
                                        : 'প্রশ্ন',
                                    alignLabelWithHint: true,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: draft.answer,
                                  minLines: 2,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'উত্তর / নমুনা উত্তর',
                                    alignLabelWithHint: true,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: 140,
                                  child: TextField(
                                    controller: draft.marks,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(labelText: 'পূর্ণ নম্বর'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _writtenDrafts.add(_WrittenDraft())),
                        icon: const Icon(Icons.add),
                        label: const Text('আরেকটি প্রশ্ন যোগ করুন'),
                      ),
                    ] else ...[
                      TextField(
                        controller: _textCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'প্রশ্নের বর্ণনা',
                          hintText: 'প্রশ্নটি এখানে লিখুন...',
                        ),
                      ),
                      const SizedBox(height: 10),
                      const SizedBox(height: 12),
                      for (final (i, label) in _bengaliLabels.indexed)
                        OptionField(
                          label: label,
                          controller: _optionCtrl(i),
                          isSelected: _correctOption == _optionKeys[i],
                          onPick: () => setState(() => _correctOption = _optionKeys[i]),
                        ),
                    ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: _explanationCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'ব্যাখ্যা (Explanation)',
                          hintText: 'সঠিক উত্তরের বিস্তারিত ব্যাখ্যা...',
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Question Bank Set Bulk Upload',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'উপরের category এবং Question set নির্বাচন করে সরাসরি একটি সম্পূর্ণ প্রশ্ন সেট upload করুন।',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _bulkJsonCtrl,
                      minLines: 4,
                      maxLines: 8,
                      decoration: InputDecoration(
                        labelText: isWritten ? 'Written / CQ JSON' : 'MCQ JSON',
                        hintText: isWritten
                            ? '{"format":"cq","stimulus":"...","questions":[{"question_text":"...","model_answer":"...","marks":5}]}'
                            : '[{"question_text":"...","option_a":"...","option_b":"...","option_c":"...","option_d":"...","correct_option":"A"}]',
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _bulkImport,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Question set upload করুন'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            PreviousYearsTags(
              tags: _previousYears,
              suggested: _suggestedTags,
              tagCtrl: _tagCtrl,
              onToggle: _toggleTag,
              onAddCustom: _addCustomTag,
            ),
            const SizedBox(height: 16),
            SaveSection(
              saving: _saving,
              error: _error,
              success: _success,
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_previousYears.contains(tag)) {
        _previousYears.remove(tag);
      } else {
        _previousYears.add(tag);
      }
    });
  }

  void _addCustomTag() {
    final tag = _tagCtrl.text.trim();
    if (tag.isEmpty) return;
    setState(() {
      if (!_previousYears.contains(tag)) {
        _previousYears.add(tag);
      }
      _tagCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (_topicId == null) {
      setState(() {
        _error = 'বিষয় নির্বাচন করুন';
        _success = null;
      });
      return;
    }
    final topic = widget.topics.expand(_flattenTopics).firstWhere((item) => item.id == _topicId);
    if (topic.questionType == 'written') {
      final invalid = _writtenDrafts.any((draft) =>
          draft.question.text.trim().isEmpty ||
          double.tryParse(draft.marks.text.trim()) == null ||
          double.parse(draft.marks.text.trim()) <= 0);
      if (invalid || (_writtenFormat == 'cq' && _stimulusCtrl.text.trim().isEmpty)) {
        setState(() => _error = 'উদ্দীপক, প্রতিটি প্রশ্ন এবং সঠিক পূর্ণ নম্বর দিন');
        return;
      }
    } else if (_textCtrl.text.trim().isEmpty) {
      setState(() => _error = 'প্রশ্নের বর্ণনা পূরণ করুন');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      if (topic.questionType == 'written') {
        await _createWrittenSet(
          format: _writtenFormat,
          stimulus: _stimulusCtrl.text.trim(),
          questions: [
            for (final draft in _writtenDrafts)
              {
                'question_text': draft.question.text.trim(),
                'model_answer': draft.answer.text.trim(),
                'marks': double.parse(draft.marks.text.trim()),
              },
          ],
        );
      } else {
        await QuestionService(apiClient).create({
          'topic_id': _topicId,
          'question_text': _textCtrl.text.trim(),
          'option_a': _aCtrl.text.trim(),
          'option_b': _bCtrl.text.trim(),
          'option_c': _cCtrl.text.trim(),
          'option_d': _dCtrl.text.trim(),
          'correct_option': _correctOption,
          'explanation': _explanationCtrl.text.trim(),
          'previous_years': _previousYears,
          'difficulty_level': _difficulty,
          'exam_type': _examTypeCtrl.text.trim(),
          'question_set': _questionSetCtrl.text.trim(),
          'source': _sourceCtrl.text.trim(),
        });
      }
      setState(() {
        _success = 'প্রশ্ন সফলভাবে সংরক্ষিত হয়েছে';
        _textCtrl.clear();
        _aCtrl.clear();
        _bCtrl.clear();
        _cCtrl.clear();
        _dCtrl.clear();
        _explanationCtrl.clear();
        _stimulusCtrl.clear();
        for (final draft in _writtenDrafts) {
          draft.dispose();
        }
        _writtenDrafts = [_WrittenDraft()];
        _previousYears.clear();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  Iterable<TopicNode> _flattenTopics(TopicNode node) sync* {
    yield node;
    for (final child in node.children) {
      yield* _flattenTopics(child);
    }
  }

  Future<void> _createWrittenSet({
    required String format,
    required String stimulus,
    required List<Map<String, dynamic>> questions,
    String? title,
    String? examType,
    String? questionSet,
    List<String>? previousYears,
  }) async {
    await WrittenQuestionService(apiClient).createSet(
      topicId: _topicId!,
      format: format,
      title: title ?? _questionSetCtrl.text.trim(),
      stimulus: stimulus,
      examType: examType ?? _examTypeCtrl.text.trim(),
      questionSet: questionSet ?? _questionSetCtrl.text.trim(),
      previousYears: previousYears ?? _previousYears,
      difficultyLevel: _difficulty,
      source: _sourceCtrl.text.trim().isEmpty ? 'admin' : _sourceCtrl.text.trim(),
      questions: questions,
    );
  }

  Future<void> _bulkImport() async {
      if (_topicId == null) {
        setState(() => _error = 'প্রথমে বিভাগ নির্বাচন করুন');
        return;
      }
      if (_questionSetCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Question set-এর নাম দিন');
        return;
      }
      try {
        final decoded = jsonDecode(_bulkJsonCtrl.text);
        setState(() {
          _saving = true;
          _error = null;
          _success = null;
        });
        final topic = widget.topics.expand(_flattenTopics).firstWhere((item) => item.id == _topicId);
        if (topic.questionType == 'written') {
          final rawSets = decoded is Map && decoded['sets'] is List
              ? decoded['sets'] as List
              : decoded is List
                  ? decoded
                  : [decoded];
          var questionCount = 0;
          for (final rawSet in rawSets) {
            if (rawSet is! Map) throw const FormatException('প্রতিটি set JSON object হতে হবে');
            final set = Map<String, dynamic>.from(rawSet);
            final rawQuestions = set['questions'] is List
                ? set['questions'] as List
                : set.containsKey('question_text')
                    ? [set]
                    : const [];
            if (rawQuestions.isEmpty) throw const FormatException('প্রতিটি set-এ questions array দিন');
            final questions = rawQuestions.map((raw) {
              if (raw is! Map) throw const FormatException('প্রতিটি প্রশ্ন JSON object হতে হবে');
              return Map<String, dynamic>.from(raw);
            }).toList();
            await WrittenQuestionService(apiClient).createSet(
              topicId: _topicId!,
              format: (set['format'] ?? 'written').toString(),
              title: (set['title'] ?? set['question_set'] ?? _questionSetCtrl.text).toString(),
              stimulus: (set['stimulus'] ?? '').toString(),
              examType: (set['exam_type'] ?? _examTypeCtrl.text).toString(),
              questionSet: (set['question_set'] ?? _questionSetCtrl.text).toString(),
              previousYears: (set['previous_years'] as List<dynamic>? ?? _previousYears)
                  .map((year) => year.toString())
                  .toList(),
              difficultyLevel: (set['difficulty_level'] ?? _difficulty).toString(),
              source: (set['source'] ?? _sourceCtrl.text).toString(),
              questions: questions,
            );
            questionCount += questions.length;
          }
          if (mounted) {
            setState(() {
              _bulkJsonCtrl.clear();
              _success = '$questionCountটি Written প্রশ্ন upload হয়েছে';
            });
          }
          return;
        }
        final payload = decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : <String, dynamic>{'questions': decoded};
        final rawQuestions = payload['questions'];
        if (rawQuestions is! List) throw const FormatException('questions array দিন');
        final items = <Map<String, dynamic>>[];
        for (final item in rawQuestions) {
          if (item is! Map) {
            throw const FormatException('প্রতিটি item JSON object হতে হবে');
          }
          final question = Map<String, dynamic>.from(item);
          items.add(question);
        }
        final count = await QuestionService(apiClient).bulkCreate(
          topicId: _topicId!,
          questions: items,
          defaults: {
            'exam_type': (payload['exam_type'] ?? _examTypeCtrl.text).toString().trim(),
            'question_set': (payload['question_set'] ?? _questionSetCtrl.text).toString().trim(),
            'difficulty_level': _difficulty,
            'source': _sourceCtrl.text.trim().isEmpty
                ? 'bulk'
                : _sourceCtrl.text.trim(),
            'previous_years': _previousYears,
          },
        );
        setState(() {
          _bulkJsonCtrl.clear();
          _success = '$countটি প্রশ্ন সফলভাবে সংরক্ষিত হয়েছে';
        });
      } catch (e) {
        setState(() => _error = 'Bulk import ব্যর্থ: $e');
      } finally {
        if (mounted) setState(() => _saving = false);
    }
  }
}

class _WrittenDraft {
  final question = TextEditingController();
  final answer = TextEditingController();
  final marks = TextEditingController(text: '10');

  void dispose() {
    question.dispose();
    answer.dispose();
    marks.dispose();
  }
}