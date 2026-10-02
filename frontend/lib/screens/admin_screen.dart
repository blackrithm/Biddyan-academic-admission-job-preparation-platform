import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'admin_question_form.dart';
import 'admin_question_bank.dart';
import 'admin_exam_form.dart';
import 'admin_topics.dart';
import '../widgets/brand_navigation.dart';
import 'home_screen.dart';

/// Admin Panel (Flutter Web).
///
/// Two tabs:
///  1. "বিষয়সমূহ" — hierarchical category/sub-topic management with
///     create / rename / delete.
///  2. "প্রশ্ন যোগ করুন" — MCQ form: topic selector, 4 options, correct
///     answer radio, rich-text explanation and multi-select previous-year tags.
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('অ্যাডমিন প্যানেল'),
        actions: [
          IconButton(
            tooltip: 'হোম',
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: const _AdminManagementHub(),
      bottomNavigationBar: BrandBottomNavigation(
        selectedIndex: 4,
        onSelected: (index) => BrandBottomNavigation.navigate(context, index),
      ),
    );
  }
}

class _AdminManagementHub extends StatelessWidget {
  const _AdminManagementHub();

  @override
  Widget build(BuildContext context) {
    final options = [
      _AdminOption('পরীক্ষা পরিচালনা', 'Exam তৈরি, প্রশ্ন সেট ও সময় manage করুন', Icons.assignment_outlined, '/admin/exams'),
      _AdminOption('এক্সাম ব্যাচ', 'বিভিন্ন ধরনের batch ও exam schedule তৈরি করুন', Icons.groups_outlined, '/admin/exam-batches'),
      _AdminOption('Photo & Share', 'ছবি, banner ও media share করুন', Icons.photo_library_outlined, '/admin/media'),
      _AdminOption('সব MCQ পরিচালনা', 'MCQ edit, update ও question bank manage করুন', Icons.quiz_outlined, '/admin/mcqs'),
      _AdminOption('Notification পরিচালনা', 'শিক্ষার্থীদের notice publish করুন', Icons.notifications_active_outlined, '/admin/notifications'),
      _AdminOption('Books, PDF & Materials', 'Book, PDF ও study material যোগ করুন', Icons.menu_book_outlined, '/admin/materials'),
      _AdminOption('Question Bank', 'Question set upload ও manage করুন', Icons.library_books_outlined, '/admin/question-bank'),
      _AdminOption('Exam Result Manage & Edit', 'পরীক্ষার ফলাফল দেখুন ও edit করুন', Icons.fact_check_outlined, '/admin/results'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Text('কী পরিচালনা করবেন?', style: Theme.of(context).textTheme.headlineSmall),
          ),
          const SizedBox(height: 4),
          const Text('একটি section নির্বাচন করলে সেটি আলাদা management page-এ খুলবে.'),
          const SizedBox(height: 14),
          for (final option in options) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                minTileHeight: 64,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                leading: CircleAvatar(radius: 20, child: Icon(option.icon, size: 21)),
                title: Text(option.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(option.description),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(option.path),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminOption {
  const _AdminOption(this.title, this.description, this.icon, this.path);

  final String title;
  final String description;
  final IconData icon;
  final String path;
}

class _TabbedAdmin extends ConsumerStatefulWidget {
  const _TabbedAdmin();

  @override
  ConsumerState<_TabbedAdmin> createState() => _TabbedAdminState();
}

class _TabbedAdminState extends ConsumerState<_TabbedAdmin> {
  int _section = 0;

  @override
  Widget build(BuildContext context) {
    final topics = ref.watch(topicsProvider);
    final notifier = ref.read(topicsNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                icon: Icon(Icons.account_tree),
                label: Text('বিষয়সমূহ'),
              ),
              ButtonSegment(
                value: 1,
                icon: Icon(Icons.quiz),
                label: Text('প্রশ্ন যোগ করুন'),
              ),
              ButtonSegment(
                value: 2,
                icon: Icon(Icons.event),
                label: Text('পরীক্ষা তৈরি'),
              ),
              ButtonSegment(
                value: 3,
                icon: Icon(Icons.library_books),
                label: Text('Question Bank'),
              ),
            ],
            selected: {_section},
            onSelectionChanged: (selection) =>
                setState(() => _section = selection.first),
          ),
        ),
        Expanded(
          child: topics.when(
            data: (rows) => _section == 0
                ? TopicsPanel(topics: rows, notifier: notifier)
                : _section == 1
                    ? AdminQuestionForm(topics: rows)
                    : _section == 2
                        ? AdminExamForm(
                        topics: rows,
                        onCreated: () => ref.invalidate(examsProvider),
                          )
                        : AdminQuestionBank(topics: rows),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorCard(message: error.toString()),
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'লোড করা যায়নি: $message',
          style: const TextStyle(color: Color(0xFFB91C1C)),
        ),
      ),
    );
  }
}
