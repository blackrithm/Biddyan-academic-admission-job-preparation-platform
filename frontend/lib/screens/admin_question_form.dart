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
  final _tagCtrl = TextEditingController();
  final _bulkJsonCtrl = TextEditingController();

  String? _topicId;
  String _correctOption = 'A';
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
    _tagCtrl.dispose();
    _bulkJsonCtrl.dispose();
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
                    const Text(
                      'নতুন MCQ প্রশ্ন যোগ করুন',
                      style: TextStyle(
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
                    TextField(
                      controller: _textCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'প্রশ্নের বর্ণনা',
                        hintText: 'প্রশ্নটি এখানে লিখুন...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final (i, label) in _bengaliLabels.indexed)
                      OptionField(
                        label: label,
                        controller: _optionCtrl(i),
                        isSelected: _correctOption == _optionKeys[i],
                        onPick: () =>
                            setState(() => _correctOption = _optionKeys[i]),
                      ),
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
                      'Bulk JSON import',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'একই নির্বাচিত বিভাগে একসাথে একাধিক MCQ যোগ করুন।',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _bulkJsonCtrl,
                      minLines: 4,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        hintText:
                            '[{"question_text":"...","option_a":"...","option_b":"...","option_c":"...","option_d":"...","correct_option":"A","explanation":"..."}]',
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _bulkImport,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('JSON থেকে সংরক্ষণ করুন'),
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
    final text = _textCtrl.text.trim();
    if (_topicId == null || text.isEmpty) {
      setState(() {
        _error = 'বিষয় ও প্রশ্নের বর্ণনা পূরণ করুন';
        _success = null;
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      await QuestionService(apiClient).create({
        'topic_id': _topicId,
        'question_text': text,
        'option_a': _aCtrl.text.trim(),
        'option_b': _bCtrl.text.trim(),
        'option_c': _cCtrl.text.trim(),
        'option_d': _dCtrl.text.trim(),
        'correct_option': _correctOption,
        'explanation': _explanationCtrl.text.trim(),
        'previous_years': _previousYears,
        'difficulty_level': 'medium',
      });
      setState(() {
        _success = 'প্রশ্ন সফলভাবে সংরক্ষিত হয়েছে';
        _textCtrl.clear();
        _aCtrl.clear();
        _bCtrl.clear();
        _cCtrl.clear();
        _dCtrl.clear();
        _explanationCtrl.clear();
        _previousYears.clear();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _bulkImport() async {
      if (_topicId == null) {
        setState(() => _error = 'প্রথমে বিভাগ নির্বাচন করুন');
        return;
      }
      try {
        final decoded = jsonDecode(_bulkJsonCtrl.text);
        if (decoded is! List) {
          throw const FormatException('JSON array দিন');
        }
        setState(() {
          _saving = true;
          _error = null;
          _success = null;
        });
        for (final item in decoded) {
          if (item is! Map) {
            throw const FormatException('প্রতিটি item JSON object হতে হবে');
          }
          final question = Map<String, dynamic>.from(item);
          question['topic_id'] = _topicId;
          await QuestionService(apiClient).create(question);
        }
        setState(() {
          _bulkJsonCtrl.clear();
          _success = '${decoded.length}টি প্রশ্ন সফলভাবে সংরক্ষিত হয়েছে';
        });
      } catch (e) {
        setState(() => _error = 'Bulk import ব্যর্থ: $e');
      } finally {
        if (mounted) setState(() => _saving = false);
    }
  }
}