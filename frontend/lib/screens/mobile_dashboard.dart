import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../providers/providers.dart';
import '../widgets/brand_navigation.dart';
import 'home_screen.dart';
import 'home_sections.dart';

class MobileDashboard extends ConsumerStatefulWidget {
  const MobileDashboard({super.key});

  @override
  ConsumerState<MobileDashboard> createState() => _MobileDashboardState();
}

class _MobileDashboardState extends ConsumerState<MobileDashboard> {
  int _selectedIndex = 0;
  bool _drawerOpen = false;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardHome(onNotice: () => setState(() => _selectedIndex = 1)),
      const _NoticeBoard(),
      const _ProfilePage(),
      const _PackagesPage(),
    ];

    return Scaffold(
      appBar: AppBar(
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
        title: Image.asset('assets/biddyan_logo.png', height: 44),
        actions: [
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
  const _DashboardHome({required this.onNotice});

  final VoidCallback onNotice;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFFFFF4F1),
          child: ListTile(
            leading: const FaIcon(FontAwesomeIcons.triangleExclamation,
                color: Colors.deepOrange),
            title: const Text('আপনার কোনো Active প্যাকেজ নেই'),
            trailing: FilledButton(
              onPressed: () {},
              child: const Text('প্যাকেজ কিনুন'),
            ),
          ),
        ),
        const SizedBox(height: 16),
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
            ('ভর্তি পরীক্ষা', FontAwesomeIcons.graduationCap),
          ],
          onTap: (title) {
            if (title != 'প্রিলি ও লিখিত প্রস্তুতি' &&
                title != 'ফ্রি সাপ্তাহিক মডেল টেস্ট') {
              final category = switch (title) {
                'BCS প্রস্তুতি' => 'BCS',
                'ব্যাংক জব' => 'Bank',
                _ => title,
              };
              context.push(
                '/subject-catalog?category=${Uri.encodeComponent(category)}',
              );
            } else if (title == 'প্রিলি ও লিখিত প্রস্তুতি') {
              context.push('/previous-question-bank');
            }
          },
        ),
        const SizedBox(height: 16),
        _SectionTitle(title: 'স্টাডি সেকশন', color: AppConstants.primary),
        const SizedBox(height: 8),
        StudySection(
          onStudyTap: (_) => context.push('/subject-catalog'),
        ),
        const SizedBox(height: 16),
        _SectionTitle(title: 'দ্রুত লিংক', color: AppConstants.primary),
        ListTile(
          tileColor: Colors.white,
          leading: const Icon(Icons.notifications_active, color: Colors.orange),
          title: const Text('Notice Board'),
          subtitle: const Text('সর্বশেষ নোটিশ ও অফার দেখুন'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onNotice,
        ),
        const SizedBox(height: 16),
        const Text('সাম্প্রতিক পরীক্ষা',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, _) => ref.watch(examsProvider).when(
                data: (exams) => ExamList(exams: exams),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorCard(message: error.toString()),
              ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.color});
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
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
              for (final item in items)
                SizedBox(
                  width: width,
                  height: 78,
                  child: Card(
                    child: InkWell(
                      onTap: () => onTap(item.$1),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            FaIcon(item.$2,
                                color: AppConstants.primary, size: 22),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(item.$1,
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

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const CircleAvatar(
                    radius: 42, child: Icon(Icons.person, size: 48)),
                const SizedBox(height: 8),
                const Text('শিক্ষার্থী',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Text('ID: BIDDYAN-USER'),
                const SizedBox(height: 16),
                FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit),
                    label: const Text('প্রোফাইল সম্পাদনা')),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          const _ProfileStat(title: 'মোট পরীক্ষা', value: '0'),
          const _ProfileStat(title: 'সঠিক উত্তর', value: '0'),
          const _ProfileStat(title: 'পয়েন্ট', value: '0'),
        ],
      );
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.title, required this.value});
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading:
              const Icon(Icons.analytics_outlined, color: AppConstants.primary),
          title: Text(title),
          trailing: Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
      );
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
    required this.onNavigate,
    required this.onAccount,
    required this.onLogout,
  });
  final ValueChanged<int> onNavigate;
  final VoidCallback onAccount;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('শিক্ষার্থী'),
              accountEmail: const Text('BIDDYAN-USER'),
              currentAccountPicture: Image.asset('assets/biddyan_logo.png'),
              decoration: const BoxDecoration(color: AppConstants.primary),
            ),
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
            const Divider(),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Panel'),
              onTap: () {
                Navigator.pop(context);
                context.go('/admin');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: onLogout,
            ),
          ],
        ),
      );
}
