import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

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
        context.go('/subject-catalog');
      case 2:
        context.go('/exam-calendar');
      case 3:
        context.go('/routine');
      case 4:
        context.go('/profile');
      case 5:
        context.go('/biddyan-ai');
    }
  }

  @override
  Widget build(BuildContext context) => NavigationBar(
      height: 68,
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: const [
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.house),
            label: 'হোম',
          ),
          NavigationDestination(
            icon: FaIcon(FontAwesomeIcons.handshake),
            label: 'সেকশন',
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
      );
}
