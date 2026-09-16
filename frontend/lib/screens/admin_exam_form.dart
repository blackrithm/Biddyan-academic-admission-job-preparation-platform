import 'package:flutter/material.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';

class AdminExamForm extends StatefulWidget {
  const AdminExamForm({
    super.key,
    required this.topics,
    required this.onCreated,
  });

  final List<TopicNode> topics;
  final VoidCallback onCreated;

  @override
  State<AdminExamForm> createState() => _AdminExamFormState();
}

class _AdminExamFormState extends State<AdminExamForm> {
  final _title = TextEditingController();
  final _marks = TextEditingController(text: '50');
  final _passMark = TextEditingController(text: '20');
  final _negative = TextEditingController(text: '0.25');
  final _duration = TextEditingController(text: '60');
  final _questionSearch = TextEditingController();
  String? _topicId;
  String? _subtopicFilterId;
  String _searchQuery = '';
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _isLive = false;
  bool _loadingQuestions = false;
  bool _saving = false;
  String? _error;
  String? _success;
  List<Question> _questions = [];
  final _selected = <String>{};

  @override
  void dispose() {
    _title.dispose();
    _marks.dispose();
    _passMark.dispose();
    _negative.dispose();
    _duration.dispose();
    _questionSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flatTopics = <TopicNode>[];
    void flatten(List<TopicNode> nodes) {
      for (final node in nodes) {
        flatTopics.add(node);
        flatten(node.children);
      }
    }

    flatten(widget.topics);
    final uniqueTopics = <String, TopicNode>{
      for (final topic in flatTopics) topic.id: topic,
    }.values.toList();
    final selectedTopicId = uniqueTopics.any((topic) => topic.id == _topicId)
        ? _topicId
        : null;
    final selectedTopicIds = selectedTopicId == null
        ? <String>{}
        : _descendantTopicIds(widget.topics, selectedTopicId);
    final subtopics = selectedTopicId == null
        ? <TopicNode>[]
        : _collectSubtopics(widget.topics, selectedTopicId);
    final filteredQuestions = _questions.where((question) {
      final matchesTopic = selectedTopicIds.contains(question.topicId);
      final matchesSubtopic = _subtopicFilterId == null ||
          question.topicId == _subtopicFilterId;
      final haystack = '${question.questionText} ${question.topicName ?? ''} '
          '${question.examType ?? ''} ${question.questionSet ?? ''}'
          .toLowerCase();
      final matchesSearch =
          _searchQuery.isEmpty || haystack.contains(_searchQuery);
      return matchesTopic && matchesSubtopic && matchesSearch;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('নতুন পরীক্ষা তৈরি করুন',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'পরীক্ষার নাম'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedTopicId,
                  decoration: const InputDecoration(labelText: 'বিষয় / টপিক'),
                  items: [
                    for (final topic in uniqueTopics)
                      DropdownMenuItem(
                          value: topic.id, child: Text(topic.name)),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _topicId = value;
                      _subtopicFilterId = value;
                      _searchQuery = '';
                      _questionSearch.clear();
                      _selected.clear();
                    });
                    _loadQuestions(value);
                  },
                ),
                if (selectedTopicId != null && subtopics.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Quick subtopic filter',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('সব'),
                        selected: _subtopicFilterId == selectedTopicId,
                        onSelected: (_) => setState(() => _subtopicFilterId = selectedTopicId),
                      ),
                      for (final subtopic in subtopics)
                        ChoiceChip(
                          label: Text(subtopic.name),
                          selected: _subtopicFilterId == subtopic.id,
                          onSelected: (_) => setState(() => _subtopicFilterId = subtopic.id),
                        ),
                    ],
                  ),
                ],
                if (selectedTopicId != null) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _questionSearch,
                    onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      labelText: 'MCQ খুঁজুন',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _numberField(_marks, 'মোট মার্ক')),
                    const SizedBox(width: 10),
                    Expanded(child: _numberField(_negative, 'নেগেটিভ মার্ক')),
                  ],
                ),
                const SizedBox(height: 10),
                _numberField(_passMark, 'পাস মার্ক'),
                const SizedBox(height: 10),
                _numberField(_duration, 'সময় (মিনিট)'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Live exam হিসেবে প্রকাশ করুন'),
                  value: _isLive,
                  onChanged: (value) => setState(() => _isLive = value),
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pickDate(start: true),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_dateLabel(_startsAt, 'Start date')),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _pickDate(start: false),
                      icon: const Icon(Icons.event_available),
                      label: Text(_dateLabel(_endsAt, 'End date')),
                    ),
                  ],
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
                Row(
                  children: [
                    const Expanded(
                      child: Text('Database প্রশ্ন নির্বাচন',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    Text('${_selected.length} selected'),
                  ],
                ),
                const SizedBox(height: 8),
                if (_loadingQuestions)
                  const Center(child: CircularProgressIndicator())
                else if (_topicId == null)
                  const Text('প্রথমে একটি topic নির্বাচন করুন')
                else if (filteredQuestions.isEmpty)
                  const Text('এই topic/subtopic-এ কোনো প্রশ্ন পাওয়া যায়নি')
                else ...[
                  Text(
                    'প্রদর্শিত প্রশ্ন: ${filteredQuestions.length} / ${_questions.length}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  for (final question in filteredQuestions)
                    CheckboxListTile(
                      value: _selected.contains(question.id),
                      onChanged: (value) => setState(() {
                        if (value == true) {
                          _selected.add(question.id);
                        } else {
                          _selected.remove(question.id);
                        }
                      }),
                      title: Text(question.questionText),
                      subtitle: Text(
                        '${question.difficultyLevel} • ${question.topicName ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                ],
                const SizedBox(height: 10),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                if (_success != null)
                  Text(_success!, style: const TextStyle(color: Colors.green)),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save),
                  label:
                      Text(_saving ? 'সংরক্ষণ হচ্ছে...' : 'পরীক্ষা তৈরি করুন'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _numberField(TextEditingController controller, String label) =>
      TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      );

  Future<void> _loadQuestions(String? topicId) async {
    if (topicId == null) return;
    setState(() {
      _loadingQuestions = true;
      _error = null;
    });
    try {
      final questions = await QuestionService(apiClient).list(topicId: topicId);
      if (mounted) {
        setState(() {
          _questions = questions;
          _subtopicFilterId = topicId;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'প্রশ্ন লোড ব্যর্থ: $error');
    } finally {
      if (mounted) setState(() => _loadingQuestions = false);
    }
  }

  Set<String> _descendantTopicIds(List<TopicNode> roots, String rootId) {
    final ids = <String>{};

    void collectChildren(TopicNode node, Set<String> acc) {
      acc.add(node.id);
      for (final child in node.children) {
        collectChildren(child, acc);
      }
    }

    void visit(List<TopicNode> nodes) {
      for (final node in nodes) {
        if (node.id == rootId) {
          ids.add(node.id);
          for (final child in node.children) {
            collectChildren(child, ids);
          }
          return;
        }
        visit(node.children);
      }
    }

    visit(roots);
    return ids;
  }

  List<TopicNode> _collectSubtopics(List<TopicNode> roots, String rootId) {
    final matches = <TopicNode>[];
    void visit(List<TopicNode> nodes) {
      for (final node in nodes) {
        if (node.id == rootId) {
          matches.addAll(_flatten(node.children));
          return;
        }
        visit(node.children);
      }
    }

    visit(roots);
    return matches;
  }

  List<TopicNode> _flatten(List<TopicNode> nodes) {
    final flat = <TopicNode>[];
    for (final node in nodes) {
      flat.add(node);
      flat.addAll(_flatten(node.children));
    }
    return flat;
  }

  Future<void> _pickDate({required bool start}) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    setState(() {
      if (start) {
        _startsAt = date;
      } else {
        _endsAt = date;
      }
    });
  }

  String _dateLabel(DateTime? date, String fallback) =>
      date == null ? fallback : '${date.year}-${date.month}-${date.day}';

  Future<void> _save() async {
    final totalMarks = double.tryParse(_marks.text.trim());
    final passMark = double.tryParse(_passMark.text.trim());
    if (_title.text.trim().isEmpty || _topicId == null || _selected.isEmpty) {
      setState(
          () => _error = 'নাম, topic এবং কমপক্ষে একটি প্রশ্ন নির্বাচন করুন');
      return;
    }
    if (totalMarks == null || passMark == null || passMark < 0 || passMark > totalMarks) {
      setState(() => _error = 'পাস মার্ক ০ থেকে মোট মার্কের মধ্যে দিন');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      await ExamService(apiClient).create({
        'title': _title.text.trim(),
        'topicId': _topicId,
        'totalMarks': totalMarks,
        'passMark': passMark,
        'negativeMarking': double.parse(_negative.text.trim()),
        'duration': int.parse(_duration.text.trim()),
        'isLive': _isLive,
        'startsAt': _startsAt?.toIso8601String(),
        'endsAt': _endsAt?.toIso8601String(),
        'questionIds': _selected.toList(),
      });
      if (mounted) {
        widget.onCreated();
        setState(() => _success = 'পরীক্ষা সফলভাবে তৈরি হয়েছে');
        _selected.clear();
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'পরীক্ষা তৈরি ব্যর্থ: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
