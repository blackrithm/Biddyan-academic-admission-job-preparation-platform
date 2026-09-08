import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/models.dart';

/// Renders a single question with Bengali option cards (ক, খ, গ, ঘ).
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.index,
    required this.question,
    required this.onSelect,
    this.selectedOption,
    this.onPrevious,
    this.onNext,
  });

  final int index;
  final Question question;
  final String? selectedOption;
  final ValueChanged<String> onSelect;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final options = <({String key, String text})>[
      (key: 'A', text: question.optionA),
      (key: 'B', text: question.optionB),
      (key: 'C', text: question.optionC),
      (key: 'D', text: question.optionD),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'প্রশ্ন ${index + 1}',
                style: const TextStyle(
                  color: AppConstants.mutedText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                question.questionText,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              for (final (i, option) in options.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OptionCard(
                    label: AppConstants.bengaliOptionLabels[i],
                    text: option.text,
                    isSelected: selectedOption == option.key,
                    onTap: () => onSelect(option.key),
                  ),
                ),
              if (onPrevious != null || onNext != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (onPrevious != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onPrevious,
                          child: const Text('আগের প্রশ্ন'),
                        ),
                      ),
                    if (onPrevious != null && onNext != null)
                      const SizedBox(width: 8),
                    if (onNext != null)
                      Expanded(
                        child: FilledButton(
                          onPressed: onNext,
                          child: const Text('পরের প্রশ্ন'),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.label,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? AppConstants.primary : Colors.white;
    return Card.outlined(
      color: bg,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppConstants.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF111827),
                    height: 1.4,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class QuestionPalette extends StatelessWidget {
  const QuestionPalette({
    super.key,
    required this.count,
    required this.selectedCount,
    required this.currentIndex,
    required this.onSelect,
  });

  final int count;
  final int selectedCount;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'প্রশ্ন তালিকা ($selectedCount/$count উত্তর দেওয়া)',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < count; i++)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: _PaletteDot(
                      number: i + 1,
                      isCurrent: i == currentIndex,
                      isAnswered: i < selectedCount,
                      onTap: () => onSelect(i),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteDot extends StatelessWidget {
  const _PaletteDot({
    required this.number,
    required this.isCurrent,
    required this.isAnswered,
    required this.onTap,
  });

  final int number;
  final bool isCurrent;
  final bool isAnswered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isCurrent
        ? AppConstants.accent
        : (isAnswered ? AppConstants.primary : const Color(0xFFE2E8F0));
    final textColor =
        (isCurrent || isAnswered) ? Colors.white : const Color(0xFF111827);
    return CircleAvatar(
      backgroundColor: color,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}