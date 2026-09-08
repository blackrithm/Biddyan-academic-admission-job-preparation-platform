import 'package:flutter/material.dart';

/// Bengali-labelled radio row for one MCQ option in the admin form.
class OptionField extends StatelessWidget {
  const OptionField({
    super.key,
    required this.label,
    required this.controller,
    required this.isSelected,
    required this.onPick,
  });

  final String label;
  final TextEditingController controller;
  final bool isSelected;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Radio<String>(
            value: label,
            groupValue: isSelected ? label : null,
            onChanged: (_) => onPick(),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                labelText: 'অপশন $label',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Multi-select chip group for `previous_years` TEXT[] tags.
class PreviousYearsTags extends StatelessWidget {
  const PreviousYearsTags({
    super.key,
    required this.tags,
    required this.suggested,
    required this.tagCtrl,
    required this.onToggle,
    required this.onAddCustom,
  });

  final List<String> tags;
  final List<String> suggested;
  final TextEditingController tagCtrl;
  final ValueChanged<String> onToggle;
  final VoidCallback onAddCustom;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'পূর্ববর্তী বছরের পরীক্ষা ট্যাগ (Previous Years)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in suggested)
                  FilterChip(
                    label: Text(tag),
                    selected: tags.contains(tag),
                    onSelected: (_) => onToggle(tag),
                  ),
                for (final tag in tags)
                  if (!suggested.contains(tag))
                    InputChip(
                      label: Text(tag),
                      onDeleted: () => onToggle(tag),
                    ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tagCtrl,
                    decoration: const InputDecoration(
                      labelText: 'কাস্টম ট্যাগ',
                      hintText: 'যেমন: 46th BCS',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'যোগ করুন',
                  onPressed: onAddCustom,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Save button plus inline error/success messaging.
class SaveSection extends StatelessWidget {
  const SaveSection({
    super.key,
    required this.saving,
    required this.error,
    required this.success,
    required this.onSave,
  });

  final bool saving;
  final String? error;
  final String? success;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null)
          Text(
            error!,
            style: const TextStyle(color: Color(0xFFB91C1C)),
          ),
        if (success != null)
          Text(
            success!,
            style: const TextStyle(color: Color(0xFF1B8730)),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: saving ? null : () => onSave(),
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: const Text('PostgreSQL-এ সংরক্ষণ করুন'),
        ),
      ],
    );
  }
}