import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../widgets/brand_navigation.dart';

class SubjectCatalogScreen extends StatefulWidget {
  const SubjectCatalogScreen({super.key});

  @override
  State<SubjectCatalogScreen> createState() => _SubjectCatalogScreenState();
}

class _SubjectCatalogScreenState extends State<SubjectCatalogScreen> {
  final _searchController = TextEditingController();

  static const _subjects = [
    ('বাংলা', 'জাতীয় বিশ্ববিদ্যালয়', 30, '5724+', 0.25, Color(0xFF3949AB)),
    ('ইতিহাস', 'জাতীয় বিশ্ববিদ্যালয়', 34, '4717+', 0.72, Color(0xFF388E3C)),
    (
      'ইসলামের ইতিহাস ও সংস্কৃতি',
      'জাতীয় বিশ্ববিদ্যালয়',
      35,
      '6704+',
      0.76,
      Color(0xFFC62828)
    ),
    ('দর্শন', 'জাতীয় বিশ্ববিদ্যালয়', 33, '5773+', 0.23, Color(0xFF7B1FA2)),
    (
      'ইসলামী শিক্ষা',
      'জাতীয় বিশ্ববিদ্যালয়',
      33,
      '5248+',
      0.66,
      Color(0xFF00796B)
    ),
    (
      'রাষ্ট্রবিজ্ঞান',
      'জাতীয় বিশ্ববিদ্যালয়',
      36,
      '4393+',
      0.84,
      Color(0xFFEF6C00)
    ),
    ('অর্থনীতি', 'জাতীয় বিশ্ববিদ্যালয়', 33, '6172+', 0.58, Color(0xFFC2185B)),
    (
      'সমাজবিজ্ঞান',
      'জাতীয় বিশ্ববিদ্যালয়',
      36,
      '4359+',
      0.40,
      Color(0xFF37474F)
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    final filtered =
        _subjects.where((subject) => subject.$1.contains(query)).toList();

    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(title: const Text('বিষয়সমূহ')),
      body: ListView(
        children: [
          Center(
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
                        return _SubjectCard(
                          name: subject.$1,
                          institution: subject.$2,
                          courses: subject.$3,
                          questions: subject.$4,
                          progress: subject.$5,
                          color: subject.$6,
                          onTap: () => context.push('/subject-practice'),
                        );
                      },
                    ),
                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('কোনো বিষয় পাওয়া যায়নি')),
                      ),
                  ],
                ),
              ),
            ),
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
