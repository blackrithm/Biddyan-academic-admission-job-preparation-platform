import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BrandBottomNavigation extends StatelessWidget {
  const BrandBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => NavigationBar(
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
        ],
      );
}
