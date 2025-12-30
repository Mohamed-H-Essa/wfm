import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/themes/colors.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../../../shared/widgets/progress_bar.dart';
import '../../data/repositories/standup_repository.dart';
import '../../data/models/standup_history_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'standup_view_screen.dart';

final standupHistoryProvider = FutureProvider.family<StandupHistoryModel, Map<String, int?>>((ref, params) async {
  final repository = StandupRepository(ref.watch(apiClientProvider));
  final response = await repository.getHistory(
    month: params['month'],
    year: params['year'],
    page: params['page'] ?? 1,
  );
  
  if (response.success && response.data != null) {
    return StandupHistoryModel.fromJson(response.data!);
  }
  throw Exception(response.message ?? 'Failed to load standup history');
});

class StandupHistoryScreen extends ConsumerStatefulWidget {
  const StandupHistoryScreen({super.key});

  @override
  ConsumerState<StandupHistoryScreen> createState() => _StandupHistoryScreenState();
}

class _StandupHistoryScreenState extends ConsumerState<StandupHistoryScreen> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(standupHistoryProvider({
      'days': _days,
      'page': 1,
    }));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Standup History'),
        actions: [
          PopupMenuButton<int>(
            onSelected: (value) {
              setState(() {
                _days = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Last 7 days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 days')),
              const PopupMenuItem(value: 90, child: Text('Last 90 days')),
            ],
          ),
        ],
      ),
      body: historyAsync.when(
        data: (history) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(history.summary),
              const SizedBox(height: 20),
              _buildStandupsList(history.standups),
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
                onPressed: () => ref.refresh(standupHistoryProvider({
                  'days': _days,
                  'page': 1,
                })),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(StandupHistorySummaryModel summary) {
    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: IntraZeroColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Submissions', summary.totalSubmissions.toString(), IntraZeroColors.info),
              ),
              Expanded(
                child: _buildStatItem('Rate', '${summary.submissionRate.toStringAsFixed(1)}%', IntraZeroColors.success),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Avg Completion', '${summary.averageCompletion.toStringAsFixed(1)}%', IntraZeroColors.progressGradient.colors.first),
              ),
              Expanded(
                child: _buildStatItem('Avg Productivity', summary.averageProductivity.toStringAsFixed(1), IntraZeroColors.warning),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: IntraZeroColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStandupsList(List<StandupHistoryItemModel> standups) {
    if (standups.isEmpty) {
      return const Center(
        child: Text('No standup records found'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Standups',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: IntraZeroColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...standups.map((standup) => _buildStandupCard(standup)),
      ],
    );
  }

  Widget _buildStandupCard(StandupHistoryItemModel standup) {
    final progress = standup.tasksTotal > 0
        ? standup.tasksCompleted / standup.tasksTotal
        : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StandupViewScreen(standupId: standup.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: IntraZeroColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: IntraZeroColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('MMM d, y').format(DateTime.parse(standup.date)),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: IntraZeroColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(standup.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    standup.status,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(standup.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (standup.todayGoals != null) ...[
              const SizedBox(height: 8),
              Text(
                standup.todayGoals!,
                style: TextStyle(
                  fontSize: 14,
                  color: IntraZeroColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            ProgressBar(
              progress: progress,
              label: 'Tasks: ${standup.tasksCompleted}/${standup.tasksTotal}',
            ),
            if (standup.productivityRating != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: IntraZeroColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    standup.productivityRating!.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 14,
                      color: IntraZeroColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETE':
        return IntraZeroColors.success;
      case 'IN_PROGRESS':
        return IntraZeroColors.warning;
      default:
        return IntraZeroColors.textSecondary;
    }
  }
}
