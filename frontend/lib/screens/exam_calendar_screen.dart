import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/brand_navigation.dart';

enum ExamTab { live, upcoming, archive }

class ExamCalendarScreen extends StatefulWidget {
  const ExamCalendarScreen({super.key});

  @override
  State<ExamCalendarScreen> createState() => _ExamCalendarScreenState();
}
class _ExamCalendarScreenState extends State<ExamCalendarScreen> {
  ExamTab _tab = ExamTab.live;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        title: const Text('পরীক্ষা ক্যালেন্ডার'),
        actions: [
          IconButton(
            tooltip: 'ক্যালেন্ডার',
            icon: const FaIcon(FontAwesomeIcons.calendarDays, size: 20),
            onPressed: () => _pickDate(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Exam>>(
        future: ExamService(apiClient).list(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('পরীক্ষা লোড করা যায়নি: ${snapshot.error}'),
              ),
            );
          }
          final exams = snapshot.data ?? const <Exam>[];
          final filtered = exams
              .where((exam) => _statusFor(exam) == _tab)
              .toList();
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              _CalendarStrip(
                selectedDate: _selectedDate,
                onChanged: (date) => setState(() => _selectedDate = date),
              ),
              const SizedBox(height: 14),
              SegmentedButton<ExamTab>(
                segments: const [
                  ButtonSegment(
                      value: ExamTab.live,
                      label: Text('লাইভ পরীক্ষা'),
                      icon: Icon(Icons.play_circle)),
                  ButtonSegment(
                      value: ExamTab.upcoming,
                      label: Text('আসন্ন পরীক্ষা'),
                      icon: Icon(Icons.schedule)),
                  ButtonSegment(
                      value: ExamTab.archive,
                      label: Text('আর্কাইভ'),
                      icon: Icon(Icons.archive)),
                ],
                selected: {_tab},
                onSelectionChanged: (value) => setState(() => _tab = value.first),
              ),
              const SizedBox(height: 14),
              if (filtered.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(child: Text('এই বিভাগে কোনো পরীক্ষা নেই')),
                  ),
                )
              else
                for (final exam in filtered) _ExamCard(exam: exam),
            ],
          );
        },
      ),
      bottomNavigationBar: BrandBottomNavigation(
        selectedIndex: 2,
        onSelected: (index) => BrandBottomNavigation.navigate(context, index),
      ),
    );
  }

  static ExamTab _statusFor(Exam exam) {
    final now = DateTime.now();
    if (exam.endsAt != null && !now.isBefore(exam.endsAt!)) {
      return ExamTab.archive;
    }
    if (exam.startsAt != null && now.isBefore(exam.startsAt!)) {
      return ExamTab.upcoming;
    }
    if (exam.isLive || exam.startsAt != null) {
      return ExamTab.live;
    }
    return ExamTab.upcoming;
  }

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      initialDate: _selectedDate,
    );
    if (date != null) setState(() => _selectedDate = date);
  }
}
class _CalendarStrip extends StatelessWidget {
  const _CalendarStrip({required this.selectedDate, required this.onChanged});

  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final start =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final date = start.add(Duration(days: index));
            final selected = date.day == selectedDate.day &&
                date.month == selectedDate.month &&
                date.year == selectedDate.year;
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(date),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 7),
                decoration: BoxDecoration(
                  color: selected ? AppConstants.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      _weekday(date.weekday),
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? Colors.white : AppConstants.mutedText,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  String _weekday(int value) => const [
        'সোম',
        'মঙ্গল',
        'বুধ',
        'বৃহস্পতি',
        'শুক্র',
        'শনি',
        'রবি'
      ][value - 1];
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam});
  final Exam exam;

  @override
  Widget build(BuildContext context) {
    final status = _ExamCalendarScreenState._statusFor(exam);
    final live = status == ExamTab.live;
    final archived = status == ExamTab.archive;
    final color = live ? Colors.green : (archived ? Colors.red : Colors.orange);
    final label = live ? 'Live' : (archived ? 'Ended' : 'Upcoming');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    exam.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                Chip(
                  label: Text(label),
                  backgroundColor: color.withValues(alpha: 0.12),
                  labelStyle:
                      TextStyle(color: color, fontWeight: FontWeight.w700),
                  side: BorderSide.none,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(exam.topicName ?? 'সকল বিষয়',
                style: const TextStyle(color: AppConstants.mutedText)),
            const Divider(height: 18),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: AppConstants.mutedText),
                const SizedBox(width: 5),
                const Icon(Icons.access_time,
                    size: 16, color: AppConstants.mutedText),
                const SizedBox(width: 5),
                Text(_formatDateTime(exam.startsAt ?? DateTime.now())),
                const SizedBox(width: 16),
                const Icon(Icons.people_outline,
                    size: 17, color: AppConstants.mutedText),
                const SizedBox(width: 5),
                Text('${exam.totalMarks.toStringAsFixed(0)} নম্বর'),
                const Spacer(),
                SizedBox(
                  width: 96,
                  height: 42,
                  child: FilledButton(
                    onPressed: () => _showAction(
                        context, archived ? 'ফলাফল দেখুন' : 'পরীক্ষা শুরু করুন'),
                    style: FilledButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: Text(archived
                        ? 'ফলাফল'
                        : (live ? 'Start Exam' : 'রিমাইন্ডার')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }

  static void _showAction(BuildContext context, String action) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$action শীঘ্রই যুক্ত হবে।')));
  }
}

