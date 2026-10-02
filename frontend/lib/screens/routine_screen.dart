import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/brand_navigation.dart';
import 'mobile_dashboard.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  final _categories = const ['সবগুলো', 'Academic', 'Admission', 'BCS & Jobs', 'Bank Job'];
  String _selectedCategory = 'সবগুলো';
  late List<_RoutineTask> _tasks = [
    _RoutineTask(
      title: 'English grammar revision',
      category: 'BCS & Jobs',
      subject: 'English',
      minutes: 45,
      date: DateTime.now(),
      note: 'Tense ও subject-verb agreement',
    ),
    _RoutineTask(
      title: 'গণিতের ২০টি MCQ',
      category: 'Academic',
      subject: 'গণিত',
      minutes: 35,
      date: DateTime.now(),
      note: 'ভুল প্রশ্নগুলো আলাদা করে রাখব',
    ),
    _RoutineTask(
      title: 'BCS বাংলা মডেল টেস্ট',
      category: 'BCS & Jobs',
      subject: 'বাংলা',
      minutes: 60,
      date: DateTime.now().add(const Duration(days: 1)),
      note: 'রাত ৮টার পরে শুরু করব',
    ),
  ];

  bool get _canPersist => apiClient.authToken?.contains('.') ?? false;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    if (!_canPersist) return;
    try {
      final plans = await RoutineService(apiClient).list();
      if (!mounted) return;
      setState(() => _tasks = plans.map(_fromPlan).toList());
    } catch (_) {}
  }

  _RoutineTask _fromPlan(RoutinePlan plan) => _RoutineTask(
        id: plan.id,
        title: plan.title,
        category: plan.category,
        subject: plan.subject,
        minutes: plan.minutes,
        date: plan.date,
        note: plan.note,
        done: plan.done,
      );

  @override
  Widget build(BuildContext context) {
    final visibleTasks = _tasks.where((task) {
      return _selectedCategory == 'সবগুলো' || task.category == _selectedCategory;
    }).toList();
    final today = visibleTasks.where((task) => _isToday(task.date)).toList();
    final upcoming = visibleTasks.where((task) => !_isToday(task.date)).toList();
    final completed = visibleTasks.where((task) => task.done).length;
    final totalMinutes = today.fold<int>(0, (sum, task) => sum + task.minutes);
    final completedMinutes = today
        .where((task) => task.done)
        .fold<int>(0, (sum, task) => sum + task.minutes);
    final progress = totalMinutes == 0 ? 0.0 : completedMinutes / totalMinutes;

    return Scaffold(
      backgroundColor: AppConstants.background,
      drawer: const DashboardDrawer(),
      appBar: const BrandHeader(),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: ListView(
              padding: EdgeInsets.fromLTRB(constraints.maxWidth > 700 ? 24 : 14, 8, constraints.maxWidth > 700 ? 24 : 14, 28),
              children: [
                _RoutineHero(
                  progress: progress,
                  completed: completed,
                  total: visibleTasks.length,
                  totalMinutes: totalMinutes,
                ),
                const SizedBox(height: 16),
                const Text('Preparation type অনুযায়ী পরিকল্পনা', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return ChoiceChip(
                        label: Text(category),
                        selected: category == _selectedCategory,
                        onSelected: (_) => setState(() => _selectedCategory = category),
                        selectedColor: AppConstants.primary,
                        labelStyle: TextStyle(
                          color: category == _selectedCategory ? Colors.white : AppConstants.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        side: const BorderSide(color: Color(0xFFD5E5E5)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _SectionTitle(title: 'আজকের পড়াশোনা', trailing: '$totalMinutes মিনিট'),
                const SizedBox(height: 10),
                if (today.isEmpty)
                  const _EmptyRoutine(text: 'আজকের জন্য এখনো কোনো task যোগ করা হয়নি।')
                else
                  for (final task in today) _RoutineTaskCard(task: task, onChanged: _toggleTask, onEdit: _openTaskEditor, onDelete: _deleteTask),
                const SizedBox(height: 20),
                _SectionTitle(title: 'সামনের পরিকল্পনা', trailing: '${upcoming.length}টি task'),
                const SizedBox(height: 10),
                if (upcoming.isEmpty)
                  const _EmptyRoutine(text: 'ভবিষ্যতের জন্য একটি study plan যোগ করুন।')
                else
                  for (final task in upcoming) _RoutineTaskCard(task: task, onChanged: _toggleTask, onEdit: _openTaskEditor, onDelete: _deleteTask),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _openTaskEditor(context),
                  icon: const Icon(Icons.add),
                  label: const Text('নতুন study plan যোগ করুন'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BrandBottomNavigation(
        selectedIndex: 3,
        onSelected: (index) => BrandBottomNavigation.navigate(context, index),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Future<void> _toggleTask(_RoutineTask task, bool value) async {
    setState(() => task.done = value);
    if (_canPersist && task.id != null) {
      try {
        await RoutineService(apiClient).update(task.id!, {'completed': value});
      } catch (_) {}
    }
  }

  Future<void> _deleteTask(_RoutineTask task) async {
    setState(() => _tasks.remove(task));
    if (_canPersist && task.id != null) {
      try {
        await RoutineService(apiClient).remove(task.id!);
      } catch (_) {}
    }
  }

  Future<void> _openTaskEditor(BuildContext context, [_RoutineTask? existing]) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final noteController = TextEditingController(text: existing?.note ?? '');
    final minutesController = TextEditingController(text: '${existing?.minutes ?? 30}');
    var category = existing?.category ?? 'Academic';
    var subject = existing?.subject ?? 'সাধারণ';
    var date = existing?.date ?? DateTime.now();
    final result = await showDialog<_RoutineTask>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Study plan যোগ করুন' : 'Study plan সম্পাদনা'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'কী পড়বেন?')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Preparation type'),
                  items: _categories.skip(1).map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                  onChanged: (value) => setDialogState(() => category = value ?? category),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: subject,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  items: const ['সাধারণ', 'বাংলা', 'English', 'গণিত', 'বিজ্ঞান', 'সাধারণ জ্ঞান']
                      .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => subject = value ?? subject),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: minutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'কত মিনিট পড়বেন?', suffixText: 'min'),
                ),
                const SizedBox(height: 4),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(_dateLabel(date)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: date.isBefore(DateTime.now()) ? DateTime.now() : date,
                    );
                    if (picked != null) setDialogState(() => date = picked);
                  },
                ),
                TextField(controller: noteController, maxLines: 2, decoration: const InputDecoration(labelText: 'ছোট note (ঐচ্ছিক)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('বাতিল')),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                final minutes = int.tryParse(minutesController.text.trim()) ?? 30;
                if (title.isEmpty) return;
                Navigator.pop(dialogContext, _RoutineTask(title: title, category: category, subject: subject, minutes: minutes.clamp(5, 600), date: date, note: noteController.text.trim(), done: existing?.done ?? false));
              },
              child: const Text('সংরক্ষণ'),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    noteController.dispose();
    minutesController.dispose();
    if (result == null || !mounted) return;
    if (_canPersist) {
      try {
        final service = RoutineService(apiClient);
        if (existing == null) {
          final saved = await service.create(
            title: result.title,
            category: result.category,
            subject: result.subject,
            minutes: result.minutes,
            date: result.date,
            note: result.note,
          );
          result.id = saved.id;
        } else if (existing.id != null) {
          final saved = await service.update(existing.id!, {
            'title': result.title,
            'category': result.category,
            'subject': result.subject,
            'durationMinutes': result.minutes,
            'scheduledDate': _dateOnly(result.date),
            'note': result.note,
            'completed': result.done,
          });
          result.id = saved.id;
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      if (existing == null) {
        _tasks.add(result);
      } else {
        final index = _tasks.indexOf(existing);
        if (index != -1) _tasks[index] = result;
      }
    });
  }

  String _dateLabel(DateTime date) => _isToday(date) ? 'আজ, ${date.day}/${date.month}' : '${date.day}/${date.month}/${date.year}';

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _RoutineTask {
  _RoutineTask({this.id, required this.title, required this.category, required this.subject, required this.minutes, required this.date, required this.note, this.done = false});

  String? id;
  final String title;
  final String category;
  final String subject;
  final int minutes;
  final DateTime date;
  final String note;
  bool done;
}

class _RoutineHero extends StatelessWidget {
  const _RoutineHero({required this.progress, required this.completed, required this.total, required this.totalMinutes});

  final double progress;
  final int completed;
  final int total;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppConstants.primary, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('আজকের focus', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800))),
            Text('${(progress * 100).round()}%', style: const TextStyle(color: Color(0xFFFFD166), fontSize: 21, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: const Color(0x4466AAA8), valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD166)))),
          const SizedBox(height: 10),
          Text('$completed/$total task complete • আজ $totalMinutes মিনিটের plan', style: const TextStyle(color: Colors.white70)),
        ]),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});
  final String title;
  final String trailing;
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))), Text(trailing, style: const TextStyle(color: AppConstants.mutedText, fontWeight: FontWeight.w700))]);
}

class _RoutineTaskCard extends StatelessWidget {
  const _RoutineTaskCard({required this.task, required this.onChanged, required this.onEdit, required this.onDelete});
  final _RoutineTask task;
  final void Function(_RoutineTask, bool) onChanged;
  final Future<void> Function(BuildContext, _RoutineTask) onEdit;
  final void Function(_RoutineTask) onDelete;
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [Checkbox(value: task.done, onChanged: (value) => onChanged(task, value ?? false)), const SizedBox(width: 4), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, decoration: task.done ? TextDecoration.lineThrough : null)), const SizedBox(height: 5), Wrap(spacing: 8, children: [Text(task.subject, style: const TextStyle(color: AppConstants.primary, fontWeight: FontWeight.w700)), Text('${task.minutes} মিনিট', style: const TextStyle(color: AppConstants.mutedText))]), if (task.note.isNotEmpty) Text(task.note, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppConstants.mutedText, fontSize: 12))])), PopupMenuButton<String>(onSelected: (value) { if (value == 'edit') onEdit(context, task); if (value == 'delete') onDelete(task); }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete'))])])));
}

class _EmptyRoutine extends StatelessWidget {
  const _EmptyRoutine({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [const Icon(Icons.event_note_outlined, color: AppConstants.primary), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(color: AppConstants.mutedText)))])));
}