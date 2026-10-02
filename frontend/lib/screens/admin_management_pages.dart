import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import 'admin_exam_form.dart';
import 'admin_question_bank.dart';
import 'admin_question_form.dart';
import 'admin_topics.dart';

class AdminSectionShell extends StatelessWidget {
  const AdminSectionShell({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: child,
    );
  }
}

class AdminExamManagementPage extends ConsumerWidget {
  const AdminExamManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(topicsProvider);
    return AdminSectionShell(
      title: 'পরীক্ষা পরিচালনা',
      child: topics.when(
        data: (rows) => AdminExamForm(
          topics: rows,
          onCreated: () {},
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _AdminError(message: error.toString()),
      ),
    );
  }
}

class AdminQuestionBankPage extends ConsumerWidget {
  const AdminQuestionBankPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(topicsProvider);
    return AdminSectionShell(
      title: 'Question Bank পরিচালনা',
      child: topics.when(
        data: (rows) => AdminQuestionBank(topics: rows),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _AdminError(message: error.toString()),
      ),
    );
  }
}

class AdminResultsPage extends ConsumerStatefulWidget {
  const AdminResultsPage({super.key});

  @override
  ConsumerState<AdminResultsPage> createState() => _AdminResultsPageState();
}

class _AdminResultsPageState extends ConsumerState<AdminResultsPage> {
  String? _examId;
  late Future<List<Exam>> _exams;
  late Future<List<Map<String, dynamic>>> _results;

  @override
  void initState() {
    super.initState();
    _exams = ExamService(apiClient).list();
    _results = ExamService(apiClient).adminResults();
  }

  void _filter(String? value) {
    setState(() {
      _examId = value;
      _results = ExamService(apiClient).adminResults(examId: value);
    });
  }

  Future<void> _edit(Map<String, dynamic> row) async {
    final score = TextEditingController(text: row['score'].toString());
    final correct = TextEditingController(text: row['correct_count'].toString());
    final wrong = TextEditingController(text: row['wrong_count'].toString());
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exam result edit'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: score, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Score')),
          TextField(controller: correct, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Correct count')),
          TextField(controller: wrong, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Wrong count')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    await ExamService(apiClient).updateAdminResult(
      attemptId: row['id'] as String,
      score: double.parse(score.text),
      correctCount: int.parse(correct.text),
      wrongCount: int.parse(wrong.text),
    );
    setState(() => _results = ExamService(apiClient).adminResults(examId: _examId));
  }

  @override
  Widget build(BuildContext context) {
    return AdminSectionShell(
      title: 'Exam Result Manage & Edit',
      child: Column(children: [
        FutureBuilder<List<Exam>>(
          future: _exams,
          builder: (context, snapshot) => Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String?>(
              value: _examId,
              decoration: const InputDecoration(labelText: 'Filter by exam'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('All exams')),
                ...((snapshot.data ?? const <Exam>[]).map((exam) => DropdownMenuItem<String?>(value: exam.id, child: Text(exam.title)))),
              ],
              onChanged: _filter,
            ),
          ),
        ),
        Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _results,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return _AdminError(message: snapshot.error.toString());
            final rows = snapshot.data ?? const [];
            if (rows.isEmpty) return const _EmptyAdminState(text: 'কোনো exam result পাওয়া যায়নি।');
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                return Card(child: ListTile(
                  title: Text('${row['display_name'] ?? row['phone_number'] ?? 'Guest'} • ${row['exam_title']}'),
                  subtitle: Text('Score: ${row['score']}  |  Correct: ${row['correct_count']}  |  Wrong: ${row['wrong_count']}'),
                  trailing: IconButton(tooltip: 'Edit result', icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(row)),
                ));
              },
            );
          },
        )),
      ]),
    );
  }
}

class AdminMediaPage extends StatefulWidget {
  const AdminMediaPage({super.key});

  @override
  State<AdminMediaPage> createState() => _AdminMediaPageState();
}

class _AdminMediaPageState extends State<AdminMediaPage> {
  final _titleController = TextEditingController();
  final _imageController = TextEditingController();
  final _captionController = TextEditingController();
  final _items = <String>[];

  @override
  void dispose() {
    _titleController.dispose();
    _imageController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  void _share() {
    if (_titleController.text.trim().isEmpty ||
        _imageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('শিরোনাম ও ছবির লিংক দিন')),
      );
      return;
    }
    setState(() {
      _items.insert(0, '${_titleController.text.trim()}|${_imageController.text.trim()}|${_captionController.text.trim()}');
      _titleController.clear();
      _imageController.clear();
      _captionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminSectionShell(
      title: 'Photo & Share',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AdminIntro(icon: Icons.photo_library, text: 'ছবি, banner এবং announcement media share করুন।'),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'শিরোনাম')),
          const SizedBox(height: 12),
          TextField(controller: _imageController, decoration: const InputDecoration(labelText: 'ছবির URL')),
          const SizedBox(height: 12),
          TextField(controller: _captionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Caption')),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _share, icon: const Icon(Icons.share), label: const Text('Share করুন')),
          const SizedBox(height: 24),
          _AdminListTitle(title: 'Shared items', count: _items.length),
          if (_items.isEmpty) const _EmptyAdminState(text: 'এখনো কোনো media share করা হয়নি।'),
          for (final item in _items)
            Card(
              child: ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text(item.split('|')[0]),
                subtitle: Text(item.split('|').length > 2 ? item.split('|')[2] : item.split('|')[1]),
                trailing: IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _items.remove(item)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AdminMcqPage extends ConsumerWidget {
  const AdminMcqPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(topicsProvider);
    return AdminSectionShell(
      title: 'সব MCQ পরিচালনা',
      child: topics.when(
        data: (rows) => DefaultTabController(
          length: 3,
          child: Column(
            children: [
              const TabBar(tabs: [
                Tab(icon: Icon(Icons.list_alt), text: 'MCQ তালিকা'),
                Tab(icon: Icon(Icons.add_circle_outline), text: 'নতুন MCQ'),
                Tab(icon: Icon(Icons.account_tree), text: 'বিষয়সমূহ'),
              ]),
              Expanded(
                child: TabBarView(children: [
                  _McqListPanel(topics: rows),
                  AdminQuestionForm(topics: rows),
                  TopicsPanel(topics: rows, notifier: ref.read(topicsNotifierProvider.notifier)),
                ]),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _AdminError(message: error.toString()),
      ),
    );
  }
}

class _McqListPanel extends ConsumerStatefulWidget {
  const _McqListPanel({required this.topics});

  final List<TopicNode> topics;

  @override
  ConsumerState<_McqListPanel> createState() => _McqListPanelState();
}

class _McqListPanelState extends ConsumerState<_McqListPanel> {
  String? _selectedTopicId;

  List<({TopicNode topic, int depth})> _flattenTopics() {
    final result = <({TopicNode topic, int depth})>[];

    void walk(List<TopicNode> topics, int depth) {
      for (final topic in topics) {
        result.add((topic: topic, depth: depth));
        walk(topic.children, depth + 1);
      }
    }

    walk(widget.topics, 0);
    return result;
  }

  Set<String> _topicIdsIncludingChildren(TopicNode topic) {
    final ids = <String>{topic.id};
    for (final child in topic.children) {
      ids.addAll(_topicIdsIncludingChildren(child));
    }
    return ids;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: QuestionService(apiClient).list(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _AdminError(message: snapshot.error.toString());
        }
        final allRows = snapshot.data ?? const [];
        final topicRows = _flattenTopics();
        final selectedTopic = _selectedTopicId == null
            ? null
            : topicRows.where((row) => row.topic.id == _selectedTopicId).firstOrNull?.topic;
        final selectedIds = selectedTopic == null
            ? null
            : _topicIdsIncludingChildren(selectedTopic);
        final rows = selectedIds == null
            ? allRows
            : allRows.where((question) => selectedIds.contains(question.topicId)).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: DropdownButtonFormField<String?>(
                value: _selectedTopicId,
                decoration: const InputDecoration(
                  labelText: 'বিষয় অনুযায়ী MCQ filter করুন',
                  prefixIcon: Icon(Icons.filter_list),
                ),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('সব বিষয়')),
                  for (final row in topicRows)
                    DropdownMenuItem<String?>(
                      value: row.topic.id,
                      child: Text('${'  ' * row.depth}${row.topic.name}'),
                    ),
                ],
                onChanged: (value) => setState(() => _selectedTopicId = value),
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? const Center(child: Text('এই বিষয়ে কোনো MCQ পাওয়া যায়নি।'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: rows.length,
                      itemBuilder: (context, index) => Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(rows[index].questionText, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text('সঠিক উত্তর: ${rows[index].correctOption ?? '-'}'),
                          trailing: const Icon(Icons.edit_outlined),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _items = <String>[];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _publish() {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) return;
    setState(() {
      _items.insert(0, '${_titleController.text.trim()}|${_messageController.text.trim()}');
      _titleController.clear();
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminSectionShell(
      title: 'Notification পরিচালনা',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AdminIntro(icon: Icons.notifications_active, text: 'শিক্ষার্থীদের জন্য notice ও notification publish করুন।'),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Notification title')),
          const SizedBox(height: 12),
          TextField(controller: _messageController, maxLines: 4, decoration: const InputDecoration(labelText: 'Message')),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _publish, icon: const Icon(Icons.send), label: const Text('Publish notification')),
          const SizedBox(height: 24),
          _AdminListTitle(title: 'Published notifications', count: _items.length),
          if (_items.isEmpty) const _EmptyAdminState(text: 'এখনো কোনো notification publish করা হয়নি।'),
          for (final item in _items)
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_none),
                title: Text(item.split('|')[0]),
                subtitle: Text(item.split('|')[1]),
                trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _items.remove(item))),
              ),
            ),
        ],
      ),
    );
  }
}

class AdminMaterialsPage extends StatefulWidget {
  const AdminMaterialsPage({super.key});

  @override
  State<AdminMaterialsPage> createState() => _AdminMaterialsPageState();
}

class _AdminMaterialsPageState extends State<AdminMaterialsPage> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  String _type = 'Book';
  final _items = <String>[];

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _addMaterial() {
    if (_titleController.text.trim().isEmpty || _urlController.text.trim().isEmpty) return;
    setState(() {
      _items.insert(0, '$_type|${_titleController.text.trim()}|${_urlController.text.trim()}');
      _titleController.clear();
      _urlController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminSectionShell(
      title: 'Books, PDF & Materials',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AdminIntro(icon: Icons.menu_book, text: 'Book, PDF এবং study material-এর link manage করুন।'),
          DropdownButtonFormField<String>(value: _type, decoration: const InputDecoration(labelText: 'Material type'), items: const ['Book', 'PDF', 'Video', 'Note'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(), onChanged: (value) => setState(() => _type = value ?? _type)),
          const SizedBox(height: 12),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Material title')),
          const SizedBox(height: 12),
          TextField(controller: _urlController, decoration: const InputDecoration(labelText: 'File or link URL')),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _addMaterial, icon: const Icon(Icons.add_link), label: const Text('Add material')),
          const SizedBox(height: 24),
          _AdminListTitle(title: 'Materials', count: _items.length),
          if (_items.isEmpty) const _EmptyAdminState(text: 'এখনো কোনো material যোগ করা হয়নি।'),
          for (final item in _items)
            Card(
              child: ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(item.split('|')[1]),
                subtitle: Text('${item.split('|')[0]} • ${item.split('|')[2]}'),
                trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => _items.remove(item))),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminIntro extends StatelessWidget {
  const _AdminIntro({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 10), Expanded(child: Text(text))]),
      );
}

class _AdminListTitle extends StatelessWidget {
  const _AdminListTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: Theme.of(context).textTheme.titleMedium), Text('$count')]);
}

class _EmptyAdminState extends StatelessWidget {
  const _EmptyAdminState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 28), child: Center(child: Text(text)));
}

class _AdminError extends StatelessWidget {
  const _AdminError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('লোড করা যায়নি: $message')));
}
