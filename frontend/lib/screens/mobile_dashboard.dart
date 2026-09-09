import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../widgets/brand_navigation.dart';
import 'home_screen.dart';
import 'home_sections.dart';
import 'subject_practice_screen.dart';

class MobileDashboard extends ConsumerStatefulWidget {
  const MobileDashboard({super.key});

  @override
  ConsumerState<MobileDashboard> createState() => _MobileDashboardState();
}

class _MobileDashboardState extends ConsumerState<MobileDashboard> {
  int _selectedIndex = 0;

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
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
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
            onPressed: () => setState(() => _selectedIndex = 1),
          ),
        ],
      ),
      drawer: _DashboardDrawer(
        onNavigate: (index) {
          Navigator.pop(context);
          setState(() => _selectedIndex = index);
        },
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: pages[_selectedIndex],
          ),
        ),
      ),
      bottomNavigationBar: BrandBottomNavigation(
        selectedIndex: _selectedIndex == 0 ? 0 : 0,
        onSelected: (index) {
          if (index == 0) {
            setState(() => _selectedIndex = 0);
          } else if (index == 2) {
            context.push('/exam-calendar');
          } else if (index == 4) {
            setState(() => _selectedIndex = 2);
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
        const _ExamCategoryTabs(),
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

class _ExamCategoryTabs extends StatefulWidget {
  const _ExamCategoryTabs();

  @override
  State<_ExamCategoryTabs> createState() => _ExamCategoryTabsState();
}

class _ExamCategoryTabsState extends State<_ExamCategoryTabs> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final category = _examCategories[_selectedIndex];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var index = 0; index < _examCategories.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_examCategories[index].name),
                        selected: index == _selectedIndex,
                        onSelected: (_) =>
                            setState(() => _selectedIndex = index),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${category.name} বিষয় ও প্রশ্নব্যাংক',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            for (final subject in category.subjects)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SubjectQuestionBankCard(
                  subject: subject,
                  onTap: () => context.push(
                    '/subject-practice',
                    extra: SubjectPracticeArgs(
                      subject: subject.name,
                      questionSets: subject.questionSets,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SubjectQuestionBankCard extends StatelessWidget {
  const _SubjectQuestionBankCard({
    required this.subject,
    required this.onTap,
  });

  final _ExamSubject subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6F8FA),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subject.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final questionSet in subject.questionSets)
                    Chip(
                      avatar: const Icon(Icons.quiz_outlined, size: 16),
                      label: Text(questionSet),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamCategory {
  const _ExamCategory(this.name, this.subjects);

  final String name;
  final List<_ExamSubject> subjects;
}

class _ExamSubject {
  const _ExamSubject(this.name, this.questionSets);

  final String name;
  final List<String> questionSets;
}

const _examCategories = [
  _ExamCategory('HSC', [
    _ExamSubject('বাংলা', ['HSC বাংলা ১ম পত্র', 'HSC বাংলা ২য় পত্র']),
    _ExamSubject('ইংরেজি', ['HSC English 1st Paper', 'HSC English 2nd Paper']),
    _ExamSubject('গণিত', ['HSC গণিত অধ্যায়ভিত্তিক']),
    _ExamSubject(
        'পদার্থবিজ্ঞান', ['ভৌত বিজ্ঞান', 'HSC পদার্থবিজ্ঞান মডেল টেস্ট']),
    _ExamSubject('রসায়ন', ['HSC রসায়ন অধ্যায়ভিত্তিক']),
  ]),
  _ExamCategory('SSC', [
    _ExamSubject('বাংলা', ['SSC বাংলা অধ্যায়ভিত্তিক']),
    _ExamSubject('ইংরেজি', ['SSC English Grammar']),
    _ExamSubject('গণিত', ['SSC গণিত অধ্যায়ভিত্তিক']),
    _ExamSubject('সাধারণ বিজ্ঞান', ['SSC সাধারণ বিজ্ঞান']),
  ]),
  _ExamCategory('ভার্সিটি', [
    _ExamSubject('বাংলা', ['বিশ্ববিদ্যালয় ভর্তি বাংলা']),
    _ExamSubject('ইংরেজি', ['বিশ্ববিদ্যালয় ভর্তি ইংরেজি']),
    _ExamSubject('সাধারণ জ্ঞান', ['বিশ্ববিদ্যালয় ভর্তি সাধারণ জ্ঞান']),
  ]),
  _ExamCategory('মেডিকেল', [
    _ExamSubject('জীববিজ্ঞান', ['মেডিকেল জীববিজ্ঞান']),
    _ExamSubject('পদার্থবিজ্ঞান', ['মেডিকেল পদার্থবিজ্ঞান']),
    _ExamSubject('রসায়ন', ['মেডিকেল রসায়ন']),
  ]),
  _ExamCategory('ইঞ্জিনিয়ারিং', [
    _ExamSubject('গণিত', ['ইঞ্জিনিয়ারিং গণিত']),
    _ExamSubject('পদার্থবিজ্ঞান', ['ইঞ্জিনিয়ারিং পদার্থবিজ্ঞান']),
    _ExamSubject('রসায়ন', ['ইঞ্জিনিয়ারিং রসায়ন']),
  ]),
  _ExamCategory('বিসিএস', [
    _ExamSubject('বাংলা', ['বিসিএস বাংলা প্রিলিমিনারি']),
    _ExamSubject('ইংরেজি', ['বিসিএস ইংরেজি প্রিলিমিনারি']),
    _ExamSubject('সাধারণ জ্ঞান', ['বিসিএস বাংলাদেশ ও আন্তর্জাতিক']),
  ]),
  _ExamCategory('ব্যাংক', [
    _ExamSubject('বাংলা', ['ব্যাংক বাংলা প্রশ্নব্যাংক']),
    _ExamSubject('ইংরেজি', ['ব্যাংক English Question Bank']),
    _ExamSubject('গণিত', ['ব্যাংক গণিত প্রশ্নব্যাংক']),
  ]),
];

class _NoticeBoard extends StatelessWidget {
  const _NoticeBoard();
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Notice Board',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('10 unread notices'),
            TextButton(onPressed: () {}, child: const Text('Mark all as read')),
          ]),
          for (final notice in const [
            (
              'আজই শেষ দিন!',
              'Rapid Discount অফারের আজই শেষ দিন! Live MCQ প্রিমিয়াম প্যাকেজে বিশেষ ছাড়।'
            ),
            (
              'BCS প্রস্তুতি নতুন রুটিন',
              'বিসিএস প্রিলি প্রস্তুতির জন্য গুরুত্বপূর্ণ টপিকের উপর নতুন রুটিন প্রকাশিত হয়েছে।'
            ),
            ('Award Mania Season 22', 'নতুন মডেল টেস্ট ও পুরস্কার জিতুন।'),
          ])
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.notifications, color: Colors.orange),
                title: Text(notice.$1,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child:
                          Text('${notice.$2}\n\nবিস্তারিত জানতে লিংক দেখুন।'))
                ],
              ),
            ),
        ],
      );
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
  const _DashboardDrawer({required this.onNavigate});
  final ValueChanged<int> onNavigate;

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
              onTap: () {},
            ),
          ],
        ),
      );
}
