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
  final _searchController = TextEditingController();
  late Future<_CatalogData> _catalog;

  @override
  void initState() {
    super.initState();
    _catalog = _loadCatalog();
  }

  Future<_CatalogData> _loadCatalog() async {
    final topics = await TopicService(apiClient).getTree();
    final questions = await QuestionService(apiClient).list();

    TopicNode? findCategory(List<TopicNode> nodes) {
      for (final node in nodes) {
        if (widget.categoryName == null ||
            node.name.toLowerCase() == widget.categoryName!.toLowerCase()) {
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
    return _CatalogData(
      category: category,
      categories: topics,
      topics: [category],
      questions: questions
          .where((question) => categoryIds.contains(question.topicId))
          .toList(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
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
              final query = _searchController.text.trim().toLowerCase();
              final filtered = snapshot.data!.topics
                  .where((topic) => topic.name.toLowerCase().contains(query))
                  .toList();
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
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'বিষয়ের নাম লিখুন...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.all(5),
                            child: FilledButton(
                              onPressed: () => FocusScope.of(context).unfocus(),
                              child: const Text('খোঁজো'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
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
                      for (final topic in filtered)
                        _TopicTree(
                          topic: topic,
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
    'HSC',
    'SSC',
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
      child: Row(
        children: [
          for (final name in names)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(name),
                selected: name.toLowerCase() ==
                    (activeCategory ?? '').toLowerCase(),
                onSelected: (_) => context.go(
                  '/subject-catalog?category=${Uri.encodeComponent(name)}',
                ),
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
    final sets = <String>{};
    for (final question in questions) {
      if (question.examType?.isNotEmpty == true) sets.add(question.examType!);
      if (question.questionSet?.isNotEmpty == true) {
        sets.add(question.questionSet!);
      }
    }
    if (sets.isEmpty) {
      sets.addAll({'Model Test Sets', 'Board Question Sets'});
    }

    return Card(
      color: AppConstants.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${categoryName ?? 'Active Category'} Question Bank Sets',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final set in sets)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_edu),
                title: Text(set),
                subtitle: Text(
                  '${questions.where((question) => question.examType == set || question.questionSet == set).length}টি প্রশ্ন',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showSet(context, set),
              ),
          ],
        ),
      ),
    );
  }

  void _showSet(BuildContext context, String set) {
    final matchingQuestions = questions
        .where((question) =>
            question.examType == set || question.questionSet == set)
        .toList();
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '$set${categoryName == null ? '' : ' — $categoryName'}',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (matchingQuestions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('এই category-তে এখনো কোনো প্রশ্ন যোগ করা হয়নি।'),
            ),
          for (final question in matchingQuestions)
            ListTile(
              leading: const Icon(Icons.quiz),
              title: Text(question.questionText),
              subtitle: Text(question.questionSet ?? question.examType ?? ''),
            ),
        ],
      ),
    );
  }
}

class _TopicTree extends StatelessWidget {
  const _TopicTree({required this.topic, required this.questions});

  final TopicNode topic;
  final List<Question> questions;

  @override
  Widget build(BuildContext context) {
    final count = questions.where((question) => question.topicId == topic.id).length;
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.menu_book, color: AppConstants.primary),
        title: Text(topic.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('$countটি প্রশ্ন'),
        children: [
          if (topic.children.isEmpty)
            ListTile(
              title: const Text('এই অধ্যায়ের প্রশ্ন অনুশীলন করুন'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openTopic(context, topic),
            ),
          for (final child in topic.children)
            _TopicTree(topic: child, questions: questions),
        ],
      ),
    );
  }

  static void _openTopic(BuildContext context, TopicNode topic) {
    context.push(
      '/subject-practice?topicId=${Uri.encodeComponent(topic.id)}&topicName=${Uri.encodeComponent(topic.name)}',
    );
  }
}
