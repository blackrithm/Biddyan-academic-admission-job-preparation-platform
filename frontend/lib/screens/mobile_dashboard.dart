import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/brand_navigation.dart';

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
      const _PackagesPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Center(
          child: Image.asset('assets/biddyan_logo.png', height: 44),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(_drawerOpen ? Icons.close : Icons.menu),
            tooltip: _drawerOpen ? 'মেনু বন্ধ করুন' : 'মেনু খুলুন',
            onPressed: () {
              if (_drawerOpen) {
                Navigator.of(context).pop();
              } else {
                Scaffold.of(context).openDrawer();
              }
            },
          ),
        ),
        actions: [
          const SizedBox(width: 48),
          IconButton(
            tooltip: 'নোটিশ',
            icon: const Badge(
              label: Text('10'),
              child: Icon(Icons.notifications_none),
            ),
            onPressed: () => setState(
              () => _selectedIndex = _selectedIndex == 1 ? 0 : 1,
            ),
          ),
        ],
      ),
      drawer: _DashboardDrawer(
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
        selectedIndex: 0,
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

class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

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
        _FeatureGrid(
          items: const [
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
            
          ],
          onTap: (title) {
            final category = switch (title) {
              'BCS প্রস্তুতি' => 'BCS',
              'ব্যাংক জব' => 'Bank',
              _ => title,
            };
            context.push('/subject-catalog?category=${Uri.encodeComponent(category)}');
          },
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
  const _RecentActivityList();

  @override
  Widget build(BuildContext context) => Card(
        child: Column(
          children: [
            const ListTile(
              leading: CircleAvatar(backgroundColor: Color(0xFFE8F3F1), child: Icon(Icons.check, color: AppConstants.primary)),
              title: Text('SSC English Practice', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('৮/১০ সঠিক • ১২ মিনিট আগে'),
              trailing: Text('৮০%', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.primary)),
            ),
            const Divider(height: 1, indent: 68),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFFFF2D8), child: Icon(Icons.history, color: Color(0xFFB77900))),
              title: const Text('BCS Question Bank', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('শেষ দেখা: General Knowledge'),
              trailing: const Icon(Icons.play_arrow, color: AppConstants.primary),
              onTap: () => context.push('/question-bank?category=BCS'),
            ),
          ],
        ),
      );
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
                            FaIcon(items[index].$2,
                                color: const Color(0xFF2C2F3D), size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(items[index].$1,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis)),
                            if (index.isOdd)
                              const Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: EdgeInsets.only(top: 7),
                                  child: CircleAvatar(
                                    radius: 5,
                                    backgroundColor: AppConstants.accent,
                                  ),
                                ),
                              ),
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService(apiClient).get();
      ProfileStats? stats;
      try {
        stats = await ProfileService(apiClient).getStats();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _profile = profile;
          _stats = stats;
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
        const _DashboardSectionHeading(
          title: 'সাম্প্রতিক activity',
          subtitle: 'আপনার শেখার momentum ধরে রাখুন',
        ),
        const SizedBox(height: 10),
        const _RecentActivityList(),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Color(0xFFDCECEA),
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
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    const Text('Student profile', style: TextStyle(color: AppConstants.mutedText)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F3F1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Active learner', style: TextStyle(color: AppConstants.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              _PreparationTypeDropdown(
                selected: selectedCategories,
                onSelected: onCategorySelected,
              ),
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings_outlined),
                onPressed: onSettings,
              ),
              IconButton(
                tooltip: 'নাম পরিবর্তন করুন',
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEditName,
              ),
            ],
          ),
        ),
      );
}

class _PreparationTypeDropdown extends StatelessWidget {
  const _PreparationTypeDropdown({
    required this.selected,
    required this.onSelected,
  });

  final List<String> selected;
  final ValueChanged<String> onSelected;

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preparation Type',
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

class _PackagesPage extends StatelessWidget {
  const _PackagesPage();
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Packages',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (final package in const [
            ('Monthly', '৳499'),
            ('Half-yearly', '৳1999'),
            ('Yearly', '৳2999')
          ])
            Card(
              child: ListTile(
                leading:
                    const Icon(Icons.workspace_premium, color: Colors.orange),
                title: Text(package.$1,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('সব পরীক্ষা ও স্টাডি কনটেন্টে অ্যাক্সেস'),
                trailing:
                    FilledButton(onPressed: () {}, child: Text(package.$2)),
              ),
            ),
        ],
      );
}

class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer({
    required this.profile,
    required this.isGuest,
    required this.isAdmin,
    required this.onNavigate,
    required this.onAccount,
    required this.onLogout,
  });
  final UserProfile? profile;
  final bool isGuest;
  final bool isAdmin;
  final ValueChanged<int> onNavigate;
  final VoidCallback onAccount;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final name = isGuest ? 'Guest-Biddyan-User' : (profile?.displayName ?? 'শিক্ষার্থী');
    final phone = profile?.phoneNumber ?? '';
    final imageUrl = profile?.profileImageUrl;
    return Drawer(
      backgroundColor: const Color(0xFFEAF5F8),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                name,
                style: const TextStyle(
                  color: AppConstants.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              accountEmail: isGuest
                  ? const SizedBox.shrink()
                  : Text(
                      phone,
                      style: const TextStyle(color: AppConstants.mutedText),
                    ),
              currentAccountPicture: imageUrl == null
                  ? Image.asset('assets/biddyan_logo.png')
                  : CircleAvatar(backgroundImage: NetworkImage(imageUrl)),
              decoration: const BoxDecoration(color: Color(0xFFEAF5F8)),
            ),
            ListTile(
                leading: const Icon(Icons.auto_awesome, color: AppConstants.primary),
                title: const Text('বিদ্বান AI'),
                subtitle: const Text('প্রশ্ন করুন, সন্দেহ দূর করুন'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/biddyan-ai');
                }),
            ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Performance'),
                onTap: () => onNavigate(2)),
            ListTile(
                leading: const Icon(Icons.card_giftcard),
                title: const Text('Referral Program'),
                onTap: () {}),
            ListTile(
                leading: const Icon(Icons.workspace_premium),
                title: const Text('Packages'),
                onTap: () => onNavigate(3)),
            ListTile(
                leading: const Icon(Icons.person_add_alt_1),
                title: const Text('Account খুলুন / Login'),
                onTap: () {
                  Navigator.pop(context);
                  onAccount();
                }),
            const Divider(),
            ListTile(
                leading: const Icon(Icons.support_agent),
                title: const Text('Contact Support'),
                onTap: () {}),
            ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('FAQs'),
                onTap: () {}),
            ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About Us'),
                onTap: () {}),
            if (isAdmin) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Admin Panel'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/admin');
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: onLogout,
            ),
          ],
        ),
      );
  }
}
