import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/brand_navigation.dart';

class SubjectCatalogScreen extends ConsumerStatefulWidget {
  const SubjectCatalogScreen({super.key});

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
    final topicIds = <String>{
      for (final question in questions) question.topicId
    };
    final visible = <TopicNode>[];
    void walk(List<TopicNode> nodes) {
      for (final node in nodes) {
        if (topicIds.contains(node.id)) visible.add(node);
        walk(node.children);
      }
    }

    walk(topics);
    return _CatalogData(topics: visible, questions: questions);
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
                      Card(
                        color: AppConstants.primary.withValues(alpha: 0.08),
                        child: ListTile(
                          leading: const Icon(Icons.history_edu,
                              color: AppConstants.primary),
                          title: const Text('Previous Question Bank',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          subtitle:
                              const Text('বিগত বছরের প্রশ্ন দেখে অনুশীলন করুন'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/previous-question-bank'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.15,
                        ),
                        itemBuilder: (context, index) {
                          final subject = filtered[index];
                          final count = snapshot.data!.questions
                              .where(
                                  (question) => question.topicId == subject.id)
                              .length;
                          return _SubjectCard(
                            name: subject.name,
                            institution: 'Database question bank',
                            courses: count,
                            questions: '$count',
                            progress: count == 0 ? 0 : 1,
                            color: AppConstants.primary,
                            onTap: () => context.push(
                              '/subject-practice?topicId=${Uri.encodeComponent(subject.id)}&topicName=${Uri.encodeComponent(subject.name)}',
                            ),
                          );
                        },
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
  const _CatalogData({required this.topics, required this.questions});

  final List<TopicNode> topics;
  final List<Question> questions;
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.name,
    required this.institution,
    required this.courses,
    required this.questions,
    required this.progress,
    required this.color,
    required this.onTap,
  });

  final String name;
  final String institution;
  final int courses;
  final String questions;
  final double progress;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppConstants.mutedText),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  institution,
                  style: const TextStyle(
                      color: AppConstants.mutedText, fontSize: 11),
                ),
                const Spacer(),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(8),
                  color: color,
                  backgroundColor: const Color(0xFFE1E5E8),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('কোর্স $courses টি',
                        style: const TextStyle(fontSize: 11)),
                    Text('প্রশ্ন $questions',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
