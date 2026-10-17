import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/brand_navigation.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'সব';

  List<AppNotification> _items = AppNotification.defaultItems();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await NotificationService(apiClient).list();
      if (!mounted) return;
      setState(() {
        _items = [...AppNotification.defaultItems(), ...items];
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _items.length;
    final filteredItems = _selectedFilter == 'সব'
        ? _items
        : _items.where((item) => item.displayCategory == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('নোটিফিকেশন'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppConstants.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(Icons.notifications_active_outlined, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('আপনার আপডেট', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                          SizedBox(height: 3),
                          Text('পরীক্ষা ও শেখার নতুন খবর এক জায়গায়', style: TextStyle(color: Color(0xFFD4E5E3), fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Text('$totalCountটি', style: const TextStyle(color: AppConstants.primary, fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(child: Text('সাম্প্রতিক নোটিফিকেশন', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppConstants.primary))),
                  Text('${filteredItems.length}টি দেখানো হচ্ছে', style: const TextStyle(fontSize: 11, color: AppConstants.mutedText)),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final filter in const ['সব', 'পরীক্ষা', 'Bidwaan AI', 'সাধারণ'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: _selectedFilter == filter,
                          onSelected: (_) => setState(() => _selectedFilter = filter),
                          showCheckmark: false,
                          selectedColor: const Color(0xFFDCEDEC),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: _selectedFilter == filter ? const Color(0xFFB9D7D4) : const Color(0xFFE1E9E8)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
              if (filteredItems.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: const Column(
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 34, color: AppConstants.mutedText),
                      SizedBox(height: 10),
                      Text('এই বিভাগে কোনো নোটিফিকেশন নেই', style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              for (final item in filteredItems)
                _NotificationCard(
                  item: item,
                  onTap: item.route.isNotEmpty ? () => context.push(item.route) : null,
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BrandBottomNavigation(
        selectedIndex: 0,
        onSelected: (index) => BrandBottomNavigation.navigate(context, index),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE3EAE9)),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.displayCategory, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: item.accent)),
                      const SizedBox(height: 4),
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppConstants.primary)),
                      const SizedBox(height: 4),
                      Text(item.message, style: const TextStyle(fontSize: 13, color: AppConstants.mutedText, height: 1.35)),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 6, top: 12),
                  child: Icon(Icons.chevron_right, color: AppConstants.mutedText),
                ),
              ],
            ),
          ),
        ),
      );
}