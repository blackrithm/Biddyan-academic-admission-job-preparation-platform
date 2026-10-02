import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/brand_navigation.dart';
import 'mobile_dashboard.dart';

enum ExamTab { live, upcoming, archive }

class ExamCalendarScreen extends StatefulWidget {
  const ExamCalendarScreen({super.key});

  @override
  State<ExamCalendarScreen> createState() => _ExamCalendarScreenState();
}
class _ExamCalendarScreenState extends State<ExamCalendarScreen> {
  ExamTab _tab = ExamTab.live;
  DateTime _selectedDate = DateTime.now();
  bool _dateFilterEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      drawer: const DashboardDrawer(),
      appBar: const BrandHeader(showNotifications: false),
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
          final filtered = exams.where((exam) {
            final matchesStatus = _statusFor(exam) == _tab;
            final examDate = exam.startsAt ?? exam.endsAt;
            final matchesDate = !_dateFilterEnabled ||
                (examDate != null && _sameDate(examDate, _selectedDate));
            return matchesStatus && matchesDate;
          }).toList();
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              _CalendarStrip(
                selectedDate: _selectedDate,
                onChanged: (date) => setState(() => _selectedDate = date),
              ),
              const SizedBox(height: 14),
              _DateFilterBar(
                selectedDate: _selectedDate,
                enabled: _dateFilterEnabled,
                onPick: _pickDate,
                onClear: () => setState(() => _dateFilterEnabled = false),
              ),
              const SizedBox(height: 12),
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

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: _selectedDate,
      helpText: 'পরীক্ষার তারিখ নির্বাচন করুন',
    );
    if (date != null && mounted) {
      setState(() {
        _selectedDate = date;
        _dateFilterEnabled = true;
      });
    }
  }

  static bool _sameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

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
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(exam.topicName ?? 'সকল বিষয়',
                style: const TextStyle(color: AppConstants.mutedText)),
            const Divider(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _ExamMeta(
                    date: _formatDateTime(exam.startsAt ?? DateTime.now()),
                    marks: '${exam.totalMarks.toStringAsFixed(0)} নম্বর',
                  ),
                ),
                const SizedBox(width: 8),
                _ExamActionButton(
                  archived: archived,
                  live: live,
                  onPressed: () {
                    if (archived) {
                      context.push('/exam/${exam.id}/read');
                    } else {
                      _showAction(context, 'পরীক্ষা শুরু করুন');
                    }
                  },
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

class _DateFilterBar extends StatelessWidget {
  const _DateFilterBar({
    required this.selectedDate,
    required this.enabled,
    required this.onPick,
    required this.onClear,
  });

  final DateTime selectedDate;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled ? AppConstants.primary : const Color(0xFFDDE5E5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              enabled ? Icons.event_available_outlined : Icons.event_outlined,
              size: 20,
              color: AppConstants.primary,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                enabled ? 'নির্বাচিত তারিখ: ${_formatDate(selectedDate)}' : 'নির্দিষ্ট তারিখে পরীক্ষা খুঁজুন',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            if (enabled)
              IconButton(
                tooltip: 'তারিখ ফিল্টার মুছুন',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
              ),
            FilledButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.calendar_month_outlined, size: 17),
              label: Text(enabled ? 'তারিখ বদলান' : 'তারিখ নির্বাচন'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 11),
                backgroundColor: AppConstants.primary,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              ),
            ),
          ],
        ),
      );

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _ExamMeta extends StatelessWidget {
  const _ExamMeta({required this.date, required this.marks});

  final String date;
  final String marks;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 5,
        runSpacing: 3,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 15, color: AppConstants.mutedText),
          const Icon(Icons.access_time, size: 15, color: AppConstants.mutedText),
          Text(date, style: const TextStyle(fontSize: 11, color: AppConstants.mutedText)),
          const SizedBox(width: 5),
          const Icon(Icons.people_outline, size: 16, color: AppConstants.mutedText),
          Text(marks, style: const TextStyle(fontSize: 11, color: AppConstants.mutedText)),
        ],
      );
}

class _ExamActionButton extends StatelessWidget {
  const _ExamActionButton({required this.archived, required this.live, required this.onPressed});

  final bool archived;
  final bool live;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final background = archived
        ? AppConstants.primary
        : live
            ? AppConstants.accent
            : const Color(0xFFE7A51B);
    return SizedBox(
      width: archived ? 104 : 96,
      height: 38,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(
          archived ? Icons.menu_book_outlined : (live ? Icons.play_arrow : Icons.notifications_none),
          size: 15,
        ),
        label: Text(
          archived ? 'Read Mode' : (live ? 'Start Exam' : 'Reminder'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: Colors.white,
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

