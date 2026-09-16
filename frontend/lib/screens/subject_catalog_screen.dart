import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/brand_navigation.dart';

class SubjectCatalogScreen extends ConsumerStatefulWidget {
  const SubjectCatalogScreen({super.key, this.categoryName});

  final String? categoryName;

  @override
  ConsumerState<SubjectCatalogScreen> createState() =>
      _SubjectCatalogScreenState();
}

class _SubjectCatalogScreenState extends ConsumerState<SubjectCatalogScreen> {
  late Future<_CatalogData> _catalog;

  @override
  void initState() {
    super.initState();
    _catalog = _loadCatalog();
  }

  @override
  void didUpdateWidget(covariant SubjectCatalogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryName != widget.categoryName) {
      final catalog = _loadCatalog();
      setState(() {
        _catalog = catalog;
      });
    }
  }

  Future<_CatalogData> _loadCatalog() async {
    final topics = await TopicService(apiClient).getTree();
    final questions = await QuestionService(apiClient).list();
    final requestedCategory = _canonicalCategory(widget.categoryName);

    TopicNode? findCategory(List<TopicNode> nodes) {
      for (final node in nodes) {
        if (requestedCategory == null ||
            node.name.toLowerCase() == requestedCategory) {
          return node;
        }
        final match = findCategory(node.children);
        if (match != null) return match;
      }
      return null;
    }

    final category = findCategory(topics);
    if (widget.categoryName == null || category == null) {
      return _CatalogData(
        category: null,
        categories: topics,
        topics: topics,
        questions: questions,
      );
    }

    final categoryIds = <String>{};
    void collectIds(TopicNode node) {
      categoryIds.add(node.id);
      for (final child in node.children) {
        collectIds(child);
      }
    }

    collectIds(category);
    final categoryName = category.name.toLowerCase();
    return _CatalogData(
      category: category,
      categories: topics,
      topics: [category],
      questions: questions
          .where((question) =>
            categoryIds.contains(question.topicId) ||
            question.topicName?.toLowerCase() == categoryName)
          .toList(),
    );
  }

  String? _canonicalCategory(String? name) {
    if (name == null) return null;
    return switch (name.trim().toLowerCase()) {
      'bcs প্রস্তুতি' => 'bcs',
      'ব্যাংক জব' => 'bank',
      _ => name.trim().toLowerCase(),
    };
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(title: const Text('বিষয়সমূহ')),
      body: ListView(
        children: [
          FutureBuilder<_CatalogData>(
            future: _catalog,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('বিষয় লোড করা যায়নি: ${snapshot.error}'),
                );
              }
                final filtered = snapshot.data!.topics;
              return Center(
                  child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
                  child: Column(
                    children: [
                      _CategoryTabs(
                        categories: snapshot.data!.categories,
                        activeCategory: widget.categoryName,
                      ),
                      const SizedBox(height: 14),
                      _QuestionBankSets(
                        questions: snapshot.data!.questions,
                        categoryName: snapshot.data!.category?.name,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Subjects & Chapters${snapshot.data!.category == null ? '' : ' — ${snapshot.data!.category!.name}'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _TopicBrowser(
                        roots: filtered,
                        questions: snapshot.data!.questions,
                      ),
                      if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child:
                              Center(child: Text('কোনো বিষয় পাওয়া যায়নি')),
                        ),
                    ],
                  ),
                ),
              ));
            },
          ),
        ],
      ),
      bottomNavigationBar: BrandBottomNavigation(
        selectedIndex: 2,
        onSelected: (index) => BrandBottomNavigation.navigate(context, index),
      ),
    );
  }
}

/// Loaded catalog payload: the topics that have at least one MCQ plus the
/// full question list used to compute per-subject question counts.
class _CatalogData {
  const _CatalogData({
    required this.category,
    required this.categories,
    required this.topics,
    required this.questions,
  });

  final TopicNode? category;
  final List<TopicNode> categories;
  final List<TopicNode> topics;
  final List<Question> questions;
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.categories,
    required this.activeCategory,
  });

  final List<TopicNode> categories;
  final String? activeCategory;

  static const _fallbackCategories = [
    'SSC',
    'HSC',
    'Varsity',
    'Medical',
    'Engineering',
    'BCS',
    'Bank',
  ];

  @override
  Widget build(BuildContext context) {
    final names = <String>{
      ..._fallbackCategories,
      for (final category in _flatten(categories))
        if (_fallbackCategories.any(
          (name) => name.toLowerCase() == category.name.toLowerCase(),
        ))
          category.name,
    }.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          for (final name in names)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(name),
                selected: name.toLowerCase() ==
                    (activeCategory ?? '').toLowerCase(),
                selectedColor: const Color(0xFFD6EEF3),
                backgroundColor: const Color(0xFFF4F7F8),
                side: const BorderSide(color: Color(0xFFD9E4E8)),
                showCheckmark: true,
                checkmarkColor: AppConstants.primary,
                labelStyle: const TextStyle(
                  color: Color(0xFF26363A),
                  fontWeight: FontWeight.w500,
                ),
                onSelected: (selected) {
                  if (!selected) return;
                  context.go(
                    '/subject-catalog?category=${Uri.encodeComponent(name)}',
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  static Iterable<TopicNode> _flatten(List<TopicNode> nodes) sync* {
    for (final node in nodes) {
      yield node;
      yield* _flatten(node.children);
    }
  }
}

class _QuestionBankSets extends StatelessWidget {
  const _QuestionBankSets({
    required this.questions,
    required this.categoryName,
  });

  final List<Question> questions;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final examTypes = <String>{};
    final previousYears = <String>{};
    final questionSets = <String>{};
    for (final question in questions) {
      if (question.examType?.isNotEmpty == true) examTypes.add(question.examType!);
      previousYears.addAll(
        question.previousYears.where(
          (year) => categoryName == null ||
              year.toLowerCase().contains(categoryName!.toLowerCase()) ||
              (categoryName!.toLowerCase() == 'bcs' &&
                  year.toLowerCase().contains('bcs')) ||
              (categoryName!.toLowerCase() == 'bank' &&
                  year.toLowerCase().contains('bank')),
        ),
      );
      if (question.questionSet?.isNotEmpty == true) {
        questionSets.add(question.questionSet!);
      }
    }
    final entries = <_QuestionBankEntry>[
      for (final set in questionSets)
        _QuestionBankEntry(
          label: set,
          caption: 'Question Set',
          questions: questions
              .where((question) => question.questionSet == set)
              .toList(),
        ),
      for (final type in examTypes)
        _QuestionBankEntry(
          label: type,
          caption: 'Exam Type',
          questions: questions.where((question) => question.examType == type).toList(),
        ),
      for (final year in previousYears)
        _QuestionBankEntry(
          label: year,
          caption: 'Previous Year',
            questions: questions
              .where((question) => question.previousYears.contains(year))
              .toList(),
        ),
    ];
      final visibleEntries = entries.take(3).toList();

    return Card(
      color: AppConstants.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${categoryName ?? 'Active Category'} Question Bank Sets',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (categoryName != null)
                  TextButton.icon(
                    onPressed: () => context.push(
                      '/question-bank?category=${Uri.encodeComponent(categoryName!)}',
                    ),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('View all question sets'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('এই category-তে এখনো কোনো question bank যোগ করা হয়নি।'),
              ),
            for (final entry in visibleEntries)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_edu),
                title: Text(entry.label),
                subtitle: Text(
                  '${entry.caption} • ${entry.questions.length}টি প্রশ্ন',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showSet(context, entry.label, entry.questions),
              ),
          ],
        ),
      ),
    );
  }

  void _showSet(
    BuildContext context,
    String set,
    List<Question> matchingQuestions,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuestionBankListSheet(
        title: '$set${categoryName == null ? '' : ' — $categoryName'}',
        questions: matchingQuestions,
      ),
    );
  }
}

class _QuestionBankEntry {
  const _QuestionBankEntry({
    required this.label,
    required this.caption,
    required this.questions,
  });

  final String label;
  final String caption;
  final List<Question> questions;
}

class _QuestionBankListSheet extends StatefulWidget {
  const _QuestionBankListSheet({required this.title, required this.questions});

  final String title;
  final List<Question> questions;

  @override
  State<_QuestionBankListSheet> createState() => _QuestionBankListSheetState();
}

class _QuestionBankListSheetState extends State<_QuestionBankListSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  String _filter = 'সব';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = <String>{
      'সব',
      for (final question in widget.questions)
        if (question.topicName?.isNotEmpty == true) question.topicName!,
    }.toList();
    final filtered = widget.questions.where((question) {
      final text = '${question.questionText} ${question.topicName ?? ''}'
          .toLowerCase();
      final matchesSearch = _query.isEmpty || text.contains(_query);
      final matchesFilter = _filter == 'সব' || question.topicName == _filter;
      return matchesSearch && matchesFilter;
    }).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.97,
      builder: (context, scrollController) => Material(
        color: const Color(0xFFEFF3F9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                  Text('${filtered.length}টি',
                      style: const TextStyle(color: AppConstants.mutedText)),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _query = value.trim().toLowerCase()),
                      decoration: const InputDecoration(
                        hintText: 'Search question...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    initialValue: _filter,
                    onSelected: (value) => setState(() => _filter = value),
                    itemBuilder: (context) => [
                      for (final filter in filters)
                        PopupMenuItem(value: filter, child: Text(filter)),
                    ],
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD9E4E8)),
                      ),
                      child: Row(
                        children: [
                          Text(_filter),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('কোনো প্রশ্ন পাওয়া যায়নি'))
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => _QuestionBankListCard(
                        index: index + 1,
                        question: filtered[index],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionBankListCard extends StatefulWidget {
  const _QuestionBankListCard({required this.index, required this.question});

  final int index;
  final Question question;

  @override
  State<_QuestionBankListCard> createState() => _QuestionBankListCardState();
}

class _QuestionBankListCardState extends State<_QuestionBankListCard> {
  bool _bookmarked = false;

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('প্রশ্ন ${widget.index}',
                      style: const TextStyle(
                          color: AppConstants.mutedText,
                          fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: _bookmarked ? 'বুকমার্ক সরান' : 'বুকমার্ক করুন',
                  onPressed: () => setState(() => _bookmarked = !_bookmarked),
                  icon: Icon(
                    _bookmarked ? Icons.favorite : Icons.favorite_border,
                    color: const Color(0xFFE85B61),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 5),
                Text(question.topicName ?? 'SSC'),
              ],
            ),
            const SizedBox(height: 8),
            Text(question.questionText,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, height: 1.35)),
            const SizedBox(height: 9),
            for (var optionIndex = 0;
                optionIndex < question.options.length;
                optionIndex++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${['ক', 'খ', 'গ', 'ঘ'][optionIndex]}. ${question.options[optionIndex]}',
                  style: const TextStyle(color: Color(0xFF39474A)),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.menu_book, size: 17, color: Color(0xFFE99B58)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    question.questionSet ?? question.examType ?? 'Question Bank',
                    style: const TextStyle(color: AppConstants.mutedText),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAnswer(context),
                  icon: const Icon(Icons.visibility_outlined, size: 17),
                  label: const Text('উত্তর দেখুন'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAnswer(BuildContext context) {
    final question = widget.question;
    final answerIndex = ['A', 'B', 'C', 'D'].indexOf(question.correctOption ?? '');
    final answer = answerIndex >= 0 ? question.options[answerIndex] : 'উত্তর দেওয়া হয়নি';
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('সঠিক উত্তর', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 8),
            Text(answer, style: const TextStyle(color: Colors.green, fontSize: 17)),
            if (question.explanation?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text('ব্যাখ্যা: ${question.explanation}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopicBrowser extends StatefulWidget {
  const _TopicBrowser({required this.roots, required this.questions});

  final List<TopicNode> roots;
  final List<Question> questions;

  @override
  State<_TopicBrowser> createState() => _TopicBrowserState();
}

class _TopicBrowserState extends State<_TopicBrowser> {
  late List<TopicNode> _level;
  final _history = <({String title, List<TopicNode> level})>[];

  @override
  void initState() {
    super.initState();
    _level = widget.roots;
  }

  @override
  Widget build(BuildContext context) {
    final title = _history.isEmpty ? 'বিষয়সমূহ' : _history.last.title;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
      decoration: const BoxDecoration(color: Color(0xFFEFF3F9)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_history.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text('$title থেকে পিছনে'),
              ),
            ),
          for (final topic in _level)
            _TopicActionCard(
              topic: topic,
              questionCount: _questionCount(topic),
              hasChildren: topic.children.isNotEmpty,
              onOpen: () => _openTopic(topic),
              onAllQuestions: () => _openPractice(topic),
              onRandomExam: () => _showRandomExamDialog(topic),
            ),
          if (_level.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('এই স্তরে কোনো subcategory নেই')),
              ),
            ),
        ],
      ),
    );
  }

  int _questionCount(TopicNode topic) {
    final ids = _descendantIds(topic);
    return widget.questions.where((question) => ids.contains(question.topicId)).length;
  }

  Set<String> _descendantIds(TopicNode topic) {
    final ids = <String>{topic.id};
    for (final child in topic.children) {
      ids.addAll(_descendantIds(child));
    }
    return ids;
  }

  void _openTopic(TopicNode topic) {
    if (topic.children.isEmpty) {
      _openPractice(topic);
      return;
    }
    setState(() {
      _history.add((title: topic.name, level: _level));
      _level = topic.children;
    });
  }

  void _goBack() {
    if (_history.isEmpty) return;
    final previous = _history.removeLast();
    setState(() => _level = previous.level);
  }

  void _openPractice(TopicNode topic) {
    context.push(
      '/subject-practice?topicId=${Uri.encodeComponent(topic.id)}&topicName=${Uri.encodeComponent(topic.name)}&mode=all',
    );
  }

  Future<void> _showRandomExamDialog(TopicNode topic) async {
    final available = _questionCount(topic);
    final questionOptions = <int>{
      ...[5, 10, 20, 30, 50].where((value) => value <= available),
      available.clamp(1, 50),
    }.toList()..sort();
    var questionCount = questionOptions.last;
    var duration = 10;
    final result = await showDialog<({int count, int duration})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${topic.name} - Random Exam'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: questionCount,
                decoration: const InputDecoration(labelText: 'কতটি প্রশ্ন?'),
                items: [
                  for (final count in questionOptions)
                    DropdownMenuItem(value: count, child: Text('$countটি প্রশ্ন')),
                ],
                onChanged: (value) => setDialogState(() => questionCount = value ?? questionCount),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: duration,
                decoration: const InputDecoration(labelText: 'সময়'),
                items: const [5, 10, 15, 20, 30]
                    .map((value) => DropdownMenuItem(value: value, child: Text('$value মিনিট')))
                    .toList(),
                onChanged: (value) => setDialogState(() => duration = value ?? duration),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
            FilledButton(
              onPressed: () => Navigator.pop(context, (count: questionCount, duration: duration)),
              child: const Text('পরীক্ষা শুরু'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    try {
      final exam = await ExamService(apiClient).generateDynamic(
        topicId: topic.id,
        questionCount: result.count,
        durationMinutes: result.duration,
        title: '${topic.name} Random Exam',
      );
      if (mounted) context.push('/exam/${exam.id}');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('পরীক্ষা তৈরি করা যায়নি: $error')));
      }
    }
  }
}

class _TopicActionCard extends StatelessWidget {
  const _TopicActionCard({required this.topic, required this.questionCount, required this.hasChildren, required this.onOpen, required this.onAllQuestions, required this.onRandomExam});

  final TopicNode topic;
  final int questionCount;
  final bool hasChildren;
  final VoidCallback onOpen;
  final VoidCallback onAllQuestions;
  final VoidCallback onRandomExam;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onOpen,
                    borderRadius: BorderRadius.circular(8),
                    child: Text(
                      topic.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const Icon(Icons.favorite, color: Color(0xFFE85B61), size: 21),
                const SizedBox(width: 5),
                const Text('0', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 3),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'বিষয় খুলুন',
                  onPressed: onOpen,
                  icon: Icon(
                    hasChildren ? Icons.chevron_right : Icons.arrow_forward_ios,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 82,
                  height: 82,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const CircularProgressIndicator(
                        value: 0,
                        strokeWidth: 6,
                        color: Color(0xFF7ED8F2),
                        backgroundColor: Color(0xFFE6F7FC),
                      ),
                      Text('0/$questionCount',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text('0.00% প্রশ্ন\nপড়া হয়েছে',
                      style: TextStyle(fontSize: 16, height: 1.45)),
                ),
                Expanded(
                  child: Text(
                    'Subtopics: ${topic.children.length}\nQuestions: $questionCount',
                    style: const TextStyle(fontSize: 16, height: 1.45),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _TopicButton(
                    label: 'All Questions',
                    background: const Color(0xFFDCD9FF),
                    onPressed: questionCount == 0 ? null : onAllQuestions,
                  ),
                ),
                if (hasChildren) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TopicButton(
                      label: 'All Subtopics',
                      background: const Color(0xFFFFE4D2),
                      onPressed: onOpen,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: _TopicButton(
                    label: 'Create Exam',
                    background: const Color(0xFFE2E7EF),
                    onPressed: questionCount == 0 ? null : onRandomExam,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicButton extends StatelessWidget {
  const _TopicButton({required this.label, required this.background, required this.onPressed});

  final String label;
  final Color background;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: const Color(0xFF202938),
          disabledBackgroundColor: background.withValues(alpha: 0.45),
          disabledForegroundColor: const Color(0x88202938),
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
