import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/themes/colors.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../providers/standup_provider.dart';
import 'morning_plan_screen.dart';
import 'evening_summary_screen.dart';
import 'standup_history_screen.dart';
import '../../data/models/standup_reminder_status_model.dart';
import '../../data/models/standup_editability_model.dart';
import '../../data/models/standup_status_model.dart';
import '../../data/repositories/standup_repository.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class StandupHomeScreen extends ConsumerStatefulWidget {
  const StandupHomeScreen({super.key});

  @override
  ConsumerState<StandupHomeScreen> createState() => _StandupHomeScreenState();
}

class _StandupHomeScreenState extends ConsumerState<StandupHomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(standupStatusProvider.notifier).loadStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh status when app comes to foreground
      ref.read(standupStatusProvider.notifier).loadStatus();
    }
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
        data: (status) {
          // Handle null status - show submit morning plan button
          if (status == null) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GlassmorphismCard(
                    child: Column(
                      children: [
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              await standupNotifier.loadStatus();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildReminderIndicators(),
                  const SizedBox(height: 20),
                  _buildProgressIndicator(status),
                  const SizedBox(height: 20),
                  GlassmorphismCard(
                  child: Column(
                    children: [
                      if (!status.morningSubmitted)
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
                      else ...[
                        // Show edit button if editable
                        _buildEditMorningButton(status.standupId),
                        const SizedBox(height: 12),
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
                      ],
                      if (status.morningSubmitted && !status.eveningSubmitted) ...[
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
                      if (status.eveningSubmitted) ...[
                        const SizedBox(height: 20),
                        if (status.standupId != null)
                          GradientButton(
                            text: 'View Evening Summary',
                            gradient: IntraZeroColors.eveningGradient,
                            icon: Icons.visibility,
                            isFullWidth: true,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EveningSummaryScreen(standupId: status.standupId),
                                ),
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
                                Text('Evening summary submitted'),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
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
                      if (status.morningSubmitted) ...[
                        const SizedBox(height: 20),
                        _buildTaskStats(status.tasks),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: GlassmorphismCard(
            child: GradientButton(
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
            ),
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
  
  Widget _buildProgressIndicator(StandupStatusModel? status) {
    if (status == null) {
      return const SizedBox.shrink();
    }
    
    int progress = 0;
    if (status.morningSubmitted && status.eveningSubmitted) {
      progress = 100;
    } else if (status.morningSubmitted) {
      progress = 50;
    }
    
    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$progress%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: progress == 100 
                      ? IntraZeroColors.success 
                      : progress == 50 
                          ? IntraZeroColors.warning 
                          : IntraZeroColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: IntraZeroColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 100 
                    ? IntraZeroColors.success 
                    : progress == 50 
                        ? IntraZeroColors.warning 
                        : IntraZeroColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    status.morningSubmitted ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: status.morningSubmitted 
                        ? IntraZeroColors.success 
                        : IntraZeroColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Morning Plan',
                    style: TextStyle(
                      fontSize: 12,
                      color: status.morningSubmitted 
                          ? IntraZeroColors.success 
                          : IntraZeroColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    status.eveningSubmitted ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: status.eveningSubmitted 
                        ? IntraZeroColors.success 
                        : IntraZeroColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Evening Summary',
                    style: TextStyle(
                      fontSize: 12,
                      color: status.eveningSubmitted 
                          ? IntraZeroColors.success 
                          : IntraZeroColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildReminderIndicators() {
    final reminderStatusAsync = ref.watch(standupReminderStatusProvider);
    
    return reminderStatusAsync.when(
      data: (reminderStatus) {
        final hasMorningReminder = reminderStatus.morning.needsReminder && !reminderStatus.morning.submitted;
        final hasEveningReminder = reminderStatus.evening.needsReminder && !reminderStatus.evening.submitted;
        
        if (!hasMorningReminder && !hasEveningReminder) {
          return const SizedBox.shrink();
        }
        
        return GlassmorphismCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active, color: IntraZeroColors.warning, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Reminders',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: IntraZeroColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: () {
                      ref.invalidate(standupReminderStatusProvider);
                    },
                    tooltip: 'Request Reminder',
                  ),
                ],
              ),
              if (hasMorningReminder) ...[
                const SizedBox(height: 12),
                _buildReminderItem(
                  'Morning Plan',
                  reminderStatus.morning.deadline,
                  reminderStatus.morning.deadlinePassed,
                  'MORNING',
                ),
              ],
              if (hasEveningReminder) ...[
                const SizedBox(height: 12),
                _buildReminderItem(
                  'Evening Summary',
                  reminderStatus.evening.deadline,
                  reminderStatus.evening.deadlinePassed,
                  'EVENING',
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
  
  Widget _buildReminderItem(String label, String deadline, bool deadlinePassed, String type) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: deadlinePassed 
            ? IntraZeroColors.danger.withOpacity(0.1)
            : IntraZeroColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: deadlinePassed 
              ? IntraZeroColors.danger
              : IntraZeroColors.warning,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            deadlinePassed ? Icons.warning : Icons.schedule,
            color: deadlinePassed ? IntraZeroColors.danger : IntraZeroColors.warning,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: IntraZeroColors.textPrimary,
                  ),
                ),
                Text(
                  'Deadline: $deadline',
                  style: TextStyle(
                    fontSize: 12,
                    color: IntraZeroColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, size: 18),
            onPressed: () async {
              final repository = StandupRepository(ref.read(apiClientProvider));
              final response = await repository.requestReminder(type: type);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      response.success 
                          ? 'Reminder requested successfully'
                          : response.message ?? 'Failed to request reminder',
                    ),
                    backgroundColor: response.success 
                        ? IntraZeroColors.success
                        : IntraZeroColors.danger,
                  ),
                );
                if (response.success) {
                  ref.invalidate(standupReminderStatusProvider);
                }
              }
            },
            tooltip: 'Request Reminder',
          ),
        ],
      ),
    );
  }
  
  Widget _buildEditMorningButton(int? standupId) {
    if (standupId == null) return const SizedBox.shrink();
    
    final editabilityAsync = ref.watch(standupEditabilityProvider);
    
    return editabilityAsync.when(
      data: (editability) {
        if (!editability.morning.canEdit) return const SizedBox.shrink();
        
        return GradientButton(
          text: 'Edit Morning Plan',
          gradient: IntraZeroColors.morningGradient,
          icon: Icons.edit,
          isFullWidth: true,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MorningPlanScreen(standupId: standupId),
              ),
            ).then((_) {
              ref.read(standupStatusProvider.notifier).loadStatus();
            });
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

