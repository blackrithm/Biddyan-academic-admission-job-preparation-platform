import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';

class BrandNotificationPopup {
  const BrandNotificationPopup._();

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Color(0xFFE8F3F1),
                    child: Icon(Icons.notifications_active_outlined, color: AppConstants.primary),
                  ),
                  title: Text('নোটিফিকেশন', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('আপনার সাম্প্রতিক আপডেটগুলো'),
                ),
                Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.campaign_outlined, color: AppConstants.primary),
                  title: Text('নতুন পরীক্ষার আপডেট'),
                  subtitle: Text('আপনার জন্য নতুন exam ও study update এসেছে।'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.auto_awesome_outlined, color: AppConstants.primary),
                  title: Text('বিদ্বান AI এখন প্রস্তুত'),
                  subtitle: Text('যেকোনো প্রশ্ন নিয়ে AI-এর সঙ্গে practice করুন।'),
                ),
              ],
            ),
          ),
        ),
      );
}

class BrandDrawer extends StatelessWidget {
  const BrandDrawer({super.key});

  @override
  Widget build(BuildContext context) => Drawer(
        backgroundColor: const Color(0xFFEAF5F8),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(
                height: 128,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18, 14, 18, 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Image(
                      image: AssetImage('assets/biddyan_logo.png'),
                      width: 92,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              _drawerItem(context, Icons.auto_awesome, 'বিদ্বান AI', '/biddyan-ai'),
              _drawerItem(context, Icons.analytics_outlined, 'Performance', '/profile'),
              _drawerItem(context, Icons.card_giftcard, 'Referral Program', null),
              _drawerItem(context, Icons.person_add_alt_1, 'Account খুলুন / Login', '/account'),
              const Divider(),
              _drawerItem(context, Icons.support_agent, 'Contact Support', null),
              _drawerItem(context, Icons.help_outline, 'FAQs', null),
              _drawerItem(context, Icons.info_outline, 'About Us', null),
              const Divider(),
              _drawerItem(context, Icons.home_outlined, 'হোম', '/'),
              _drawerItem(context, Icons.menu_book_outlined, 'বই ও শিক্ষাসামগ্রী', '/books'),
              _drawerItem(context, Icons.calendar_month_outlined, 'পরীক্ষা ক্যালেন্ডার', '/exam-calendar'),
              _drawerItem(context, Icons.edit_calendar_outlined, 'রুটিন', '/routine'),
            ],
          ),
        ),
      );

  static Widget _drawerItem(BuildContext context, IconData icon, String label, String? route) => ListTile(
        leading: Icon(icon, color: AppConstants.primary),
        title: Text(label),
        trailing: route == null ? null : const Icon(Icons.chevron_right),
        onTap: route == null
            ? null
            : () {
                Navigator.pop(context);
                context.go(route);
              },
      );
}

class BrandHeader extends StatelessWidget implements PreferredSizeWidget {
  const BrandHeader({
    super.key,
    this.onMenu,
    this.menuOpen = false,
    this.onNotification,
    this.showNotifications = true,
    this.extraActions = const [],
  });

  final ValueChanged<BuildContext>? onMenu;
  final bool menuOpen;
  final VoidCallback? onNotification;
  final bool showNotifications;
  final List<Widget> extraActions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
        titleSpacing: 0,
        centerTitle: true,
        title: Image.asset('assets/biddyan_logo.png', height: 44),
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: menuOpen ? 'মেনু বন্ধ করুন' : 'মেনু খুলুন',
            icon: Icon(menuOpen ? Icons.close : Icons.menu),
            onPressed: () {
              if (onMenu != null) {
                onMenu!(context);
              } else {
                _showFallbackMenu(context);
              }
            },
          ),
        ),
        actions: [
          if (showNotifications)
            IconButton(
              tooltip: 'নোটিশ',
              icon: const Badge(
                label: Text('10'),
                child: Icon(Icons.notifications_none),
              ),
              onPressed: onNotification ?? () => BrandNotificationPopup.show(context),
            ),
          ...extraActions,
        ],
      );

  void _showFallbackMenu(BuildContext context) {
    Scaffold.maybeOf(context)?.openDrawer();
  }
}

class BrandMenuButton extends StatelessWidget {
  const BrandMenuButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'মেনু খুলুন',
        icon: const Icon(Icons.menu),
        onPressed: () => _showMenu(context),
      );

  void _showMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(0xFFE8F3F1),
                child: Icon(Icons.menu_book, color: Color(0xFF00343A)),
              ),
              title: Text('বিদ্বান', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('আপনার পড়াশোনার shortcuts'),
            ),
            for (final item in _menuItems)
              ListTile(
                leading: Icon(item.$1),
                title: Text(item.$2),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(item.$3);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static const _menuItems = [
    (Icons.home_outlined, 'হোম', '/'),
    (Icons.menu_book_outlined, 'বই ও শিক্ষাসামগ্রী', '/books'),
    (Icons.calendar_month_outlined, 'পরীক্ষা ক্যালেন্ডার', '/exam-calendar'),
    (Icons.edit_calendar_outlined, 'রুটিন', '/routine'),
    (Icons.person_outline, 'প্রোফাইল', '/profile'),
    (Icons.auto_awesome_outlined, 'বিদ্বান AI', '/biddyan-ai'),
  ];
}

class BrandBottomNavigation extends StatelessWidget {
  const BrandBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static void navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
          case 1:
            context.go('/books');
      case 2:
        context.go('/preparation');
      case 3:
        context.go('/routine');
      case 4:
        context.go('/profile');
      case 5:
        context.go('/biddyan-ai');
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: NavigationBar(
          height: 72,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected,
          destinations: const [
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.house),
            label: 'হোম',
          ),
            NavigationDestination(
              icon: FaIcon(FontAwesomeIcons.bookOpen),
              label: 'বই',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.rectangleList),
            label: 'প্রস্তুতি',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.filePen),
            label: 'রুটিন',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.user),
            label: 'প্রোফাইল',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.wandMagicSparkles),
            label: 'বিদ্বান AI',
          ),
          ],
        ),
      );
}
