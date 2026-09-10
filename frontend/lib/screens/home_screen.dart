import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import 'home_sections.dart';

/// Home Dashboard — package banner, exam categories, study section and
/// navigation drawer. Responsive across Flutter Web and mobile.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _categories = <({String title, IconData icon})>[
    
    (title: 'SSC', icon: Icons.school),
    (title: 'HSC', icon: Icons.account_balance),
    (title: 'Varsity', icon: Icons.school),
    (title: 'Medical', icon: Icons.account_balance),
    (title: 'Engineering', icon: Icons.school),
    (title: 'Agriculture', icon: Icons.account_balance),
    (title: 'BCS প্রস্তুতি', icon: Icons.school),
    (title: 'ব্যাংক জব', icon: Icons.account_balance),
    (title: 'সরকারি চাকরি', icon: Icons.work),
    (title: 'নন-ক্যাডার', icon: Icons.badge),
    (title: 'প্রাইমারি', icon: Icons.child_care),
    (title: 'ভর্তি পরীক্ষা', icon: Icons.how_to_reg),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final examsAsync = ref.watch(examsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('বিদ্বান'),
        actions: [
          if (authState.isLoggedIn)
            IconButton(
              tooltip: 'লগআউট',
              icon: const Icon(Icons.logout),
              onPressed: () =>
                  ref.read(authNotifierProvider.notifier).logout(),
            ),
        ],
      ),
      drawer: const _AppDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _PackageBanner(),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'পরীক্ষা সেকশন'),
              const SizedBox(height: 12),
              _CategoryGrid(
                categories: _categories,
                onCategoryTap: (category) => context.go(
                  '/subject-catalog?category=${Uri.encodeComponent(category)}',
                ),
              ),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'স্টাডি সেকশন'),
              const SizedBox(height: 12),
              StudySection(
                onStudyTap: (subject) => _showSectionMessage(
                  context,
                  subject,
                  'এই বিষয়ের স্টাডি কনটেন্ট খুব শীঘ্রই যুক্ত হবে।',
                ),
              ),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'সাম্প্রতিক পরীক্ষা'),
              const SizedBox(height: 12),
              examsAsync.when(
                data: (exams) => ExamList(exams: exams),
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => ErrorCard(message: error.toString()),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

void _showSectionMessage(
  BuildContext context,
  String title,
  String message,
) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ঠিক আছে'),
        ),
      ],
    ),
  );
}

/// Recent exams fetched from `GET /api/v1/exams`.
final examsProvider = FutureProvider<List<Exam>>((ref) async {
  return ExamService(apiClient).list();
});

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        Navigator.of(context).pop();
        if (index == 4) {
          context.go('/admin');
        } else if (index > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('এই সেকশনটি খুব শীঘ্রই যুক্ত হবে।')),
          );
        }
      },
      children: const <Widget>[
        NavigationDrawerDestination(
          icon: Icon(Icons.home),
          label: Text('হোম'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.school),
          label: Text('পরীক্ষা'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.menu_book),
          label: Text('স্টাডি'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.bar_chart),
          label: Text('রেজাল্ট'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.settings),
          label: Text('অ্যাডমিন'),
        ),
      ],
    );
  }
}

class _PackageBanner extends StatelessWidget {
  const _PackageBanner();

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      color: const Color(0xFFEAF4EC),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final content = [
            const Icon(
              Icons.workspace_premium,
              color: AppConstants.golden,
              size: 32,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'প্রিমিয়াম প্যাকেজ সক্রিয় — সব কোর্সে আনলিমিটেড অ্যাক্সেস',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton(
              onPressed: () => _showSectionMessage(
                context,
                'প্রিমিয়াম প্যাকেজ',
                'আপনার প্রিমিয়াম প্যাকেজ সক্রিয় আছে।',
              ),
              child: const Text('প্যাকেজ দেখুন'),
            ),
          ];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [content[0], content[1], content[2]]),
                      const SizedBox(height: 12),
                      content[3],
                    ],
                  )
                : Row(children: content),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.onCategoryTap,
  });

  final List<({String title, IconData icon})> categories;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 360 ? 1 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final category in categories)
              SizedBox(
                width: width,
                height: 108,
                child: _CategoryCard(
                  title: category.title,
                  icon: category.icon,
                  onTap: () => onCategoryTap(category.title),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppConstants.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: Icon(icon, color: AppConstants.primary, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14,
                  color: AppConstants.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}
