import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../widgets/brand_navigation.dart';

class SubjectPracticeArgs {
  const SubjectPracticeArgs({
    required this.subject,
    required this.questionSets,
  });

  final String subject;
  final List<String> questionSets;
}

class SubjectPracticeScreen extends StatelessWidget {
  const SubjectPracticeScreen({super.key, this.args});

  final SubjectPracticeArgs? args;

  static const _sections = [
    ('অধ্যায়ভিত্তিক অনুশীলন', 'একেক অধ্যায়', Color(0xFF29B6E6)),
    ('সম্পূর্ণ সিলেবাস অনুশীলন', 'সবগুলো অধ্যায়', Color(0xFF18B447)),
    ('নির্বাচনী পরীক্ষা প্রস্তুতি', 'কমনের নিশ্চয়তা', Color(0xFF29B6E6)),
    ('ফাইনাল পরীক্ষা প্রস্তুতি', 'কমনের নিশ্চয়তা', Color(0xFF18B447)),
    ('পরীক্ষার আগে শর্ট সাজেশন', 'কমনের নিশ্চয়তা', Color(0xFFF39C12)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        title: Text(args?.subject ?? 'বিষয় অনুশীলন',
            overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                args == null
                    ? 'বিষয়ভিত্তিক প্রশ্ন অনুশীলন করুন।'
                    : '${args!.subject} বিষয়ের জন্য তৈরি প্রশ্ন সেটগুলো থেকে অনুশীলন করুন।',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.7,
                  color: Color(0xFF555555),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final section in (args?.questionSets ??
              _sections.map((section) => section.$1).toList()))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PracticeCard(
                title: section,
                tag: 'প্রশ্ন সেট',
                color: const Color(0xFF29B6E6),
                onTap: () => _showComingSoon(context, section),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BrandBottomNavigation(
        selectedIndex: 2,
        onSelected: (_) {},
      ),
    );
  }

  static void _showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title শীঘ্রই শুরু হবে।')),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    required this.title,
    required this.tag,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String tag;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 82,
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  color: color,
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
