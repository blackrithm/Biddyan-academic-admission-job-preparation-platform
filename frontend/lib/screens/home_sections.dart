import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../models/models.dart';

/// Study section cards (বাংলা, ইংরেজি, গণিত, সাধারণ জ্ঞান).
class StudySection extends StatelessWidget {
  const StudySection({super.key, required this.onStudyTap});

  final ValueChanged<String> onStudyTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final item
            in const <({String title, String subtitle, IconData icon})>[
          (title: 'বাংলা', subtitle: 'ব্যাকরণ ও সাহিত্য', icon: Icons.auto_stories),
          (title: 'ইংরেজি', subtitle: 'গ্রামার ও ভোকাবুলারি', icon: Icons.language),
          (title: 'গণিত', subtitle: 'পাটিগণিত থেকে জ্যামিতি', icon: Icons.calculate),
          (title: 'সাধারণ জ্ঞান', subtitle: 'বাংলাদেশ ও আন্তর্জাতিক', icon: Icons.public),
        ])
          SizedBox(
            width: 260,
            height: 150,
            child: _StudyCard(
              title: item.title,
              subtitle: item.subtitle,
              icon: item.icon,
              onTap: () => onStudyTap(item.title),
            ),
          ),
      ],
    );
  }
}

class _StudyCard extends StatelessWidget {
  const _StudyCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: AppConstants.accent, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppConstants.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tap-able list of exams that navigates to the live exam room.
class ExamList extends StatelessWidget {
  const ExamList({super.key, required this.exams});

  final List<Exam> exams;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final exam in exams)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                title: Text(exam.title),
                subtitle: Text(
                  '${exam.totalMarks} নম্বর • ${exam.durationMinutes} মিনিট • '
                  'নেগেটিভ ${exam.negativeMarking}',
                ),
                onTap: () => context.go('/exam/${exam.id}'),
              ),
            ),
          ),
      ],
    );
  }
}

/// Simple error placeholder.
class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.message});

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