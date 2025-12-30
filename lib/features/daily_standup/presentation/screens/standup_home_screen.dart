import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/themes/colors.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../providers/standup_provider.dart';
import 'morning_plan_screen.dart';
import 'evening_summary_screen.dart';
import 'standup_history_screen.dart';

class StandupHomeScreen extends ConsumerStatefulWidget {
  const StandupHomeScreen({super.key});

  @override
  ConsumerState<StandupHomeScreen> createState() => _StandupHomeScreenState();
}

class _StandupHomeScreenState extends ConsumerState<StandupHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(standupStatusProvider.notifier).loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final standupStatus = ref.watch(standupStatusProvider);
    final standupNotifier = ref.read(standupStatusProvider.notifier);
    
    return Scaffold(
      backgroundColor: IntraZeroColors.background,
      appBar: AppBar(
        title: const Text('Daily Standup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StandupHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              standupNotifier.loadStatus();
            },
          ),
        ],
      ),
      body: standupStatus.when(
        data: (status) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              GlassmorphismCard(
                child: Column(
                  children: [
                    if (status != null && !status.morningSubmitted)
                      GradientButton(
                        text: 'Submit Morning Plan',
                        gradient: IntraZeroColors.morningGradient,
                        icon: Icons.wb_sunny,
                        isFullWidth: true,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MorningPlanScreen()),
                          ).then((_) {
                            standupNotifier.loadStatus();
                          });
                        },
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: IntraZeroColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: IntraZeroColors.success),
                            SizedBox(width: 12),
                            Text('Morning plan submitted'),
                          ],
                        ),
                      ),
                    if (status != null && status.morningSubmitted && !status.eveningSubmitted) ...[
                      const SizedBox(height: 20),
                      GradientButton(
                        text: 'Submit Evening Summary',
                        gradient: IntraZeroColors.eveningGradient,
                        icon: Icons.nightlight,
                        isFullWidth: true,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EveningSummaryScreen()),
                          ).then((_) {
                            standupNotifier.loadStatus();
                          });
                        },
                      ),
                    ],
                    if (status != null && status.eveningSubmitted) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: IntraZeroColors.completeGradient.colors.first.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: IntraZeroColors.completeGradient.colors.first),
                            const SizedBox(width: 12),
                            const Text('Standup complete for today'),
                          ],
                        ),
                      ),
                    ],
                    if (status != null && status.morningSubmitted) ...[
                      const SizedBox(height: 20),
                      _buildTaskStats(status.tasks),
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
                onPressed: () => standupNotifier.loadStatus(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTaskStats(tasks) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IntraZeroColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('Total', tasks.total.toString(), IntraZeroColors.info),
          _buildStat('Done', tasks.completed.toString(), IntraZeroColors.success),
          _buildStat('In Progress', tasks.inProgress.toString(), IntraZeroColors.warning),
          _buildStat('Pending', tasks.pending.toString(), IntraZeroColors.textSecondary),
        ],
      ),
    );
  }
  
  Widget _buildStat(String label, String value, Color color) {
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
            fontSize: 11,
            color: IntraZeroColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

