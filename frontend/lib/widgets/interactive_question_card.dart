import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/models.dart';

class InteractiveQuestionCard extends StatefulWidget {
  const InteractiveQuestionCard({super.key, required this.index, required this.question});

  final int index;
  final Question question;

  @override
  State<InteractiveQuestionCard> createState() => _InteractiveQuestionCardState();
}

class _InteractiveQuestionCardState extends State<InteractiveQuestionCard> {
  bool _showAnswer = false;
  bool _showExplanation = false;
  bool _bookmarked = false;
  String? _selectedOption;

  static const _labels = ['ক', 'খ', 'গ', 'ঘ'];
  static const _keys = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text('প্রশ্ন ${widget.index}\n${question.questionText}',
                      style: const TextStyle(fontSize: 16, height: 1.4, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  tooltip: _bookmarked ? 'বুকমার্ক সরান' : 'বুকমার্ক করুন',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _bookmarked = !_bookmarked),
                  icon: Icon(_bookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: _bookmarked ? AppConstants.accent : AppConstants.mutedText),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < question.options.length; index++)
              _InteractiveOptionRow(
                label: _labels[index],
                text: question.options[index],
                selected: _selectedOption == _keys[index],
                correct: _showAnswer && question.correctOption == _keys[index],
                incorrect: _showAnswer && _selectedOption == _keys[index] && question.correctOption != _keys[index],
                onTap: () => setState(() => _selectedOption = _keys[index]),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _InteractiveActionChip(
                  icon: _showAnswer ? Icons.visibility_off : Icons.visibility,
                  label: _showAnswer ? 'উত্তর লুকান' : 'উত্তর দেখুন',
                  onPressed: () => setState(() => _showAnswer = !_showAnswer),
                ),
                if (question.explanation?.trim().isNotEmpty == true)
                  _InteractiveActionChip(
                    icon: Icons.lightbulb_outline,
                    label: 'ব্যাখ্যা',
                    onPressed: () => setState(() => _showExplanation = !_showExplanation),
                  ),
              ],
            ),
            if (_showExplanation && question.explanation?.trim().isNotEmpty == true)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('ব্যাখ্যা: ${question.explanation}'),
              ),
          ],
        ),
      ),
    );
  }
}

class _InteractiveOptionRow extends StatelessWidget {
  const _InteractiveOptionRow({required this.label, required this.text, required this.selected, required this.correct, required this.incorrect, required this.onTap});

  final String label;
  final String text;
  final bool selected;
  final bool correct;
  final bool incorrect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = correct ? Colors.green : incorrect ? AppConstants.accent : selected ? AppConstants.primary : Colors.transparent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: correct || incorrect || selected ? 0.1 : 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color == Colors.transparent ? const Color(0xFFE5E8E7) : color),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: color == Colors.transparent ? const Color(0xFF9DEBF6) : color,
                child: Text(label, style: TextStyle(color: color == Colors.transparent ? AppConstants.primary : Colors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(text)),
              if (correct) const Icon(Icons.check_circle, color: Colors.green, size: 20),
              if (incorrect) const Icon(Icons.cancel, color: AppConstants.accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionChip extends StatelessWidget {
  const _InteractiveActionChip({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: Icon(icon, size: 16, color: AppConstants.primary),
        label: Text(label),
        onPressed: onPressed,
      );
}
