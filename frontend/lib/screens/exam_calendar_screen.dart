import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/constants.dart';

enum ExamTab { live, upcoming, archive }

class ExamCalendarScreen extends StatefulWidget {
  const ExamCalendarScreen({super.key});

  @override
  State<ExamCalendarScreen> createState() => _ExamCalendarScreenState();
}

class _ExamCalendarScreenState extends State<ExamCalendarScreen> {
  ExamTab _tab = ExamTab.live;
  DateTime _selectedDate = DateTime.now();

  static final _exams = [
    _ExamItem(
      title: 'দৈনিক মডেল টেস্ট - বাংলাদেশ বিষয়াবলি',
      category: 'বাংলাদেশ বিষয়াবলি',
      date: DateTime(2026, 9, 9, 20, 0),
      participants: 134,
      status: ExamTab.live,
    ),
    _ExamItem(
      title: 'BCS প্রিলি পূর্ণাঙ্গ প্রস্তুতি',
      category: 'সকল বিষয়',
      date: DateTime(2026, 9, 12, 20, 0),
      participants: 280,
      status: ExamTab.upcoming,
    ),
    _ExamItem(
      title: 'মেডিকেল ভর্তি প্রস্তুতি',
      category: 'সাধারণ বিজ্ঞান',
      date: DateTime(2026, 9, 15, 19, 0),
      participants: 192,
      status: ExamTab.upcoming,
    ),
    _ExamItem(
      title: 'ভূগোল ও পরিবেশ - ফাইনাল প্রস্তুতি',
      category: 'ভূগোল',
      date: DateTime(2026, 4, 17, 20, 0),
      participants: 134,
      status: ExamTab.archive,
    ),
    _ExamItem(
      title: 'মার্কেটিং ২য় বর্ষ - নিজেকে যাচাই',
      category: 'ব্যবস্থাপনা',
      date: DateTime(2026, 4, 4, 20, 0),
      participants: 102,
      status: ExamTab.archive,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _exams.where((exam) => exam.status == _tab).toList();
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
      body: ListView(
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
      ),
      bottomNavigationBar: const _ExamBottomNavigation(),
    );
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

class _ExamBottomNavigation extends StatelessWidget {
  const _ExamBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 2,
      onDestinationSelected: (index) {
        if (index == 0) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (index == 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('প্রোফাইল শীঘ্রই যুক্ত হবে।')),
          );
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'হোম',
        ),
        NavigationDestination(
          icon: Icon(Icons.handshake_outlined),
          selectedIcon: Icon(Icons.handshake),
          label: 'আমার সেকশন',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment),
          label: 'পরীক্ষা',
        ),
        NavigationDestination(
          icon: Icon(Icons.edit_calendar_outlined),
          selectedIcon: Icon(Icons.edit_calendar),
          label: 'রুটিন',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'প্রোফাইল',
        ),
      ],
    );
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
  final _ExamItem exam;

  @override
  Widget build(BuildContext context) {
    final live = exam.status == ExamTab.live;
    final archived = exam.status == ExamTab.archive;
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
            Text(exam.category,
                style: const TextStyle(color: AppConstants.mutedText)),
            const Divider(height: 18),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: AppConstants.mutedText),
                const SizedBox(width: 5),
                Text(_formatDate(exam.date)),
                const SizedBox(width: 16),
                const Icon(Icons.people_outline,
                    size: 17, color: AppConstants.mutedText),
                const SizedBox(width: 5),
                Text('${exam.participants} জন'),
                const Spacer(),
                FilledButton(
                  onPressed: () => _showAction(
                      context, archived ? 'ফলাফল দেখুন' : 'পরীক্ষা শুরু করুন'),
                  child: Text(archived
                      ? 'ফলাফল'
                      : (live ? 'Start Exam' : 'রিমাইন্ডার')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static void _showAction(BuildContext context, String action) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$action শীঘ্রই যুক্ত হবে।')));
  }
}

class _ExamItem {
  const _ExamItem({
    required this.title,
    required this.category,
    required this.date,
    required this.participants,
    required this.status,
  });

  final String title;
  final String category;
  final DateTime date;
  final int participants;
  final ExamTab status;
}
