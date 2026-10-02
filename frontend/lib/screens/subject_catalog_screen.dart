import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/brand_navigation.dart';
import 'mobile_dashboard.dart';

class SubjectCatalogScreen extends ConsumerStatefulWidget {
  const SubjectCatalogScreen({super.key, this.categoryName, this.createExam = false});

  final String? categoryName;
  final bool createExam;

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
    final writtenQuestions = await WrittenQuestionService(apiClient).list();
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
        writtenQuestions: writtenQuestions,
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
      writtenQuestions: writtenQuestions
          .where((question) => categoryIds.contains(question.topicId))
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
      drawer: const DashboardDrawer(),
      appBar: const BrandHeader(),
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
                        writtenQuestions: snapshot.data!.writtenQuestions,
                        autoOpenCreate: widget.createExam,
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

class _DialogFieldCaption extends StatelessWidget {
  const _DialogFieldCaption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: const TextStyle(
              color: AppConstants.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
}

/// Loaded catalog payload: the topics that have at least one MCQ plus the
/// full question list used to compute per-subject question counts.
class _CatalogData {
  const _CatalogData({
    required this.category,
    required this.categories,
    required this.topics,
    required this.questions,
    required this.writtenQuestions,
  });

  final TopicNode? category;
  final List<TopicNode> categories;
  final List<TopicNode> topics;
  final List<Question> questions;
  final List<WrittenQuestion> writtenQuestions;
}

class _CategoryTabs extends StatefulWidget {
  const _CategoryTabs({
    required this.categories,
    required this.activeCategory,
  });

  final List<TopicNode> categories;
  final String? activeCategory;

  @override
  State<_CategoryTabs> createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<_CategoryTabs> {
  final _scrollController = ScrollController();
  double _scrollOffset = 0;

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final names = <String>{
      ..._fallbackCategories,
      for (final category in _flatten(widget.categories))
        if (_fallbackCategories.any(
          (name) => name.toLowerCase() == category.name.toLowerCase(),
        ))
          category.name,
    }.toList();

    final dotCount = (names.length / 4).ceil().clamp(1, 4);
    final activeDot = _scrollController.hasClients &&
            _scrollController.position.maxScrollExtent > 0
        ? ((_scrollOffset / _scrollController.position.maxScrollExtent) *
                (dotCount - 1))
            .round()
        : 0;

    return Column(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              setState(() => _scrollOffset = notification.metrics.pixels);
            }
            return false;
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                for (final name in names)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(name),
                      selected: name.toLowerCase() ==
                          (widget.activeCategory ?? '').toLowerCase(),
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
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < dotCount; index++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: index == activeDot ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: index == activeDot
                      ? AppConstants.primary
                      : const Color(0xFFB7C7CB),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
          ],
        ),
        if (_scrollController.hasClients &&
            _scrollController.position.maxScrollExtent > 0)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.swipe,
              size: 14,
              color: Color(0xFF8A9A9E),
            ),
          ),
      ],
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
  const _TopicBrowser({
    required this.roots,
    required this.questions,
    required this.writtenQuestions,
    this.autoOpenCreate = false,
  });

  final List<TopicNode> roots;
  final List<Question> questions;
  final List<WrittenQuestion> writtenQuestions;
  final bool autoOpenCreate;

  @override
  State<_TopicBrowser> createState() => _TopicBrowserState();
}

class _TopicBrowserState extends State<_TopicBrowser> {
  late List<TopicNode> _level;
  final _history = <({String title, List<TopicNode> level})>[];
  bool _autoOpened = false;

  @override
  void initState() {
    super.initState();
    _level = widget.roots;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.autoOpenCreate && !_autoOpened && _level.isNotEmpty) {
      _autoOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showCreateExamDialog(_level.first);
      });
    }
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
              onRandomExam: () {
                if (topic.questionType == 'written') {
                  _openWrittenExam(topic);
                } else {
                  _showCreateExamDialog(topic);
                }
              },
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
    if (topic.questionType == 'written') {
      return widget.writtenQuestions.where((question) => ids.contains(question.topicId)).length;
    }
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
    if (topic.questionType == 'written') {
      context.push(
        '/written-practice?topicId=${Uri.encodeComponent(topic.id)}&topicName=${Uri.encodeComponent(topic.name)}',
      );
      return;
    }
    context.push(
      '/subject-practice?topicId=${Uri.encodeComponent(topic.id)}&topicName=${Uri.encodeComponent(topic.name)}&mode=all',
    );
  }

  void _openWrittenExam(TopicNode topic) {
    context.push(
      '/written-practice?topicId=${Uri.encodeComponent(topic.id)}&topicName=${Uri.encodeComponent(topic.name)}&mode=exam',
    );
  }

  Future<void> _showCreateExamDialog(TopicNode initialTopic) async {
    final topics = _flatten(widget.roots)
        .where((topic) => _questionCount(topic) > 0)
        .toList();
    final selectedCounts = <String, int>{
      initialTopic.id: _questionCount(initialTopic).clamp(1, 10),
    };
    final passController = TextEditingController();
    final perQuestionMarkController = TextEditingController(text: '1');
    final negativeController = TextEditingController(text: '0.25');
    final durationController = TextEditingController(text: '30');
    final titleController = TextEditingController(text: 'Custom Practice Exam');
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Custom Exam'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _DialogFieldCaption('Exam title'),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      hintText: 'Custom Practice Exam',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Topics ও question count', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 6),
                  for (final topic in topics)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            value: selectedCounts.containsKey(topic.id),
                            onChanged: (selected) => setDialogState(() {
                              if (selected == true) {
                                selectedCounts[topic.id] = _questionCount(topic).clamp(1, 50);
                              } else {
                                selectedCounts.remove(topic.id);
                              }
                            }),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(topic.name),
                                Text('${_questionCount(topic)}টি প্রশ্ন available'),
                              ],
                            ),
                          ),
                          if (selectedCounts.containsKey(topic.id)) ...[
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 84,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      'Qty',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppConstants.mutedText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TextFormField(
                                    initialValue: '${selectedCounts[topic.id]}',
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    ),
                                    onChanged: (value) {
                                      final count = int.tryParse(value);
                                      if (count != null && count > 0) selectedCounts[topic.id] = count;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const Divider(),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 360 ? 2 : 1;
                      final gap = 12.0;
                      final fieldWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
                      Widget numberField(
                        String label,
                        TextEditingController controller,
                        String hint, {
                        bool decimal = true,
                      }) => SizedBox(
                            width: fieldWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _DialogFieldCaption(label),
                                TextField(
                                  controller: controller,
                                  keyboardType: decimal
                                      ? const TextInputType.numberWithOptions(decimal: true)
                                      : TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: hint,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                      return Wrap(
                        spacing: gap,
                        runSpacing: 12,
                        children: [
                          numberField('Pass mark', passController, 'Auto · 40%'),
                          numberField('Per question mark', perQuestionMarkController, '1.0'),
                          numberField('Negative mark', negativeController, '0.25'),
                          numberField('Minutes', durationController, '30', decimal: false),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
            FilledButton(
              onPressed: selectedCounts.isEmpty
                  ? null
                  : () {
                      final perQuestionMark = double.tryParse(perQuestionMarkController.text) ?? 1;
                      Navigator.pop(context, {
                      'topicQuestions': [
                        for (final entry in selectedCounts.entries)
                          {'topicId': entry.key, 'questionCount': entry.value},
                      ],
                      'perQuestionMark': perQuestionMark,
                      'passMark': double.tryParse(passController.text),
                      'negativeMarking': double.tryParse(negativeController.text) ?? 0.25,
                      'durationMinutes': int.tryParse(durationController.text) ?? 30,
                      'title': titleController.text.trim().isEmpty ? 'Custom Practice Exam' : titleController.text.trim(),
                      });
                    },
              child: const Text('Create Exam'),
            ),
          ],
        ),
      ),
    );
    passController.dispose();
    negativeController.dispose();
    durationController.dispose();
    titleController.dispose();
    if (result == null || !mounted) return;
    try {
      final exam = await ExamService(apiClient).generateDynamicMulti(
        topicQuestions: (result['topicQuestions'] as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(),
        perQuestionMark: result['perQuestionMark'] as double,
        passMark: result['passMark'] as double?,
        negativeMarking: result['negativeMarking'] as double,
        durationMinutes: result['durationMinutes'] as int,
        title: result['title'] as String,
      );
      if (mounted) await _showCreatedExamDialog(exam);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('পরীক্ষা তৈরি করা যায়নি: $error')));
      }

    }
  perQuestionMarkController.dispose();
  }

  Iterable<TopicNode> _flatten(List<TopicNode> nodes) sync* {
    for (final node in nodes) {
      yield node;
      yield* _flatten(node.children);
    }
  }

  Future<void> _showCreatedExamDialog(Exam exam) async {
    final shareUrl = '${Uri.base.origin}/#/exam/${exam.id}';
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Exam তৈরি হয়েছে'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('এই link share করলে অন্যরা সরাসরি exam দিতে পারবে:'),
            const SizedBox(height: 10),
            SelectableText(shareUrl, style: const TextStyle(fontSize: 12, color: AppConstants.primary)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final shareUri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent('${exam.title}\\n$shareUrl')}');
              await launchUrl(shareUri, mode: LaunchMode.externalApplication);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share'),
          ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: shareUrl));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exam link copied')));
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copy link'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.push('/exam/${exam.id}/participants');
            },
            child: const Text('Participants & rank'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.push('/exam/${exam.id}');
            },
            child: const Text('Start Exam'),
          ),
        ],
      ),
    );
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
                    'Subtopics: ${topic.children.length}\n${topic.questionType == 'written' ? 'Written questions' : 'Questions'}: $questionCount',
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
                    label: topic.questionType == 'written' ? 'Read Written' : 'All Questions',
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
                    label: topic.questionType == 'written' ? 'Written Exam' : 'Create Exam',
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
