import 'package:flutter/material.dart';

import '../widgets/brand_navigation.dart';
import 'mobile_dashboard.dart';

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  static const _items = [
    _BookItem('BCS প্রস্তুতি', 'BCS ও সরকারি চাকরির প্রস্তুতির বই', Icons.menu_book, '১২টি বই'),
    _BookItem('SSC ও HSC', 'স্কুল ও কলেজের পাঠ্য সহায়ক বই', Icons.school, '৮টি বই'),
    _BookItem('Admission', 'বিশ্ববিদ্যালয় ভর্তি প্রস্তুতির বই', Icons.account_balance, '১০টি বই'),
    _BookItem('PDF Notes', 'বিষয়ভিত্তিক short notes ও PDF', Icons.picture_as_pdf, '২৪টি PDF'),
    _BookItem('Model Test', 'প্র্যাকটিস সেট ও model test materials', Icons.assignment, '১৮টি সেট'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DashboardDrawer(),
      appBar: const BrandHeader(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: [
          Text('আপনার প্রস্তুতির জন্য', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text('বই, PDF notes এবং model test এক জায়গায় দেখুন।'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE4F7F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_stories, size: 32, color: Color(0xFF006B72)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'আজকের পড়াশোনার জন্য একটি resource বেছে নিন।',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final item in _items)
            Card(
              margin: const EdgeInsets.only(bottom: 9),
              child: ListTile(
                minTileHeight: 68,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFD9F3F5),
                  foregroundColor: const Color(0xFF006B72),
                  child: Icon(item.icon),
                ),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${item.description}\n${item.count}'),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showResourceMessage(context, item.title),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BrandBottomNavigation(
        selectedIndex: 1,
        onSelected: (index) => BrandBottomNavigation.navigate(context, index),
      ),
    );
  }

  static void _showResourceMessage(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title-এর materials শীঘ্রই দেখা যাবে।')),
    );
  }
}

class _BookItem {
  const _BookItem(this.title, this.description, this.icon, this.count);

  final String title;
  final String description;
  final IconData icon;
  final String count;
}
