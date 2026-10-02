import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/brand_navigation.dart';

const _dashboardExamTypes = <String>[
  'SSC',
  'HSC',
  'Varsity',
  'Medical',
  'Engineering',
  'Agriculture',
  'BCS প্রস্তুতি',
  'শিক্ষক নিবন্ধন',
  'বার কাউন্সিল',
  'ব্যাংক জব',
  'সরকারি চাকরি',
  'নন-ক্যাডার',
];

List<String> _examTypesFromTopics(List<TopicNode> topics) {
  final examTypes = [..._dashboardExamTypes];
  for (final root in topics) {
    for (final topic in root.children) {
      final name = switch (topic.name) {
        'BCS' => 'BCS প্রস্তুতি',
        'Bank' => 'ব্যাংক জব',
        _ => topic.name,
      };
      if (!examTypes.contains(name)) examTypes.add(name);
    }
  }
  return examTypes;
}

String _filterTypeLabel(String value) => switch (value.trim()) {
      'BCS' => 'BCS প্রস্তুতি',
      'Bank' => 'ব্যাংক জব',
      'বিশ্ববিদ্যালয় ভর্তি' => 'Varsity',
      'মেডিকেল ভর্তি' => 'Medical',
      'ইঞ্জিনিয়ারিং ভর্তি' => 'Engineering',
      'SSC / HSC' => 'SSC',
      _ => value.trim(),
    };

List<String> _batchFilterTypes(
  List<TopicNode> topics,
  List<Map<String, dynamic>> batches,
) {
  final types = <String>{
    for (final type in _examTypesFromTopics(topics)) _filterTypeLabel(type),
  };
  for (final batch in batches) {
    final type = _filterTypeLabel(batch['exam_type']?.toString() ?? '');
    if (type.isNotEmpty) types.add(type);
  }
  return ['সব', ...types];
}

bool _matchesBatchType(Map<String, dynamic> batch, String selectedType) {
  if (selectedType == 'সব') return true;
  final type = batch['exam_type']?.toString().trim() ?? '';
  if (type == 'SSC / HSC' && selectedType == 'HSC') return true;
  return _filterTypeLabel(type) == selectedType;
}

const _batchQuestionTypes = ['সব', 'MCQ', 'Written'];

bool _matchesQuestionType(Map<String, dynamic> batch, String selectedType) {
  if (selectedType == 'সব') return true;
  final expected = selectedType.toLowerCase();
  final batchTypes = batch['question_types'];
  return batchTypes is Iterable &&
      batchTypes.any((type) => type.toString().toLowerCase() == expected);
}

class ExamBatchesScreen extends ConsumerStatefulWidget {
  const ExamBatchesScreen({super.key});

  @override
  ConsumerState<ExamBatchesScreen> createState() => _ExamBatchesScreenState();
}

class _ExamBatchesScreenState extends ConsumerState<ExamBatchesScreen> {
  late Future<List<Map<String, dynamic>>> _batches;
  late Future<List<TopicNode>> _topics;
  String _selectedExamType = 'সব';
  String _selectedQuestionType = 'সব';

  @override
  void initState() {
    super.initState();
    _batches = ExamService(apiClient).batchList();
    _topics = TopicService(apiClient).getTree();
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(authNotifierProvider).user != null;
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(title: const Text('এক্সাম ব্যাচ')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _batches,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
              final batches = snapshot.data ?? const [];
              if (batches.isEmpty) {
                return const Center(child: Text('এখনো কোনো এক্সাম ব্যাচ প্রকাশ করা হয়নি।'));
              }
              return FutureBuilder<List<TopicNode>>(
                future: _topics,
                builder: (context, topicSnapshot) {
                  if (topicSnapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final types = _batchFilterTypes(
                    topicSnapshot.data ?? const [],
                    batches,
                  );
                  final questionTypes = _batchQuestionTypes;
                  final filteredBatches = batches
                      .where((batch) =>
                          _matchesBatchType(batch, _selectedExamType) &&
                          _matchesQuestionType(batch, _selectedQuestionType))
                      .toList();
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ব্যাচ খুঁজুন',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                const Text('বিষয় ও প্রশ্নের ধরন বেছে নিন'),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppConstants.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${filteredBatches.length}টি ব্যাচ',
                              style: const TextStyle(color: AppConstants.primary, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _BatchFilterPanel(
                        topicTypes: types,
                        questionTypes: questionTypes,
                        selectedTopicType: _selectedExamType,
                        selectedQuestionType: _selectedQuestionType,
                        resultCount: filteredBatches.length,
                        onTopicSelected: (type) => setState(() => _selectedExamType = type),
                        onQuestionTypeSelected: (type) => setState(() => _selectedQuestionType = type),
                      ),
                      const SizedBox(height: 16),
                      if (filteredBatches.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          decoration: BoxDecoration(
                            color: AppConstants.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E9E8)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.manage_search, size: 34, color: AppConstants.mutedText.withValues(alpha: 0.8)),
                              const SizedBox(height: 10),
                              const Text('এই ফিল্টারে কোনো ব্যাচ পাওয়া যায়নি', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              const Text('অন্য বিষয় বা প্রশ্নের ধরন বেছে দেখুন।', textAlign: TextAlign.center),
                              if (_selectedExamType != 'সব' || _selectedQuestionType != 'সব') ...[
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: () => setState(() {
                                    _selectedExamType = 'সব';
                                    _selectedQuestionType = 'সব';
                                  }),
                                  icon: const Icon(Icons.restart_alt),
                                  label: const Text('ফিল্টার মুছুন'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      for (final batch in filteredBatches)
                        _PublicBatchCard(
                          batch: batch,
                          onTap: () => context.push('/exam-batches/${batch['id']}'),
                        ),
                      if (!signedIn)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/account'),
                            icon: const Icon(Icons.login),
                            label: const Text('ফ্রি enrollment করতে sign in করুন'),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BrandBottomNavigation(
        selectedIndex: 2,
        onSelected: (index) => BrandBottomNavigation.navigate(context, index),
      ),
    );
  }
}

class ExamBatchDetailScreen extends ConsumerStatefulWidget {
  const ExamBatchDetailScreen({super.key, required this.batchId, this.autoEnroll = false});

  final String batchId;
  final bool autoEnroll;

  @override
  ConsumerState<ExamBatchDetailScreen> createState() => _ExamBatchDetailScreenState();
}

class _ExamBatchDetailScreenState extends ConsumerState<ExamBatchDetailScreen> {
  late Future<Map<String, dynamic>> _details;
  bool _enrolling = false;

  @override
  void initState() {
    super.initState();
    _details = ExamService(apiClient).batchDetails(widget.batchId);
    if (widget.autoEnroll) {
      _autoEnrollWhenLoaded();
    }
  }

  Future<void> _autoEnrollWhenLoaded() async {
    try {
      final batch = await _details;
      if (batch['is_enrolled'] != true && mounted) await _enroll();
    } catch (_) {}
  }

  Future<void> _enroll() async {
    if (ref.read(authNotifierProvider).user == null) {
      final destination = Uri.encodeComponent('/exam-batches/${widget.batchId}?enroll=1');
      await context.push('/account?redirect=$destination');
      return;
    }
    setState(() => _enrolling = true);
    try {
      await ExamService(apiClient).enrollInBatch(widget.batchId);
      setState(() => _details = ExamService(apiClient).batchDetails(widget.batchId));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _enrolling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(title: const Text('ব্যাচের পরীক্ষা')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _details,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
          final batch = snapshot.data!;
          final enrolled = batch['is_enrolled'] == true;
          final exams = (batch['exams'] as List<dynamic>? ?? const [])
              .map((item) => Map<String, dynamic>.from(item as Map)).toList();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if ((batch['image_url'] as String? ?? '').isNotEmpty) ...[
                    _BatchImage(
                      imageUrl: batch['image_url'] as String?,
                      width: double.infinity,
                      height: 180,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(batch['name'] as String? ?? '', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('${batch['exam_type'] ?? ''}  •  ${batch['enrolled_count'] ?? 0} জন শিক্ষার্থী'),
                  if ((batch['description'] as String? ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(batch['description'] as String),
                  ],
                  const SizedBox(height: 16),
                  if (!enrolled)
                    FilledButton.icon(
                      onPressed: _enrolling ? null : _enroll,
                      icon: _enrolling ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add),
                      label: const Text('বিনামূল্যে ব্যাচে যোগ দিন'),
                    )
                  else
                    const Chip(avatar: Icon(Icons.verified, size: 18), label: Text('আপনি এই ব্যাচে enrolled')),
                  const SizedBox(height: 20),
                  Text('ব্যাচের পরীক্ষাসমূহ', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  if (exams.isEmpty) const Text('এই ব্যাচে এখনো কোনো পরীক্ষা যোগ করা হয়নি।'),
                  for (final exam in exams) _BatchExamTile(exam: exam, enrolled: enrolled),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BrandBottomNavigation(
        selectedIndex: 2,
        onSelected: (index) => BrandBottomNavigation.navigate(context, index),
      ),
    );
  }
}

class _BatchExamTile extends StatelessWidget {
  const _BatchExamTile({required this.exam, required this.enrolled});

  final Map<String, dynamic> exam;
  final bool enrolled;

  @override
  Widget build(BuildContext context) {
    final startsAt = DateTime.parse(exam['starts_at'] as String).toLocal();
    final endsAt = DateTime.parse(exam['ends_at'] as String).toLocal();
    final now = DateTime.now();
    final live = !now.isBefore(startsAt) && now.isBefore(endsAt);
    final state = now.isBefore(startsAt) ? 'আসন্ন' : live ? 'এখন চলছে' : 'সময় শেষ';
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        title: Text(exam['title'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${_formatDate(startsAt)}  •  ${exam['duration_minutes']} মিনিট  •  ${exam['question_count']} প্রশ্ন\n$state'),
        isThreeLine: true,
        trailing: live && enrolled
            ? FilledButton(onPressed: () => context.push('/exam/${exam['id']}'), child: const Text('পরীক্ষা দিন'))
            : const Icon(Icons.schedule),
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

class AdminExamBatchesScreen extends StatefulWidget {
  const AdminExamBatchesScreen({super.key});

  @override
  State<AdminExamBatchesScreen> createState() => _AdminExamBatchesScreenState();
}

class _AdminExamBatchesScreenState extends State<AdminExamBatchesScreen> {
  late Future<List<Map<String, dynamic>>> _batches;
  late Future<List<Exam>> _exams;
  late Future<List<TopicNode>> _topics;
  List<Map<String, dynamic>>? _orderedBatches;
  String _selectedExamType = 'সব';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _orderedBatches = null;
    _batches = ExamService(apiClient).batchList();
    _exams = ExamService(apiClient).list();
    _topics = TopicService(apiClient).getTree();
  }

  Future<void> _createBatch() async {
    final exams = await _exams;
    final examTypes = _examTypesFromTopics(await _topics);
    if (!mounted) return;
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => _CreateExamBatchDialog(exams: exams, examTypes: examTypes),
    );
    if (created == true && mounted) setState(_load);
  }

  Future<void> _editBatch(
    Map<String, dynamic> batch,
    List<Exam> exams,
    List<String> examTypes,
  ) async {
    try {
      final batchId = batch['id'].toString();
      final details = await ExamService(apiClient).batchDetails(batchId);
      final types = [...examTypes];
      final existingType = details['exam_type']?.toString() ?? '';
      if (existingType.isNotEmpty && !types.contains(existingType)) {
        types.add(existingType);
      }
      if (!mounted) return;
      final updated = await showDialog<bool>(
        context: context,
        builder: (context) => _CreateExamBatchDialog(
          exams: exams,
          examTypes: types,
          initialBatch: details,
        ),
      );
      if (updated == true && mounted) setState(_load);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ব্যাচের তথ্য লোড করা যায়নি: $error')),
        );
      }
    }
  }

  Future<void> _reorderBatches(
    List<Map<String, dynamic>> batches,
    List<Map<String, dynamic>> visibleBatches,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final reorderedVisible = [...visibleBatches];
    final movedBatch = reorderedVisible.removeAt(oldIndex);
    reorderedVisible.insert(newIndex, movedBatch);
    final visibleIds = reorderedVisible.map((batch) => batch['id'].toString()).toSet();
    final positions = <int>[
      for (var index = 0; index < batches.length; index++)
        if (visibleIds.contains(batches[index]['id'].toString())) index,
    ];
    final reorderedAll = [...batches];
    for (var index = 0; index < positions.length; index++) {
      reorderedAll[positions[index]] = reorderedVisible[index];
    }
    setState(() => _orderedBatches = reorderedAll);

    try {
      await ExamService(apiClient).reorderBatches(
        reorderedAll.map((batch) => batch['id'].toString()).toList(),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _orderedBatches = batches);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('সাজানো সংরক্ষণ করা যায়নি: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('এক্সাম ব্যাচ পরিচালনা')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _batches,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
            final batches = _orderedBatches ?? snapshot.data ?? const [];
            return FutureBuilder<List<TopicNode>>(
              future: _topics,
              builder: (context, topicSnapshot) {
                if (topicSnapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                return FutureBuilder<List<Exam>>(
                  future: _exams,
                  builder: (context, examSnapshot) {
                    if (examSnapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final examTypes = _batchFilterTypes(
                      topicSnapshot.data ?? const [],
                      batches,
                    );
                    final filtered = batches
                        .where((batch) => _matchesBatchType(batch, _selectedExamType))
                        .toList();
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: _createBatch,
                              icon: const Icon(Icons.add),
                              label: const Text('নতুন ব্যাচ'),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 42,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final type in examTypes)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(type),
                                    selected: _selectedExamType == type,
                                    onSelected: (_) => setState(() => _selectedExamType = type),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: batches.isEmpty
                              ? const Center(child: Text('কোনো exam batch তৈরি হয়নি।'))
                              : filtered.isEmpty
                                  ? const Center(child: Text('এই ধরনের কোনো exam batch নেই।'))
                                  : ReorderableListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      buildDefaultDragHandles: false,
                                      itemCount: filtered.length,
                                      onReorder: (oldIndex, newIndex) => _reorderBatches(
                                        batches,
                                        filtered,
                                        oldIndex,
                                        newIndex,
                                      ),
                                      itemBuilder: (context, index) {
                                        final batch = filtered[index];
                                        return Card(
                                          key: ValueKey(batch['id'].toString()),
                                          margin: const EdgeInsets.only(bottom: 10),
                                          child: ListTile(
                                            leading: _BatchImage(imageUrl: batch['image_url'] as String?),
                                            title: Text(batch['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                                            subtitle: Text('${batch['exam_type'] ?? ''}  •  ${batch['exam_count'] ?? 0}টি পরীক্ষা  •  ${batch['enrolled_count'] ?? 0} জন enrolled'),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  tooltip: 'সম্পাদনা',
                                                  onPressed: () => _editBatch(
                                                    batch,
                                                    examSnapshot.data ?? const [],
                                                    examTypes.skip(1).toList(),
                                                  ),
                                                  icon: const Icon(Icons.edit_outlined),
                                                ),
                                                ReorderableDragStartListener(
                                                  index: index,
                                                  child: const Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                                    child: Icon(Icons.drag_handle),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      );
}

class _CreateExamBatchDialog extends StatefulWidget {
  const _CreateExamBatchDialog({
    required this.exams,
    required this.examTypes,
    this.initialBatch,
  });

  final List<Exam> exams;
  final List<String> examTypes;
  final Map<String, dynamic>? initialBatch;

  @override
  State<_CreateExamBatchDialog> createState() => _CreateExamBatchDialogState();
}

class _CreateExamBatchDialogState extends State<_CreateExamBatchDialog> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _type = _dashboardExamTypes.first;
  Exam? _selectedExam;
  DateTime _scheduledAt = DateTime.now().add(const Duration(days: 1));
  final List<Map<String, String>> _scheduledExams = [];
  String? _imageUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final batch = widget.initialBatch;
    if (batch == null) return;
    _name.text = batch['name'] as String? ?? '';
    _description.text = batch['description'] as String? ?? '';
    _type = batch['exam_type'] as String? ?? _type;
    _imageUrl = batch['image_url'] as String?;
    for (final item in batch['exams'] as List<dynamic>? ?? const []) {
      final exam = Map<String, dynamic>.from(item as Map);
      final examId = (exam['id'] ?? exam['exam_id'])?.toString() ?? '';
      final startsAt = exam['starts_at']?.toString() ?? '';
      if (examId.isNotEmpty && startsAt.isNotEmpty) {
        _scheduledExams.add({'examId': examId, 'startsAt': startsAt});
      }
    }
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 900,
      imageQuality: 75,
    );
    if (image == null || !mounted) return;
    try {
      final bytes = await image.readAsBytes();
      final extension = image.name.split('.').last.toLowerCase();
      final mimeType = switch (extension) {
        'png' => 'png',
        'webp' => 'webp',
        'gif' => 'gif',
        _ => 'jpeg',
      };
      setState(() => _imageUrl = 'data:image/$mimeType;base64,${base64Encode(bytes)}');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ছবি লোড করা যায়নি: $error')),
        );
      }
    }
  }

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_scheduledAt));
    if (time == null) return;
    setState(() => _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _scheduledExams.isEmpty) return;
    setState(() => _saving = true);
    try {
      final service = ExamService(apiClient);
      final values = {
        'name': _name.text.trim(),
        'examType': _type,
        'description': _description.text.trim(),
        'imageUrl': _imageUrl,
        'exams': _scheduledExams,
      };
      final existingBatch = widget.initialBatch;
      if (existingBatch == null) {
        await service.createBatch(
          name: values['name']! as String,
          examType: values['examType']! as String,
          description: values['description']! as String,
          imageUrl: values['imageUrl'] as String?,
          exams: values['exams']! as List<Map<String, String>>,
        );
      } else {
        await service.updateBatch(
          batchId: existingBatch['id'].toString(),
          name: values['name']! as String,
          examType: values['examType']! as String,
          description: values['description']! as String,
          imageUrl: values['imageUrl'] as String?,
          exams: values['exams']! as List<Map<String, String>>,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.initialBatch == null ? 'নতুন exam batch' : 'ব্যাচ সম্পাদনা'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(controller: _name, decoration: const InputDecoration(labelText: 'ব্যাচের নাম')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _BatchImage(imageUrl: _imageUrl, width: 84, height: 68),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _saving ? null : _pickImage,
                            icon: const Icon(Icons.image_outlined),
                            label: Text(_imageUrl == null ? 'ছবি আপলোড করুন' : 'ছবি পরিবর্তন করুন'),
                          ),
                          if (_imageUrl != null)
                            TextButton.icon(
                              onPressed: _saving ? null : () => setState(() => _imageUrl = null),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('ছবি সরান'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'পরীক্ষার ধরন'),
                  items: [for (final type in widget.examTypes) DropdownMenuItem(value: type, child: Text(type))],
                  onChanged: (value) => setState(() => _type = value ?? widget.examTypes.first),
                ),
                const SizedBox(height: 10),
                TextField(controller: _description, maxLines: 2, decoration: const InputDecoration(labelText: 'বর্ণনা')),
                const Divider(height: 28),
                DropdownButtonFormField<Exam>(
                  value: _selectedExam,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'ব্যাচে পরীক্ষা যোগ করুন'),
                  items: [
                    for (final exam in widget.exams.where((exam) => !_scheduledExams.any((item) => item['examId'] == exam.id)))
                      DropdownMenuItem(value: exam, child: Text(exam.title, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (value) => setState(() => _selectedExam = value),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: _pickSchedule, icon: const Icon(Icons.calendar_month), label: Text(_formatDate(_scheduledAt))),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _selectedExam == null ? null : () {
                      setState(() {
                        _scheduledExams.add({'examId': _selectedExam!.id, 'startsAt': _scheduledAt.toUtc().toIso8601String()});
                        _selectedExam = null;
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('তালিকায় যোগ করুন'),
                  ),
                ),
                for (var index = 0; index < _scheduledExams.length; index++)
                  ListTile(
                    dense: true,
                    title: Text(widget.exams.firstWhere((exam) => exam.id == _scheduledExams[index]['examId']).title),
                    subtitle: Text(_formatDate(DateTime.parse(_scheduledExams[index]['startsAt']!).toLocal())),
                    trailing: IconButton(tooltip: 'সরান', onPressed: () => setState(() => _scheduledExams.removeAt(index)), icon: const Icon(Icons.close)),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('বাতিল')),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(widget.initialBatch == null ? 'ব্যাচ তৈরি করুন' : 'পরিবর্তন সংরক্ষণ'),
          ),
        ],
      );
}

class _BatchFilterPanel extends StatelessWidget {
  const _BatchFilterPanel({
    required this.topicTypes,
    required this.questionTypes,
    required this.selectedTopicType,
    required this.selectedQuestionType,
    required this.resultCount,
    required this.onTopicSelected,
    required this.onQuestionTypeSelected,
  });

  final List<String> topicTypes;
  final List<String> questionTypes;
  final String selectedTopicType;
  final String selectedQuestionType;
  final int resultCount;
  final ValueChanged<String> onTopicSelected;
  final ValueChanged<String> onQuestionTypeSelected;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppConstants.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E8E7)),
          boxShadow: const [
            BoxShadow(color: Color(0x0800343A), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, size: 18, color: AppConstants.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('ফিল্টার', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                Text(
                  '$resultCountটি ফলাফল',
                  style: const TextStyle(color: AppConstants.mutedText, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _BatchFilterGroup(
              icon: Icons.category_outlined,
              title: 'বিষয়',
              options: topicTypes,
              selected: selectedTopicType,
              onSelected: onTopicSelected,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFE9EEED)),
            ),
            _BatchFilterGroup(
              icon: Icons.quiz_outlined,
              title: 'প্রশ্নের ধরন',
              options: questionTypes,
              selected: selectedQuestionType,
              onSelected: onQuestionTypeSelected,
            ),
          ],
        ),
      );
}

class _BatchFilterGroup extends StatelessWidget {
  const _BatchFilterGroup({
    required this.icon,
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final IconData icon;
  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppConstants.mutedText),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final option in options)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(option),
                      selected: selected == option,
                      onSelected: (_) => onSelected(option),
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: selected == option ? AppConstants.primary : AppConstants.mutedText,
                        fontWeight: selected == option ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                      selectedColor: const Color(0xFFDCEDEC),
                      backgroundColor: const Color(0xFFF4F7F6),
                      side: BorderSide(
                        color: selected == option ? const Color(0xFFB9D7D4) : const Color(0xFFE3EAE9),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
}

class _PublicBatchCard extends StatelessWidget {
  const _PublicBatchCard({required this.batch, required this.onTap});

  final Map<String, dynamic> batch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final description = (batch['description'] as String? ?? '').trim();
    final questionTypes = (batch['question_types'] as Iterable? ?? const [])
        .map((type) => type.toString().toLowerCase())
        .toSet();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE4EAE9)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BatchImage(imageUrl: batch['image_url'] as String?, width: 62, height: 62),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            batch['name'] as String? ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppConstants.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _BatchTag(label: batch['exam_type']?.toString() ?? ''),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppConstants.mutedText, height: 1.3),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _BatchMetric(
                          icon: Icons.assignment_outlined,
                          label: '${batch['exam_count'] ?? 0}টি পরীক্ষা',
                        ),
                        _BatchMetric(
                          icon: Icons.groups_outlined,
                          label: '${batch['enrolled_count'] ?? 0} জন',
                        ),
                        for (final type in questionTypes)
                          _BatchTag(label: type == 'mcq' ? 'MCQ' : type == 'written' ? 'Written' : type.toUpperCase()),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 6, top: 20),
                child: Icon(Icons.chevron_right, color: AppConstants.mutedText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatchMetric extends StatelessWidget {
  const _BatchMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppConstants.primary),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 11, color: AppConstants.mutedText)),
          ],
        ),
      );
}

class _BatchTag extends StatelessWidget {
  const _BatchTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 112),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F3F1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppConstants.primary),
        ),
      );
}

class _BatchImage extends StatelessWidget {
  const _BatchImage({
    required this.imageUrl,
    this.width = 48,
    this.height = 48,
  });

  final String? imageUrl;
  final double width;
  final double height;

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: AppConstants.primary.withValues(alpha: 0.08),
        child: const Icon(Icons.groups_outlined, color: AppConstants.primary),
      );

  @override
  Widget build(BuildContext context) {
    final value = imageUrl?.trim() ?? '';
    if (value.isEmpty) return ClipRRect(borderRadius: BorderRadius.circular(10), child: _placeholder());

    Widget image;
    if (value.startsWith('data:image/')) {
      final separator = value.indexOf(',');
      if (separator < 0) return _placeholder();
      try {
        image = Image.memory(
          base64Decode(value.substring(separator + 1)),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } on FormatException {
        return _placeholder();
      }
    } else {
      image = Image.network(
        value,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return ClipRRect(borderRadius: BorderRadius.circular(10), child: image);
  }
}