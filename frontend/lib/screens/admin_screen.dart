import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'admin_question_form.dart';
import 'admin_topics.dart';

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
      body: const _TabbedAdmin(),
    );
  }
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
                : AdminQuestionForm(topics: rows),
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