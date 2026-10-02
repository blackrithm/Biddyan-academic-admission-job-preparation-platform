import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/brand_navigation.dart';

const _preparationCategories = <(String, IconData)>[
  ('SSC', FontAwesomeIcons.school),
  ('HSC', FontAwesomeIcons.school),
  ('Varsity', FontAwesomeIcons.buildingColumns),
  ('Medical', FontAwesomeIcons.userDoctor),
  ('Engineering', FontAwesomeIcons.gears),
  ('Agriculture', FontAwesomeIcons.seedling),
  ('BCS প্রস্তুতি', FontAwesomeIcons.buildingColumns),
  ('শিক্ষক নিবন্ধন', FontAwesomeIcons.graduationCap),
  ('বার কাউন্সিল', FontAwesomeIcons.scaleBalanced),
  ('ব্যাংক জব', FontAwesomeIcons.buildingColumns),
  ('সরকারি চাকরি', FontAwesomeIcons.landmark),
  ('নন-ক্যাডার', FontAwesomeIcons.userTie),
];

void _openPreparationCategory(BuildContext context, String title) {
  final category = switch (title) {
    'BCS প্রস্তুতি' => 'BCS',
    'ব্যাংক জব' => 'Bank',
    _ => title,
  };
  context.push('/subject-catalog?category=${Uri.encodeComponent(category)}');
}

class MobileDashboard extends ConsumerStatefulWidget {
  const MobileDashboard({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<MobileDashboard> createState() => _MobileDashboardState();
}

class _MobileDashboardState extends ConsumerState<MobileDashboard> {
  late int _selectedIndex = widget.initialIndex;
  bool _drawerOpen = false;
  UserProfile? _sidebarProfile;

  @override
  void initState() {
    super.initState();
    _loadSidebarProfile();
  }

  @override
  void didUpdateWidget(covariant MobileDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _selectedIndex = widget.initialIndex;
    }
  }

  Future<void> _loadSidebarProfile() async {
    if (apiClient.authToken == null || apiClient.authToken!.contains('.')) {
      try {
        final profile = await ProfileService(apiClient).get();
        if (mounted) setState(() => _sidebarProfile = profile);
      } catch (_) {
        // Guests use the fixed guest identity in the drawer.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _DashboardHome(),
      const _NoticeBoard(),
      const _ProfilePage(),
    ];

    return Scaffold(
      appBar: BrandHeader(
        menuOpen: _drawerOpen,
        onMenu: (context) {
          if (_drawerOpen) {
            Navigator.of(context).pop();
          } else {
            Scaffold.of(context).openDrawer();
          }
        },
        onNotification: () => BrandNotificationPopup.show(context),
      ),
      drawer: DashboardDrawer(
        profile: _sidebarProfile,
        isGuest: ref.watch(authNotifierProvider).user == null,
        isAdmin: ref.watch(authNotifierProvider).user?.role == 'admin',
        onAccount: () => context.push('/account'),
        onLogout: () => ref.read(authNotifierProvider.notifier).logout(),
        onNavigate: (index) {
          Navigator.pop(context);
          setState(() => _selectedIndex = index);
        },
      ),
      onDrawerChanged: (isOpen) => setState(() => _drawerOpen = isOpen),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: pages[_selectedIndex],
          ),
        ),
      ),
      bottomNavigationBar: BrandBottomNavigation(
        selectedIndex: _selectedIndex == 2 ? 4 : 0,
        onSelected: (index) {
          if (index == 0) {
            setState(() => _selectedIndex = 0);
          } else {
            BrandBottomNavigation.navigate(context, index);
          }
        },
      ),
    );
  }
}

class PreparationScreen extends StatelessWidget {
  const PreparationScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('সেলফ স্টাডি & প্রশ্নব্যাংক')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _FeatureGrid(
                  items: _preparationCategories,
                  onTap: (title) => _openPreparationCategory(context, title),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BrandBottomNavigation(
          selectedIndex: 2,
          onSelected: (index) => BrandBottomNavigation.navigate(context, index),
        ),
      );
}

class _DashboardHome extends ConsumerStatefulWidget {
  const _DashboardHome();

  @override
  ConsumerState<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends ConsumerState<_DashboardHome> {
  Future<void> _openExamCreator() async {
    if (ref.read(authNotifierProvider).user == null) {
      await context.push('/account');
      return;
    }
    await context.push('/subject-catalog?create=1');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
      children: [
        _SectionTitle(title: 'পরীক্ষা সেকশন', color: AppConstants.primary),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.event_note, color: AppConstants.primary),
            title: const Text('Exam Calendar'),
            subtitle: const Text('Live, upcoming ও past exam দেখুন'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/exam-calendar'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: const Color(0xFFE8F3F1),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppConstants.primary,
              child: Icon(Icons.auto_graph, color: Colors.white),
            ),
            title: const Text('Make Dynamic Exam', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: const Text('নিজের মতো এক্সাম বানান, পরীক্ষা দিন, এক্সাম বন্ধুদের শেয়ার করে লিডারবোর্ডে র‍্যাঙ্ক দেখুন! '),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openExamCreator,
          ),
        ),
        const SizedBox(height: 8),
        _SectionTitle(title: 'এক্সাম ব্যাচ', color: AppConstants.primary),
        const SizedBox(height: 8),
        Card(
          color: const Color(0xFFE8F3F1),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppConstants.primary,
              child: Icon(Icons.groups_outlined, color: Colors.white),
            ),
            title: const Text('ফ্রি এক্সাম ব্যাচে যোগ দিন', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: const Text('ব্যাচভিত্তিক রুটিনে বিভিন্ন ধরনের পরীক্ষা দিন'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/exam-batches'),
          ),
        ),
        const SizedBox(height: 24),
        _SectionTitle(title: 'সেলফ স্টাডি & প্রশ্নব্যাংক', color: AppConstants.primary),
        const SizedBox(height: 8),
        _FeatureGrid(
          items: _preparationCategories,
          onTap: (title) => _openPreparationCategory(context, title),
        ),
      ],
    );
  }

}

class _StudyProgressCard extends StatelessWidget {
  const _StudyProgressCard();

  @override
  Widget build(BuildContext context) => Card(
        color: AppConstants.primary,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('এই সপ্তাহের progress',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                  Text('৬৮%', style: TextStyle(color: Colors.white.withValues(alpha: .9), fontSize: 21, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const LinearProgressIndicator(
                  value: .68,
                  minHeight: 9,
                  backgroundColor: Color(0x557AA7A4),
                  color: Color(0xFFFFC857),
                ),
              ),
              const SizedBox(height: 10),
              Text('৪টি session সম্পন্ন • আরও ২টি করলে weekly goal পূর্ণ হবে',
                  style: TextStyle(color: Colors.white.withValues(alpha: .82))),
            ],
          ),
        ),
      );
}

class _DashboardSectionHeading extends StatelessWidget {
  const _DashboardSectionHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: AppConstants.mutedText)),
        ],
      );
}

class _ActivitySummaryGrid extends StatelessWidget {
  const _ActivitySummaryGrid({required this.stats});

  final ProfileStats? stats;

  @override
  Widget build(BuildContext context) {
    final data = stats;
    final metrics = [
      (Icons.menu_book, '${data?.totalQuestionsRead ?? 0}', 'Total Questions Read', const Color(0xFFE8F3F1)),
      (Icons.assignment_outlined, '${data?.totalExams ?? 0}', 'Total Exams', const Color(0xFFFFF2D8)),
      (Icons.auto_graph, '${data?.totalPracticeExams ?? 0}', 'Practice Exams', const Color(0xFFEFE8FF)),
      (Icons.live_tv, '${data?.totalLiveExams ?? 0}', 'Live Exams', const Color(0xFFFFE8E8)),
      (Icons.verified_outlined, '${data?.totalPassedExams ?? 0}', 'Passed Exams', const Color(0xFFE3F4E7)),
      (Icons.warning_amber_outlined, '${data?.failedOrIncompleteExams ?? 0}', 'Failed / Incomplete', const Color(0xFFFFF0E0)),
      (Icons.check_circle_outline, '${data?.totalRightAnswers ?? 0}', 'Right Answers', const Color(0xFFE4F5EF)),
      (Icons.cancel_outlined, '${data?.totalWrongAnswers ?? 0}', 'Wrong Answers', const Color(0xFFFFE8EA)),
      (Icons.remove_circle_outline, '${data?.totalSkippedAnswers ?? 0}', 'Skip / Unanswer', const Color(0xFFF0F1F4)),
      (Icons.timer_outlined, _formatStudyTime(data?.totalStudyMinutes ?? 0), 'Study Time', const Color(0xFFE8F0FF)),
      (Icons.volunteer_activism_outlined, '${data?.totalContribution ?? 0}', 'Contribution', const Color(0xFFFFEAF4)),
      (Icons.emoji_events_outlined, data?.overallRank == null ? '—' : '#${data!.overallRank}', 'Overall Rank', const Color(0xFFE6F4F5)),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 520 ? 3 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 3 ? 1.05 : 1.2,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return _ActivityMetric(
              icon: metric.$1,
              value: metric.$2,
              label: metric.$3,
              color: metric.$4,
            );
          },
        );
      },
    );
  }

  String _formatStudyTime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }
}

class _ActivityMetric extends StatelessWidget {
  const _ActivityMetric({required this.icon, required this.value, required this.label, required this.color});
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppConstants.primary, size: 22),
            const SizedBox(height: 9),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppConstants.mutedText)),
          ],
        ),
      );
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList({required this.activities});

  final List<RecentActivity> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_outlined, color: AppConstants.primary),
              SizedBox(width: 12),
              Expanded(child: Text('আপনি exam বা topic practice শুরু করলে এখানে সাম্প্রতিক activity দেখা যাবে।')),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          for (var index = 0; index < activities.length; index++) ...[
            _ActivityTile(activity: activities[index]),
            if (index < activities.length - 1) const Divider(height: 1, indent: 68),
          ],
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final RecentActivity activity;

  @override
  Widget build(BuildContext context) {
    final isExam = activity.type == 'exam';
    final score = activity.totalMarks == null || activity.totalMarks == 0
        ? null
        : '${((activity.correctCount ?? 0) / activity.totalMarks! * 100).round()}%';
    final details = isExam
        ? '${activity.correctCount ?? 0}টি সঠিক • ${_relativeTime(activity.activityAt)}'
        : '${activity.questionCount ?? 0}টি প্রশ্ন পড়া • ${_relativeTime(activity.activityAt)}';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isExam ? const Color(0xFFE8F3F1) : const Color(0xFFFFF2D8),
        child: Icon(
          isExam ? Icons.check : Icons.menu_book_outlined,
          color: isExam ? AppConstants.primary : const Color(0xFFB77900),
        ),
      ),
      title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(details),
      trailing: score != null
          ? Text(score, style: const TextStyle(fontWeight: FontWeight.w800, color: AppConstants.primary))
          : const Icon(Icons.play_arrow, color: AppConstants.primary),
      onTap: () {
        if (isExam) {
          context.push('/exam/${activity.relatedId}');
        } else {
          final uri = Uri(path: '/subject-practice', queryParameters: {
            'topicId': activity.relatedId,
            'topicName': activity.title,
          });
          context.push(uri.toString());
        }
      },
    );
  }

  String _relativeTime(DateTime timestamp) {
    final elapsed = DateTime.now().difference(timestamp);
    if (elapsed.inMinutes < 1) return 'এইমাত্র';
    if (elapsed.inHours < 1) return '${elapsed.inMinutes} মিনিট আগে';
    if (elapsed.inDays < 1) return '${elapsed.inHours} ঘণ্টা আগে';
    return '${elapsed.inDays} দিন আগে';
  }
}

class _QuestionBankSection extends StatefulWidget {
  const _QuestionBankSection();

  @override
  State<_QuestionBankSection> createState() => _QuestionBankSectionState();
}

class _QuestionBankSectionState extends State<_QuestionBankSection> {
  late Future<_QuestionBankData> _data;
  String? _selectedCategory;

  static const _categories = [
    'SSC',
    'HSC',
    'Varsity',
    'Medical',
    'Engineering',
    'Agriculture',
    'BCS প্রস্তুতি',
    'শিক্ষক নিবন্ধন',
    'বার কাউন্সিল',
    'ব্যাংক জব',
    'সরকারি চাকরি',
    'নন-ক্যাডার',
    'ভর্তি পরীক্ষা',
  ];

  @override
  void initState() {
    super.initState();
    _data = _loadData();
  }

  Future<_QuestionBankData> _loadData() async {
    final topics = await TopicService(apiClient).getTree();
    final questions = await QuestionService(apiClient).list();
    return _QuestionBankData(topics: topics, questions: questions);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_QuestionBankData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data;
        if (data == null) return const Text('Question Bank লোড করা যায়নি।');
        final selectedQuestions = _questionsForCategory(
          data,
          _selectedCategory,
        );
        final sets = <String, int>{};
        for (final question in selectedQuestions) {
          final setName = question.questionSet?.trim();
          if (setName != null && setName.isNotEmpty) {
            sets[setName] = (sets[setName] ?? 0) + 1;
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FeatureGrid(
              items: [
                for (final category in _categories)
                  (category, FontAwesomeIcons.bookOpen),
              ],
              onTap: (category) => context.push(
                '/question-bank?category=${Uri.encodeComponent(category)}',
              ),
            ),
            if (_selectedCategory != null) ...[
              const SizedBox(height: 14),
              Text(
                '${_selectedCategory!} Question Sets',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (sets.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('এই category-তে এখনো কোনো question set upload করা হয়নি।'),
                  ),
                )
              else
                _FeatureGrid(
                  items: [
                    for (final entry in sets.entries)
                      ('${entry.key} (${entry.value}টি)', FontAwesomeIcons.listCheck),
                  ],
                  onTap: (_) => context.push('/previous-question-bank'),
                ),
            ],
          ],
        );
      },
    );
  }

  List<Question> _questionsForCategory(
    _QuestionBankData data,
    String? categoryName,
  ) {
    if (categoryName == null) return const [];
    final aliases = <String, String>{
      'BCS প্রস্তুতি': 'BCS',
      'ব্যাংক জব': 'Bank',
    };
    final target = (aliases[categoryName] ?? categoryName).toLowerCase();
    final topicIds = <String>{};

    void visit(List<TopicNode> nodes) {
      for (final node in nodes) {
        if (node.name.toLowerCase() == target) {
          void collect(TopicNode item) {
            topicIds.add(item.id);
            for (final child in item.children) {
              collect(child);
            }
          }
          collect(node);
        }
        visit(node.children);
      }
    }

    visit(data.topics);
    return data.questions.where((question) {
      return topicIds.contains(question.topicId) ||
          question.topicName?.toLowerCase() == target;
    }).toList();
  }
}

class _QuestionBankData {
  const _QuestionBankData({required this.topics, required this.questions});

  final List<TopicNode> topics;
  final List<Question> questions;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2200343A),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.items, required this.onTap});
  final List<(String, IconData)> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 560 ? 2 : 3;
          final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var index = 0; index < items.length; index++)
                SizedBox(
                  width: width,
                  height: 74,
                  child: Card(
                    elevation: 3,
                    shadowColor: const Color(0x24000000),
                    child: InkWell(
                      onTap: () => onTap(items[index].$1),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F3F1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: FaIcon(
                                  items[index].$2,
                                  color: AppConstants.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(items[index].$1,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
}

class _NoticeBoard extends StatefulWidget {
  const _NoticeBoard();

  @override
  State<_NoticeBoard> createState() => _NoticeBoardState();
}

class _NoticeBoardState extends State<_NoticeBoard> {
  final _notices = <({String title, String body, String date, bool unread})>[
    (
      title: 'আজই শেষ দিন!',
      body:
          'Rapid Discount অফারের আজই শেষ দিন! Live MCQ প্রিমিয়াম প্যাকেজে বিশেষ ছাড়।',
      date: 'আজ, ১০:৩০ AM',
      unread: true,
    ),
    (
      title: 'BCS প্রস্তুতি নতুন রুটিন',
      body:
          'বিসিএস প্রিলি প্রস্তুতির জন্য গুরুত্বপূর্ণ টপিকের উপর নতুন রুটিন প্রকাশিত হয়েছে।',
      date: 'গতকাল, ০৮:১৫ PM',
      unread: true,
    ),
    (
      title: 'Award Mania Season 22',
      body: 'নতুন মডেল টেস্টে অংশ নিন এবং আকর্ষণীয় পুরস্কার জিতে নিন।',
      date: '০৭ সেপ্টেম্বর ২০২৬',
      unread: true,
    ),
  ];

  int get _unreadCount => _notices.where((notice) => notice.unread).length;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: Text('Notice Board',
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700)),
            ),
            TextButton(
              onPressed: _unreadCount == 0
                  ? null
                  : () => setState(() {
                        for (var index = 0; index < _notices.length; index++) {
                          _notices[index] = (
                            title: _notices[index].title,
                            body: _notices[index].body,
                            date: _notices[index].date,
                            unread: false
                          );
                        }
                      }),
              child: const Text('সব পড়া হয়েছে'),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$_unreadCountটি unread notice',
          style: const TextStyle(color: AppConstants.mutedText),
        ),
        const SizedBox(height: 14),
        for (var index = 0; index < _notices.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _NoticeCard(
              notice: _notices[index],
              onExpanded: () {
                if (_notices[index].unread) {
                  setState(() {
                    _notices[index] = (
                      title: _notices[index].title,
                      body: _notices[index].body,
                      date: _notices[index].date,
                      unread: false
                    );
                  });
                }
              },
            ),
          ),
      ],
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice, required this.onExpanded});

  final ({String title, String body, String date, bool unread}) notice;
  final VoidCallback onExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: ExpansionTile(
        onExpansionChanged: (_) => onExpanded(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(52, 0, 16, 16),
        leading: Icon(
          notice.unread ? Icons.notifications_active : Icons.notifications_none,
          color: notice.unread ? Colors.orange : AppConstants.mutedText,
        ),
        title: Text(
          notice.title,
          style: TextStyle(
            fontWeight: notice.unread ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: Text(notice.date),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              notice.body,
              style: const TextStyle(height: 1.5, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePage extends ConsumerStatefulWidget {
  const _ProfilePage();

  @override
  ConsumerState<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<_ProfilePage> {
  UserProfile? _profile;
  ProfileStats? _stats;
  List<RecentActivity> _activities = const [];
  late Future<List<Exam>> _myExams;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _myExams = ref.read(authNotifierProvider).user == null
        ? Future.value(const <Exam>[])
        : ExamService(apiClient).myCreatedExams();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService(apiClient).get();
      ProfileStats? stats;
      List<RecentActivity> activities = const [];
      try {
        stats = await ProfileService(apiClient).getStats();
      } catch (_) {}
      try {
        activities = await ProfileService(apiClient).getRecentActivity();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _profile = profile;
          _stats = stats;
          _activities = activities;
        });
      }
    } catch (_) {
      final user = ref.read(authNotifierProvider).user;
      if (mounted) {
        setState(() {
          _profile = UserProfile(
            id: user?.userId ?? 'guest-profile',
            phoneNumber: user?.phoneNumber ?? '',
            displayName: user?.displayName ?? 'শিক্ষার্থী',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final profile = _profile;
    if (profile == null) {
      return const Center(child: Text('Profile লোড করা যায়নি'));
    }
    final isSignedIn = ref.watch(authNotifierProvider).user != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        _ProfileIdentityCard(
          name: profile.displayName,
          imageUrl: profile.profileImageUrl,
          onSettings: () => _showSettings(context),
          onPhoto: _pickPhoto,
          onEditName: () => _editName(context),
          selectedCategories: profile.preparationCategories,
          onCategorySelected: _toggleCategory,
        ),
        const SizedBox(height: 14),
        const _StudyProgressCard(),
        const SizedBox(height: 18),
        const _DashboardSectionHeading(
          title: 'আজকের পড়াশোনা',
          subtitle: 'আপনার প্রস্তুতির এক নজরের overview',
        ),
        const SizedBox(height: 10),
        _ActivitySummaryGrid(stats: _stats),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: _DashboardSectionHeading(
                title: 'আমার তৈরি Dynamic Exam',
                subtitle: 'শেয়ার লিংক, অংশগ্রহণকারী ও rank',
              ),
            ),
            IconButton(
              tooltip: 'তালিকা refresh করুন',
              onPressed: () => setState(() => _myExams = ExamService(apiClient).myCreatedExams()),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (!isSignedIn)
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('নিজের exam ও rank দেখতে sign in করুন'),
              trailing: TextButton(onPressed: () => context.push('/account'), child: const Text('Sign in')),
            ),
          )
        else
          FutureBuilder<List<Exam>>(
            future: _myExams,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Card(
                  child: ListTile(
                    title: const Text('তৈরি exam লোড করা যায়নি'),
                    onTap: () => setState(() => _myExams = ExamService(apiClient).myCreatedExams()),
                  ),
                );
              }
              final exams = snapshot.data ?? const <Exam>[];
              if (exams.isEmpty) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.assignment_add),
                    title: Text('এখনো কোনো dynamic exam তৈরি করেননি'),
                    subtitle: Text('Home-এর Make Dynamic Exam থেকে প্রথম exam তৈরি করুন'),
                  ),
                );
              }
              return Column(
                children: [
                  for (final exam in exams)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(exam.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 3),
                            Text('${exam.questionCount ?? exam.questions.length}টি প্রশ্ন • ${exam.totalMarks.toStringAsFixed(0)} নম্বর • ${exam.durationMinutes} মিনিট'),
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: 'লিংক কপি করুন',
                                  onPressed: () async {
                                    final shareUrl = '${Uri.base.origin}/#/exam/${exam.id}';
                                    await Clipboard.setData(ClipboardData(text: shareUrl));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exam link কপি হয়েছে')));
                                    }
                                  },
                                  icon: const Icon(Icons.copy_outlined),
                                ),
                                IconButton(
                                  tooltip: 'WhatsApp-এ share করুন',
                                  onPressed: () => _shareExam(exam),
                                  icon: const Icon(Icons.share_outlined),
                                ),
                                TextButton.icon(
                                  onPressed: () => context.push('/exam/${exam.id}/participants'),
                                  icon: const Icon(Icons.leaderboard_outlined, size: 18),
                                  label: const Text('ফলাফল ও rank'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: 18),
        const _DashboardSectionHeading(
          title: 'সাম্প্রতিক activity',
          subtitle: 'আপনার শেখার momentum ধরে রাখুন',
        ),
        const SizedBox(height: 10),
        _RecentActivityList(activities: _activities),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE8F3F1),
              child: Icon(Icons.settings_outlined, color: AppConstants.primary),
            ),
            title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Notification, language ও account preferences'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSettings(context),
          ),
        ),
      ],
    );
  }

  Future<void> _shareExam(Exam exam) async {
    final shareUrl = '${Uri.base.origin}/#/exam/${exam.id}';
    final shareUri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent('${exam.title}\n$shareUrl')}');
    if (!await launchUrl(shareUri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share link খোলা যায়নি')));
    }
  }

  Future<void> _toggleCategory(String category) async {
    final current = [...?_profile?.preparationCategories];
    if (current.contains(category)) {
      current.remove(category);
    } else {
      current.add(category);
    }
    try {
      final updated = await ProfileService(apiClient).update(
        preparationCategories: current,
      );
      if (mounted) setState(() => _profile = updated);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Category save failed: $error')));
    }
  }

  Future<void> _pickPhoto() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (image == null) return;
    try {
      final bytes = await image.readAsBytes();
      final extension = image.name.split('.').last.toLowerCase();
      final mimeType = switch (extension) {
        'jpg' || 'jpeg' => 'jpeg',
        'png' => 'png',
        'webp' => 'webp',
        'gif' => 'gif',
        'bmp' => 'bmp',
        'avif' => 'avif',
        _ => 'jpeg',
      };
      final profile = await ProfileService(apiClient).update(
        profileImageUrl: 'data:image/$mimeType;base64,${base64Encode(bytes)}',
      );
      if (mounted) setState(() => _profile = profile);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile picture save failed: $error')));
    }
  }

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: _profile?.displayName);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('নাম পরিবর্তন করুন'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('বাতিল')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('সংরক্ষণ')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    try {
      final updated = await ProfileService(apiClient).update(displayName: name);
      if (!mounted) return;
      setState(() => _profile = updated);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Name save failed: $error')));
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final values = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Password পরিবর্তন করুন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: current, obscureText: true, decoration: const InputDecoration(labelText: 'বর্তমান password')),
            const SizedBox(height: 10),
            TextField(controller: next, obscureText: true, decoration: const InputDecoration(labelText: 'নতুন password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('বাতিল')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, (current.text, next.text)), child: const Text('আপডেট')),
        ],
      ),
    );
    current.dispose();
    next.dispose();
    if (values == null) return;
    try {
      await ProfileService(apiClient).changePassword(values.$1, values.$2);
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Password update failed: $error')));
    }
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              leading: Icon(Icons.settings_outlined, color: AppConstants.primary),
              title: Text('Profile settings', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('নাম পরিবর্তন করুন'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _editName(this.context);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_none),
              title: const Text('Study notifications'),
              value: _profile?.notificationsEnabled ?? true,
              onChanged: (value) async {
                final updated = await ProfileService(apiClient).update(notificationsEnabled: value);
                if (mounted) setState(() => _profile = updated);
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('ভাষা'),
              trailing: Text(_profile?.preferredLanguage ?? 'বাংলা'),
              onTap: () async {
                final updated = await ProfileService(apiClient).update(preferredLanguage: 'বাংলা');
                if (mounted) setState(() => _profile = updated);
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Account security'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _changePassword(this.context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({
    required this.name,
    required this.onSettings,
    required this.onPhoto,
    required this.onEditName,
    required this.selectedCategories,
    required this.onCategorySelected,
    this.imageUrl,
  });

  final String name;
  final VoidCallback onSettings;
  final VoidCallback onPhoto;
  final VoidCallback onEditName;
  final List<String> selectedCategories;
  final ValueChanged<String> onCategorySelected;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) => Card(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 620;
            final actions = _IdentityActions(
              onSettings: onSettings,
              onEditName: onEditName,
            );
            final selector = _PreparationTypeDropdown(
              selected: selectedCategories,
              onSelected: onCategorySelected,
            );
            final mobileSelector = _PreparationTypeDropdown(
              selected: selectedCategories,
              onSelected: onCategorySelected,
              centered: true,
            );
            return Padding(
              padding: EdgeInsets.all(isWide ? 18 : 14),
              child: isWide
                  ? Row(
                      children: [
                        _ProfileAvatar(imageUrl: imageUrl, onPhoto: onPhoto),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _IdentityDetails(
                            name: name,
                            selectedCategories: selectedCategories,
                          ),
                        ),
                        const SizedBox(width: 18),
                        selector,
                        const SizedBox(width: 6),
                        actions,
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _ProfileAvatar(imageUrl: imageUrl, onPhoto: onPhoto),
                            const SizedBox(width: 12),
                            Flexible(
                              child: _IdentityDetails(
                                name: name,
                                selectedCategories: selectedCategories,
                              ),
                            ),
                            const SizedBox(width: 6),
                            mobileSelector,
                            const SizedBox(width: 2),
                            actions,
                          ],
                        ),
                      ],
                    ),
            );
          },
        ),
      );
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.imageUrl, required this.onPhoto});

  final String? imageUrl;
  final VoidCallback onPhoto;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: const Color(0xFFDCECEA),
            backgroundImage: imageUrl == null ? null : NetworkImage(imageUrl!),
            child: imageUrl == null
                ? const Icon(Icons.person, size: 38, color: AppConstants.primary)
                : null,
          ),
          Positioned(
            right: -3,
            bottom: -3,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: AppConstants.primary,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 14,
                color: Colors.white,
                icon: const Icon(Icons.camera_alt_outlined),
                onPressed: onPhoto,
              ),
            ),
          ),
        ],
      );
}

class _IdentityDetails extends StatelessWidget {
  const _IdentityDetails({required this.name, required this.selectedCategories});

  final String name;
  final List<String> selectedCategories;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          const Text('Student profile', style: TextStyle(color: AppConstants.mutedText)),
          if (selectedCategories.isNotEmpty) ...[
            const SizedBox(height: 7),
            Wrap(
              spacing: 5,
              runSpacing: 4,
              children: [
                for (final category in selectedCategories.take(2))
                  _PreparationTag(label: category),
                if (selectedCategories.length > 2)
                  _PreparationTag(label: '+${selectedCategories.length - 2}'),
              ],
            ),
          ],
        ],
      );
}

class _PreparationTag extends StatelessWidget {
  const _PreparationTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F3F1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppConstants.primary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _IdentityActions extends StatelessWidget {
  const _IdentityActions({required this.onSettings, required this.onEditName});

  final VoidCallback onSettings;
  final VoidCallback onEditName;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Settings',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.settings_outlined),
            onPressed: onSettings,
          ),
          IconButton(
            tooltip: 'নাম পরিবর্তন করুন',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEditName,
          ),
        ],
      );
}

class _PreparationTypeDropdown extends StatelessWidget {
  const _PreparationTypeDropdown({
    required this.selected,
    required this.onSelected,
    this.centered = false,
  });

  final List<String> selected;
  final ValueChanged<String> onSelected;
  final bool centered;

  static const _categories = [
    ('Academic', Icons.school_outlined),
    ('Admission', Icons.account_balance_outlined),
    ('BCS & Jobs', Icons.work_outline),
    ('Bank Job', Icons.account_balance_wallet_outlined),
    ('Medical', Icons.local_hospital_outlined),
    ('Engineering', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedLabel = selected.isEmpty
        ? 'Select type'
        : selected.length == 1
            ? selected.first
            : '${selected.length} selected';
    return Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Preparation Type',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: AppConstants.mutedText,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        PopupMenuButton<String>(
          tooltip: 'Preparation Type নির্বাচন করুন',
          onSelected: onSelected,
          itemBuilder: (context) => [
            for (final category in _categories)
              PopupMenuItem<String>(
                value: category.$1,
                child: Row(
                  children: [
                    Icon(
                      selected.contains(category.$1)
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: AppConstants.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(category.$1),
                  ],
                ),
              ),
          ],
          child: Container(
            constraints: const BoxConstraints(maxWidth: 112),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5F8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD5E5EA)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    selectedLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppConstants.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 17, color: AppConstants.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DashboardDrawer extends ConsumerWidget {
  const DashboardDrawer({
    super.key,
    this.profile,
    this.isGuest,
    this.isAdmin,
    this.onNavigate,
    this.onAccount,
    this.onLogout,
  });
  final UserProfile? profile;
  final bool? isGuest;
  final bool? isAdmin;
  final ValueChanged<int>? onNavigate;
  final VoidCallback? onAccount;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authNotifierProvider).user;
    final signedInAsGuest = isGuest ?? authUser == null;
    final adminUser = isAdmin ?? authUser?.role == 'admin';
    final name = signedInAsGuest
        ? 'Guest-Biddyan-User'
        : (profile?.displayName ?? authUser?.displayName ?? 'শিক্ষার্থী');
    final phone = profile?.phoneNumber ?? authUser?.phoneNumber ?? '';
    final imageUrl = profile?.profileImageUrl;
    final preparationTypes = profile?.preparationCategories ?? const <String>[];
    final width = MediaQuery.sizeOf(context).width;

    void navigate(String route) {
      Navigator.pop(context);
      context.go(route);
    }

    void showComingSoon(String title) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title শীঘ্রই যুক্ত হবে।')),
      );
    }

    Future<void> copyInviteLink() async {
      await Clipboard.setData(
        ClipboardData(text: Uri.base.replace(path: '/', query: null, fragment: null).toString()),
      );
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite link কপি হয়েছে।')),
      );
    }

    return Drawer(
      width: width > 420 ? 380 : width * 0.9,
      backgroundColor: const Color(0xFFF4F7F6),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 12, 14, 18),
              decoration: const BoxDecoration(
                color: AppConstants.primary,
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
                        child: Image.asset('assets/biddyan_logo.png', fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('বিদ্বান', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      ),
                      IconButton(
                        tooltip: 'মেনু বন্ধ করুন',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFFDCEDEC),
                        backgroundImage: imageUrl == null ? null : NetworkImage(imageUrl),
                        child: imageUrl == null
                            ? const Icon(Icons.person_outline, color: AppConstants.primary, size: 28)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                            if (phone.isNotEmpty)
                              Text(phone, style: const TextStyle(color: Color(0xFFCCE0DE), fontSize: 12)),
                            if (signedInAsGuest)
                              const Text('শেখা শুরু করতে আপনার অ্যাকাউন্টে প্রবেশ করুন', maxLines: 2, style: TextStyle(color: Color(0xFFCCE0DE), fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (preparationTypes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final type in preparationTypes.take(2))
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: const Color(0xFF24575A), borderRadius: BorderRadius.circular(16)),
                            child: Text(type, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ],
                  if (signedInAsGuest) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          if (onAccount != null) {
                            onAccount!();
                          } else {
                            context.push('/account');
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppConstants.primary,
                          minimumSize: const Size.fromHeight(42),
                        ),
                        icon: const Icon(Icons.login),
                        label: const Text('Sign up / Login'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                children: [
                  const _DrawerSectionLabel('শেখা ও প্রস্তুতি'),
                  _DrawerMenuItem(
                    icon: Icons.home_outlined,
                    title: 'ড্যাশবোর্ড',
                    onTap: () {
                      if (onNavigate != null) {
                        onNavigate!(2);
                      } else {
                        navigate('/profile');
                      }
                    },
                  ),
                  _DrawerMenuItem(icon: Icons.auto_awesome_outlined, title: 'বিদ্বান AI', onTap: () => navigate('/biddyan-ai')),
                  _DrawerMenuItem(icon: Icons.groups_outlined, title: 'এক্সাম ব্যাচ', onTap: () => navigate('/exam-batches')),
                  _DrawerMenuItem(icon: Icons.calendar_month_outlined, title: 'এক্সাম ক্যালেন্ডার', onTap: () => navigate('/exam-calendar')),
                  _DrawerMenuItem(icon: Icons.menu_book_outlined, title: 'সেলফ স্টাডি & প্রশ্নব্যাংক', onTap: () => navigate('/preparation')),
                  _DrawerMenuItem(
                    icon: Icons.auto_fix_high_outlined,
                    title: 'Make Dynamic Exam',
                    onTap: () {
                      if (signedInAsGuest) {
                        Navigator.pop(context);
                        if (onAccount != null) {
                          onAccount!();
                        } else {
                          context.push('/account');
                        }
                      } else {
                        navigate('/subject-catalog?create=1');
                      }
                    },
                  ),
                  _DrawerMenuItem(icon: Icons.library_books_outlined, title: 'বই ও রিসোর্স', onTap: () => navigate('/books')),
                  _DrawerMenuItem(icon: Icons.edit_calendar_outlined, title: 'রুটিন / Study Plan', onTap: () => navigate('/routine')),
                  _DrawerMenuItem(icon: Icons.forum_outlined, title: 'Group Study', onTap: () => showComingSoon('Group Study')),
                  const SizedBox(height: 8),
                  const Divider(height: 1, indent: 12, endIndent: 12),
                  const SizedBox(height: 12),
                  const _DrawerSectionLabel('সহায়তা ও তথ্য'),
                  _DrawerMenuItem(icon: Icons.support_agent_outlined, title: 'Contact Support', onTap: () => showComingSoon('Contact Support')),
                  _DrawerMenuItem(icon: Icons.info_outline, title: 'About Us', onTap: () => showComingSoon('About Us')),
                  _DrawerMenuItem(icon: Icons.fact_check_outlined, title: 'Terms & Conditions', onTap: () => showComingSoon('Terms & Conditions')),
                  _DrawerMenuItem(icon: Icons.help_outline, title: 'FAQs', onTap: () => showComingSoon('FAQs')),
                  _DrawerMenuItem(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () => showComingSoon('Privacy Policy')),
                  _DrawerMenuItem(icon: Icons.gpp_good_outlined, title: 'Disclaimer', onTap: () => showComingSoon('Disclaimer')),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE3EAE9))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (adminUser)
                        _DrawerFooterAction(
                          icon: Icons.admin_panel_settings_outlined,
                          label: 'Admin Panel',
                          onTap: () => navigate('/admin'),
                        ),
                      if (!signedInAsGuest)
                        _DrawerFooterAction(
                          icon: Icons.logout,
                          label: 'Logout',
                          onTap: () {
                            Navigator.pop(context);
                            if (onLogout != null) {
                              onLogout!();
                            } else {
                              ref.read(authNotifierProvider.notifier).logout();
                            }
                          },
                          destructive: true,
                        ),
                      _DrawerFooterAction(
                        icon: Icons.person_add_alt_1,
                        label: 'Invite friend',
                        onTap: copyInviteLink,
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('আমাদের সাথে যুক্ত থাকুন', style: TextStyle(fontSize: 11, color: AppConstants.mutedText)),
                      const SizedBox(width: 6),
                      _SocialButton(icon: FontAwesomeIcons.facebook, color: const Color(0xFF1877F2), url: Uri.parse('https://www.facebook.com/'), label: 'Facebook'),
                      _SocialButton(icon: FontAwesomeIcons.youtube, color: const Color(0xFFFF0000), url: Uri.parse('https://www.youtube.com/'), label: 'YouTube'),
                      _SocialButton(icon: FontAwesomeIcons.telegram, color: const Color(0xFF229ED9), url: Uri.parse('https://t.me/'), label: 'Telegram'),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text('All rights reserved by Softwaid.com | 2026', textAlign: TextAlign.center, style: TextStyle(color: AppConstants.mutedText, fontSize: 10)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  const _DrawerSectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppConstants.mutedText),
        ),
      );
}

class _DrawerMenuItem extends StatelessWidget {
  const _DrawerMenuItem({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: const Color(0xFFE5F0EF), borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, size: 18, color: AppConstants.primary),
                  ),
                  const SizedBox(width: 11),
                  Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF24383A)))),
                  const Icon(Icons.chevron_right, size: 18, color: Color(0xFF8A9997)),
                ],
              ),
            ),
          ),
        ),
      );
}

class _DrawerFooterAction extends StatelessWidget {
  const _DrawerFooterAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: destructive ? AppConstants.accent : AppConstants.primary,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.color,
    required this.url,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final Uri url;
  final String label;

  Future<void> _open() async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: label,
        onPressed: _open,
        icon: FaIcon(icon, color: color, size: 21),
      );
}
