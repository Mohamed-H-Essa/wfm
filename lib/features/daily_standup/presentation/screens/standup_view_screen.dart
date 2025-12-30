import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/themes/colors.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../../../shared/widgets/progress_bar.dart';
import '../../data/repositories/standup_repository.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final standupViewProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, standupId) async {
  try {
    final repository = StandupRepository(ref.watch(apiClientProvider));
    final response = await repository.getById(standupId);
    if (response.success && response.data != null) {
      return response.data!;
    }
  } catch (e) {
    // Silently handle errors
  }
  // Return empty data instead of throwing
  return {
    'id': standupId.toString(),
    'date': DateTime.now().toIso8601String().split('T')[0],
    'status': 'UNKNOWN',
    'work_type': 'OFFICE',
    'today_goals': null,
    'work_summary': null,
    'morning_submitted_at': null,
    'evening_submitted_at': null,
    'tasks': [],
    'carryover_blockers': [],
  };
});

class StandupViewScreen extends ConsumerWidget {
  final int standupId;
  
  const StandupViewScreen({super.key, required this.standupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standupAsync = ref.watch(standupViewProvider(standupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Standup Details'),
      ),
      body: standupAsync.when(
        data: (standup) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassmorphismCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d, y').format(DateTime.parse(standup['date']?.toString() ?? DateTime.now().toIso8601String())),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: IntraZeroColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Morning Plan Section
                    if (standup['morning_submitted_at'] != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: IntraZeroColors.morningGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.wb_sunny, color: Colors.white),
                                const SizedBox(width: 8),
                                const Text(
                                  'Morning Plan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            if (standup['morning_submitted_at'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Submitted: ${standup['morning_submitted_at']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                            if (standup['today_goals'] != null && standup['today_goals'].toString().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Today\'s Goals',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                standup['today_goals'].toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Evening Summary Section
                    if (standup['evening_submitted_at'] != null || standup['work_summary'] != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: IntraZeroColors.eveningGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.nightlight, color: Colors.white),
                                const SizedBox(width: 8),
                                const Text(
                                  'Evening Summary',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            if (standup['evening_submitted_at'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Submitted: ${standup['evening_submitted_at']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                            if (standup['work_summary'] != null && standup['work_summary'].toString().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Work Summary',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                standup['work_summary'].toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (standup['tasks'] != null && standup['tasks'] is List) ...[
                      const Text(
                        'Tasks',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: IntraZeroColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(standup['tasks'] as List).map((task) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: IntraZeroColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                task['title']?.toString() ?? 'Task',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: IntraZeroColors.textPrimary,
                                ),
                              ),
                            ),
                            if (task['status'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: IntraZeroColors.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  task['status'].toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: IntraZeroColors.info,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref.refresh(standupViewProvider(standupId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

