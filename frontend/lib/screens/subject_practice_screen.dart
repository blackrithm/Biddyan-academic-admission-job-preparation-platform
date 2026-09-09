import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../widgets/brand_navigation.dart';

class SubjectPracticeScreen extends StatelessWidget {
  const SubjectPracticeScreen({super.key});

  static const _sections = [
    ('Previous Question Bank', 'বিগত বছরের প্রশ্ন', Color(0xFF7B1FA2)),
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
        title: const Text('Exam Type'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          for (final section in _sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PracticeCard(
                title: section.$1,
                tag: section.$2,
                color: section.$3,
                onTap: () {
                  if (section.$1 == 'Previous Question Bank') {
                    context.push('/previous-question-bank');
                  } else {
                    _showComingSoon(context, section.$1);
                  }
                },
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
