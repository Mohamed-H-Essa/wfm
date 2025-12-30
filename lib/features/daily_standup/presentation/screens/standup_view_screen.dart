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
  final repository = StandupRepository(ref.watch(apiClientProvider));
  final response = await repository.getToday(); // Using getToday for now, should be getById
  if (response.success && response.data != null) {
    return response.data!;
  }
  throw Exception(response.message ?? 'Failed to load standup');
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
                      DateFormat('EEEE, MMMM d, y').format(DateTime.parse(standup['date'] as String)),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: IntraZeroColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (standup['today_goals'] != null) ...[
                      const Text(
                        'Today\'s Goals',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: IntraZeroColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        standup['today_goals'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: IntraZeroColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (standup['work_summary'] != null) ...[
                      const Text(
                        'Work Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: IntraZeroColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        standup['work_summary'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: IntraZeroColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

