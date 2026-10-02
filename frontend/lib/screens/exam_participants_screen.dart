import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../services/services.dart';
import '../providers/providers.dart';
import '../widgets/brand_navigation.dart';
import 'mobile_dashboard.dart';

class ExamParticipantsScreen extends StatelessWidget {
  const ExamParticipantsScreen({super.key, required this.examId});

  final String examId;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppConstants.background,
        drawer: const DashboardDrawer(),
        appBar: const BrandHeader(),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: ExamService(apiClient).participants(examId),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Participants লোড করা যায়নি: ${snapshot.error}'));
            }
            final participants = snapshot.data ?? const <Map<String, dynamic>>[];
            if (participants.isEmpty) {
              return const Center(child: Text('এখনো কেউ এই exam দেয়নি।'));
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Participants & Rank', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 5),
                Text('${participants.length} জন student exam দিয়েছে', style: const TextStyle(color: AppConstants.mutedText)),
                const SizedBox(height: 14),
                for (final participant in participants)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: participant['rank'] == 1 ? const Color(0xFFFFD166) : const Color(0xFFE8F3F1),
                        child: Text('${participant['rank'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      title: Text(participant['display_name'] as String? ?? 'শিক্ষার্থী', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${participant['correct_count'] ?? 0} correct • ${participant['wrong_count'] ?? 0} wrong'),
                      trailing: Text('${participant['score'] ?? 0}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppConstants.primary)),
                    ),
                  ),
              ],
            );
          },
        ),
        bottomNavigationBar: BrandBottomNavigation(
          selectedIndex: 2,
          onSelected: (index) => BrandBottomNavigation.navigate(context, index),
        ),
      );
}