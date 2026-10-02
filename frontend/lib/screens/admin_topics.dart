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

  Future<void> createTopic(String name, String? parentId, String questionType) async {
    await TopicService(apiClient).create({
      'name': name,
      if (parentId != null) 'parent_id': parentId,
      'question_type': questionType,
    });
  }

  Future<void> deleteTopic(String id) async {
    await TopicService(apiClient).delete(id);
  }

  Future<void> renameTopic(String id, String name, String? parentId) async {
    await TopicService(apiClient).update(id, {
      'name': name,
      'parent_id': parentId,
    });
  }

  Future<void> reorderTopics(String? parentId, List<String> topicIds) async {
    await TopicService(apiClient).reorder(
      parentId: parentId,
      topicIds: topicIds,
    );
  }

  Future<void> moveTopic(String id, String? parentId) async {
    await TopicService(apiClient).move(id, parentId);
  }

  Future<Map<String, dynamic>> copySubtopics({
    required String sourceTopicId,
    required String? targetParentId,
    required List<String> childIds,
    required bool copyQuestions,
  }) {
    return TopicService(apiClient).copySubtopics(
      sourceTopicId: sourceTopicId,
      targetParentId: targetParentId,
      childIds: childIds,
      copyQuestions: copyQuestions,
    );
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
  String questionType = 'mcq';
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
                      onChanged: (value) => setState(() {
                        parentId = value;
                        final selectedParent = flatTopics
                            .where((row) => row.node.id == value)
                            .firstOrNull;
                        questionType = selectedParent?.node.questionType ?? 'mcq';
                      }),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: questionType,
                      decoration: const InputDecoration(labelText: 'প্রশ্নের ধরন'),
                      items: const [
                        DropdownMenuItem(value: 'mcq', child: Text('MCQ')),
                        DropdownMenuItem(value: 'written', child: Text('Written')),
                      ],
                      onChanged: (value) => setState(() => questionType = value ?? 'mcq'),
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
            _ExistingTopics(
              flatTopics: flatTopics,
              onDelete: _delete,
              onRename: _rename,
              onReorder: _reorder,
              onMove: _move,
              onCopy: _copy,
            ),
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
      await widget.notifier.createTopic(name, parentId, questionType);
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

  Future<void> _rename(String id, String name, String? parentId) async {
    try {
      await widget.notifier.renameTopic(id, name, parentId);
      ref.invalidate(topicsProvider);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> _reorder(String? parentId, List<String> topicIds) async {
    try {
      await widget.notifier.reorderTopics(parentId, topicIds);
      ref.invalidate(topicsProvider);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> _move(String id, String? parentId) async {
    try {
      await widget.notifier.moveTopic(id, parentId);
      ref.invalidate(topicsProvider);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<Map<String, dynamic>> _copy({
    required String sourceTopicId,
    required String? targetParentId,
    required List<String> childIds,
    required bool copyQuestions,
  }) async {
    try {
      final result = await widget.notifier.copySubtopics(
        sourceTopicId: sourceTopicId,
        targetParentId: targetParentId,
        childIds: childIds,
        copyQuestions: copyQuestions,
      );
      ref.invalidate(topicsProvider);
      return result;
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
      rethrow;
    }
  }
}

class _ExistingTopics extends StatefulWidget {
  const _ExistingTopics({
    required this.flatTopics,
    required this.onDelete,
    required this.onRename,
    required this.onReorder,
    required this.onMove,
    required this.onCopy,
  });

  final List<_TopicRow> flatTopics;
  final Future<void> Function(String id) onDelete;
  final Future<void> Function(String id, String name, String? parentId) onRename;
  final Future<void> Function(String? parentId, List<String> topicIds) onReorder;
  final Future<void> Function(String id, String? parentId) onMove;
  final Future<Map<String, dynamic>> Function({
    required String sourceTopicId,
    required String? targetParentId,
    required List<String> childIds,
    required bool copyQuestions,
  }) onCopy;

  @override
  State<_ExistingTopics> createState() => _ExistingTopicsState();
}

class _ExistingTopicsState extends State<_ExistingTopics> {
  final _expandedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final visibleTopics = <_TopicRow>[];

    void addVisible(TopicNode node, int depth) {
      visibleTopics.add(_TopicRow(node: node, depth: depth));
      if (_expandedIds.contains(node.id)) {
        for (final child in node.children) {
          addVisible(child, depth + 1);
        }
      }
    }

    for (final row in widget.flatTopics.where((row) => row.depth == 0)) {
      addVisible(row.node, 0);
    }

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
            _rootDropZone(),
            if (widget.flatTopics.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: const Text(
                  'এখনো কোনো বিষয় যোগ করা হয়নি',
                  style: TextStyle(color: AppConstants.mutedText),
                ),
              )
            else
              for (final row in visibleTopics)
                _buildTopicRow(row),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicRow(_TopicRow row) => DragTarget<_TopicRow>(
        onWillAcceptWithDetails: (details) =>
            details.data.node.id != row.node.id &&
            !_containsTopic(details.data.node, row.node.id),
        onAcceptWithDetails: (details) {
          if (details.data.node.parentId == row.node.parentId) {
            _reorderSiblings(details.data, row);
          } else {
            setState(() => _expandedIds.add(row.node.id));
            widget.onMove(details.data.node.id, row.node.id);
          }
        },
        builder: (context, candidateData, rejectedData) {
          final tile = ListTile(
            contentPadding: EdgeInsets.only(left: row.depth * 24.0, right: 0),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.drag_indicator, color: AppConstants.mutedText, size: 20),
                const SizedBox(width: 4),
                Icon(
                  row.depth == 0 ? Icons.folder : Icons.subdirectory_arrow_right,
                  color: AppConstants.primary,
                ),
              ],
            ),
            title: Text(row.node.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(row.node.questionType == 'written' ? 'Written' : 'MCQ'),
            onTap: row.node.children.isEmpty
                ? null
                : () => setState(() {
                      if (!_expandedIds.add(row.node.id)) {
                        _expandedIds.remove(row.node.id);
                      }
                    }),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (row.node.children.isNotEmpty)
                  Icon(
                    _expandedIds.contains(row.node.id)
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppConstants.primary,
                  ),
                if (row.node.children.isNotEmpty)
                  IconButton(
                    tooltip: 'সাব-টপিক কপি করুন',
                    icon: const Icon(Icons.copy_all_outlined, color: AppConstants.primary),
                    onPressed: () => _copySubtopics(row),
                  ),
                IconButton(
                  tooltip: 'নাম পরিবর্তন করুন',
                  icon: const Icon(Icons.edit_outlined, color: AppConstants.primary),
                  onPressed: () => _editTopic(row),
                ),
                IconButton(
                  tooltip: 'মুছে ফেলুন',
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFC62828)),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('নিশ্চিত করুন'),
                        content: Text(
                          '"${row.node.name}", এর সব সাব-টপিক এবং যুক্ত MCQ মুছে ফেলা হবে।',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            child: const Text('বাতিল'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text('মুছে ফেলুন'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) await widget.onDelete(row.node.id);
                  },
                ),
              ],
            ),
          );

          return Draggable<_TopicRow>(
            data: row,
            affinity: Axis.vertical,
            axis: Axis.vertical,
            feedback: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: 320,
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.drag_indicator),
                    title: Text(row.node.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.35, child: tile),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: candidateData.isNotEmpty ? AppConstants.background : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: tile,
            ),
          );
        },
      );

  Widget _rootDropZone() => DragTarget<_TopicRow>(
        onWillAcceptWithDetails: (details) => details.data.node.parentId != null,
        onAcceptWithDetails: (details) => widget.onMove(details.data.node.id, null),
        builder: (context, candidateData, rejectedData) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty ? AppConstants.background : Colors.transparent,
            border: Border.all(color: AppConstants.primary.withValues(alpha: .18)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.north, size: 18, color: AppConstants.primary),
              SizedBox(width: 8),
              Text('এখানে drop করলে মূল বিষয় হবে'),
            ],
          ),
        ),
      );

  bool _containsTopic(TopicNode root, String targetId) {
    if (root.id == targetId) return true;
    return root.children.any((child) => _containsTopic(child, targetId));
  }

  Future<void> _copySubtopics(_TopicRow source) async {
    final children = source.node.children;
    if (children.isEmpty) return;
    final excludedIds = <String>{};
    void collectIds(TopicNode node) {
      excludedIds.add(node.id);
      for (final child in node.children) {
        collectIds(child);
      }
    }

    collectIds(source.node);
    final destinations = widget.flatTopics
        .where((row) => !excludedIds.contains(row.node.id))
        .toList();
    final selectedIds = children.map((child) => child.id).toSet();
    var targetValue = '__root__';
    var includeQuestions = false;
    final selection = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('"${source.node.name}"-এর subtopic copy'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('কোন topic-এর অধীনে copy করবেন?'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: targetValue,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'গন্তব্য topic'),
                    items: [
                      const DropdownMenuItem(
                        value: '__root__',
                        child: Text('মূল বিষয় (Root)'),
                      ),
                      for (final destination in destinations)
                        DropdownMenuItem(
                          value: destination.node.id,
                          child: Text(
                            '${'  ' * destination.depth}${destination.node.name}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => setDialogState(
                      () => targetValue = value ?? '__root__',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'কপি করার subtopic',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setDialogState(() {
                          if (selectedIds.length == children.length) {
                            selectedIds.clear();
                          } else {
                            selectedIds.addAll(children.map((child) => child.id));
                          }
                        }),
                        child: Text(selectedIds.length == children.length ? 'কেউ না' : 'সব'),
                      ),
                    ],
                  ),
                  for (final child in children)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: selectedIds.contains(child.id),
                      title: Text(child.name),
                      subtitle: child.children.isEmpty
                          ? null
                          : Text('${child.children.length}টি nested subtopic-সহ'),
                      onChanged: (selected) => setDialogState(() {
                        if (selected == true) {
                          selectedIds.add(child.id);
                        } else {
                          selectedIds.remove(child.id);
                        }
                      }),
                    ),
                  const Divider(),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: includeQuestions,
                    title: const Text('MCQ-সহ copy করুন'),
                    subtitle: const Text('নির্বাচিত subtopic ও nested topic-এর প্রশ্নও কপি হবে'),
                    onChanged: (value) => setDialogState(
                      () => includeQuestions = value ?? false,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('বাতিল'),
            ),
            FilledButton(
              onPressed: selectedIds.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, {
                        'childIds': selectedIds.toList(),
                        'targetParentId': targetValue == '__root__' ? null : targetValue,
                        'copyQuestions': includeQuestions,
                      }),
              child: const Text('Copy করুন'),
            ),
          ],
        ),
      ),
    );
    if (selection == null) return;
    try {
      final result = await widget.onCopy(
        sourceTopicId: source.node.id,
        targetParentId: selection['targetParentId'] as String?,
        childIds: (selection['childIds'] as List<dynamic>).cast<String>(),
        copyQuestions: selection['copyQuestions'] as bool,
      );
      if (!mounted) return;
      final questionCount = result['copiedQuestions'] as int? ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result['copiedTopics']}টি subtopic${includeQuestions ? ' এবং $questionCountটি MCQ' : ''} copy হয়েছে',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subtopic copy করা যায়নি: $error')),
        );
      }
    }
  }

  Future<void> _editTopic(_TopicRow row) async {
    final controller = TextEditingController(text: row.node.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('বিষয়ের নাম পরিবর্তন'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'বিষয়ের নাম'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('সংরক্ষণ'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmedName = name?.trim();
    if (trimmedName == null || trimmedName.isEmpty || trimmedName == row.node.name) return;
    await widget.onRename(row.node.id, trimmedName, row.node.parentId);
  }

  Future<void> _reorderSiblings(_TopicRow source, _TopicRow target) async {
    if (source.node.parentId != target.node.parentId) return;
    final topicIds = widget.flatTopics
        .where((row) => row.node.parentId == source.node.parentId)
        .map((row) => row.node.id)
        .toList();
    final sourceIndex = topicIds.indexOf(source.node.id);
    final targetIndex = topicIds.indexOf(target.node.id);
    if (sourceIndex < 0 || targetIndex < 0) return;
    final sourceId = topicIds[sourceIndex];
    topicIds[sourceIndex] = topicIds[targetIndex];
    topicIds[targetIndex] = sourceId;
    await widget.onReorder(source.node.parentId, topicIds);
  }
}