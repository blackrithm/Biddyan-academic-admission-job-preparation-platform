import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';

final topicsProvider = FutureProvider<List<TopicNode>>((ref) async {
  return TopicService(apiClient).getTree();
});

final topicsNotifierProvider = StateNotifierProvider<TopicsNotifier,
    TopicsState>((ref) => TopicsNotifier());

class TopicsState {
  const TopicsState({this.errorMessage});

  final String? errorMessage;
}

class TopicsNotifier extends StateNotifier<TopicsState> {
  TopicsNotifier() : super(const TopicsState());

  Future<void> createTopic(String name, String? parentId) async {
    await TopicService(apiClient).create({
      'name': name,
      if (parentId != null) 'parent_id': parentId,
    });
  }

  Future<void> deleteTopic(String id) async {
    await TopicService(apiClient).delete(id);
  }
}

class _TopicRow {
  const _TopicRow({required this.node, required this.depth});

  final TopicNode node;
  final int depth;
}

/// Hierarchical topic/sub-topic management panel.
class TopicsPanel extends ConsumerStatefulWidget {
  const TopicsPanel({super.key, required this.topics, required this.notifier});

  final List<TopicNode> topics;
  final TopicsNotifier notifier;

  @override
  ConsumerState<TopicsPanel> createState() => _TopicsPanelState();
}

class _TopicsPanelState extends ConsumerState<TopicsPanel> {
  final nameCtrl = TextEditingController();
  String? parentId;
  String? error;

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flatTopics = <_TopicRow>[];
    void walk(List<TopicNode> nodes, int depth) {
      for (final node in nodes) {
        flatTopics.add(_TopicRow(node: node, depth: depth));
        walk(node.children, depth + 1);
      }
    }
    walk(widget.topics, 0);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'নতুন বিষয়/সাব-টপিক তৈরি করুন',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'বিষয়ের নাম',
                        hintText: 'যেমন: বাংলা সাহিত্য',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: parentId,
                      decoration: const InputDecoration(
                        labelText: 'প্যারেন্ট (ঐচ্ছিক — সাব-টপিকের জন্য)',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('— মূল বিষয় (Root) —'),
                        ),
                        for (final row in flatTopics)
                          DropdownMenuItem(
                            value: row.node.id,
                            child: Text(
                              '${'  ' * row.depth}${row.node.name}',
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() => parentId = value),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: const TextStyle(color: Color(0xFFB91C1C)),
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _create,
                      icon: const Icon(Icons.add),
                      label: const Text('সংরক্ষণ করুন'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ExistingTopics(flatTopics: flatTopics, onDelete: _delete),
          ],
        ),
      ),
    );
  }

  Future<void> _create() async {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => error = 'বিষয়ের নাম লিখুন');
      return;
    }
    try {
      await widget.notifier.createTopic(name, parentId);
      nameCtrl.clear();
      setState(() => error = null);
      ref.invalidate(topicsProvider);
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  Future<void> _delete(String id) async {
    try {
      await widget.notifier.deleteTopic(id);
      ref.invalidate(topicsProvider);
    } catch (e) {
      setState(() => error = e.toString());
    }
  }
}

class _ExistingTopics extends StatelessWidget {
  const _ExistingTopics({required this.flatTopics, required this.onDelete});

  final List<_TopicRow> flatTopics;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'বিদ্যমান বিষয়সমূহ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (flatTopics.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: const Text(
                  'এখনো কোনো বিষয় যোগ করা হয়নি',
                  style: TextStyle(color: AppConstants.mutedText),
                ),
              )
            else
              for (final row in flatTopics)
                ListTile(
                  leading: Icon(
                    row.depth == 0
                        ? Icons.folder
                        : Icons.subdirectory_arrow_right,
                    color: AppConstants.primary,
                  ),
                  title: Text(
                    '${'  ' * row.depth}${row.node.name}',
                  ),
                  trailing: IconButton(
                    tooltip: 'মুছে ফেলুন',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFC62828),
                    ),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('নিশ্চিত করুন'),
                          content: Text(
                            '"${row.node.name}" এবং এর সব সাব-টপিক মুছে ফেলা হবে।',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('বাতিল'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('মুছে ফেলুন'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await onDelete(row.node.id);
                      }
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}