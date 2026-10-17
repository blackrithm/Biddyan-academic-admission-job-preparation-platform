import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';

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
              _drawerItem(
                  context, Icons.auto_awesome, 'Bidwaan AI', '/biddyan-ai'),
              _drawerItem(
                  context, Icons.analytics_outlined, 'Performance', '/profile'),
              _drawerItem(
                  context, Icons.card_giftcard, 'Referral Program', null),
              _drawerItem(context, Icons.person_add_alt_1,
                  'Account খুলুন / Login', '/account'),
              const Divider(),
              _drawerItem(
                  context, Icons.support_agent, 'Contact Support', null),
              _drawerItem(context, Icons.help_outline, 'FAQs', null),
              _drawerItem(context, Icons.info_outline, 'About Us', null),
              const Divider(),
              _drawerItem(context, Icons.home_outlined, 'হোম', '/'),
              _drawerItem(context, Icons.menu_book_outlined,
                  'বই ও শিক্ষাসামগ্রী', '/books'),
              _drawerItem(context, Icons.calendar_month_outlined,
                  'পরীক্ষা ক্যালেন্ডার', '/exam-calendar'),
              _drawerItem(
                  context, Icons.edit_calendar_outlined, 'রুটিন', '/routine'),
            ],
          ),
        ),
      );

  static Widget _drawerItem(
          BuildContext context, IconData icon, String label, String? route) =>
      ListTile(
        leading: Icon(icon, color: AppConstants.primary),
        title: Text(label),
        trailing: route == null ? null : const Icon(Icons.chevron_right),
        onTap: route == null
            ? null
            : () {
                Navigator.pop(context);
                context.push(route);
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
          builder: (context) => GoRouterState.of(context).uri.path == '/'
              ? _menuButton(context)
              : AppBackButton(
                  onPressed: () => _goBack(context),
                ),
        ),
        actions: [
          if (GoRouterState.of(context).uri.path != '/')
            Builder(builder: _menuButton),
          if (showNotifications)
            IconButton(
              tooltip: 'নোটিশ',
              icon: const Badge(
                label: Text('2'),
                child: Icon(Icons.notifications_none),
              ),
              onPressed: onNotification ??
                  () {
                    context.push('/notifications');
                  },
            ),
          ...extraActions,
        ],
      );

  Widget _menuButton(BuildContext context) => IconButton(
        tooltip: menuOpen ? 'মেনু বন্ধ করুন' : 'মেনু খুলুন',
        icon: Icon(menuOpen ? Icons.close : Icons.menu),
        onPressed: () {
          if (onMenu != null) {
            onMenu!(context);
          } else {
            _showFallbackMenu(context);
          }
        },
      );

  void _goBack(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/');
    }
  }

  void _showFallbackMenu(BuildContext context) {
    Scaffold.maybeOf(context)?.openDrawer();
  }
}

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'পিছনে যান',
        icon: const Icon(Icons.arrow_back),
        onPressed: onPressed ??
            () {
              final router = GoRouter.of(context);
              if (router.canPop()) {
                router.pop();
              } else {
                router.go('/');
              }
            },
      );
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
              title: Text('Bidwaan',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('আপনার পড়াশোনার shortcuts'),
            ),
            for (final item in _menuItems)
              ListTile(
                leading: Icon(item.$1),
                title: Text(item.$2),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(item.$3);
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
    (Icons.auto_awesome_outlined, 'Bidwaan AI', '/biddyan-ai'),
  ];
}

class PersistentFooterScope extends InheritedWidget {
  const PersistentFooterScope({super.key, required super.child});

  static bool isActive(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PersistentFooterScope>() !=
      null;

  @override
  bool updateShouldNotify(PersistentFooterScope oldWidget) => false;
}

class BrandBottomNavigation extends StatelessWidget {
  const BrandBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.isPersistent = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool isPersistent;

  static const _destinations = [
    _FooterDestination(FontAwesomeIcons.house, 'হোম'),
    _FooterDestination(FontAwesomeIcons.bookOpen, 'বই'),
    _FooterDestination(FontAwesomeIcons.rectangleList, 'প্রস্তুতি'),
    _FooterDestination(FontAwesomeIcons.filePen, 'রুটিন'),
    _FooterDestination(FontAwesomeIcons.user, 'প্রোফাইল'),
    _FooterDestination(FontAwesomeIcons.wandMagicSparkles, 'Bidwaan AI'),
  ];

  static String locationFor(int index) => switch (index) {
        0 => '/',
        1 => '/books',
        2 => '/preparation',
        3 => '/routine',
        4 => '/profile',
        5 => '/biddyan-ai',
        _ => '/',
      };

  static void navigate(BuildContext context, int index) {
    context.push(locationFor(index));
  }

  @override
  Widget build(BuildContext context) {
    if (PersistentFooterScope.isActive(context) && !isPersistent) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5ECEB))),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A00343A),
              blurRadius: 12,
              offset: Offset(0, -3),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
        child: Row(
          children: [
            for (var index = 0; index < _destinations.length; index++)
              Expanded(
                child: _FooterNavigationItem(
                  destination: _destinations[index],
                  selected: selectedIndex == index,
                  onTap:
                      selectedIndex == index ? null : () => onSelected(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FooterDestination {
  const _FooterDestination(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _FooterNavigationItem extends StatelessWidget {
  const _FooterNavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _FooterDestination destination;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: destination.label,
        child: Tooltip(
          message: destination.label,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOutCubic,
                    width: selected ? 42 : 38,
                    height: 25,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFDDECEB)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: FaIcon(
                      destination.icon,
                      size: 17,
                      color: selected
                          ? AppConstants.primary
                          : const Color(0xFF607477),
                    ),
                  ),
                  const SizedBox(height: 1),
                  SizedBox(
                    height: 12,
                    child: selected
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              destination.label,
                              maxLines: 1,
                              style: const TextStyle(
                                color: AppConstants.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
