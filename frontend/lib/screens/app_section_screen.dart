import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../widgets/brand_navigation.dart';
import 'mobile_dashboard.dart';

class AppSectionScreen extends StatelessWidget {
  const AppSectionScreen({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.selectedIndex,
  });

  final String title;
  final String message;
  final IconData icon;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      drawer: const DashboardDrawer(),
      appBar: const BrandHeader(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 52, color: AppConstants.primary),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BrandBottomNavigation(
        selectedIndex: selectedIndex,
        onSelected: (index) => BrandBottomNavigation.navigate(context, index),
      ),
    );
  }
}
