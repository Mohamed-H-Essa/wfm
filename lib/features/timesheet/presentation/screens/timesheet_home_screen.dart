import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/themes/colors.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../providers/timesheet_provider.dart';
import 'timesheet_entries_screen.dart';

class TimesheetHomeScreen extends ConsumerStatefulWidget {
  const TimesheetHomeScreen({super.key});

  @override
  ConsumerState<TimesheetHomeScreen> createState() => _TimesheetHomeScreenState();
}

class _TimesheetHomeScreenState extends ConsumerState<TimesheetHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timesheetStatusProvider.notifier).loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final timesheetStatus = ref.watch(timesheetStatusProvider);
    final timesheetNotifier = ref.read(timesheetStatusProvider.notifier);
    
    return Scaffold(
      backgroundColor: IntraZeroColors.background,
      appBar: AppBar(
        title: const Text('Timesheet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TimesheetEntriesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              timesheetNotifier.loadStatus();
            },
          ),
        ],
      ),
      body: timesheetStatus.when(
        data: (status) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              GlassmorphismCard(
                child: Column(
                  children: [
                    if (status.isRunning && status.currentEntry != null) ...[
                      const Text(
                        'Timer Running',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: IntraZeroColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        status.currentEntry!.durationFormatted,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: IntraZeroColors.primaryGradient.colors.first,
                        ),
                      ),
                      if (status.currentEntry!.taskName != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          status.currentEntry!.taskName!,
                          style: TextStyle(
                            fontSize: 16,
                            color: IntraZeroColors.textSecondary,
                          ),
                        ),
                      ],
                    ] else ...[
                      const Text(
                        'No Active Timer',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: IntraZeroColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Start tracking your work time',
                        style: TextStyle(
                          fontSize: 16,
                          color: IntraZeroColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    if (!status.isRunning)
                      GradientButton(
                        text: 'Start Timer',
                        gradient: IntraZeroColors.progressGradient,
                        icon: Icons.play_arrow,
                        isFullWidth: true,
                        onPressed: () => _handleStartTimer(timesheetNotifier),
                      )
                    else if (status.currentEntry != null)
                      GradientButton(
                        text: 'Stop Timer',
                        gradient: IntraZeroColors.eveningGradient,
                        icon: Icons.stop,
                        isFullWidth: true,
                        onPressed: () => _handleStopTimer(timesheetNotifier, status.currentEntry!.id),
                      ),
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
                onPressed: () => timesheetNotifier.loadStatus(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _handleStartTimer(TimesheetStatusNotifier notifier) async {
    try {
      await notifier.start(description: 'General work tracking');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timer started'),
            backgroundColor: IntraZeroColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start timer: ${e.toString()}'),
            backgroundColor: IntraZeroColors.danger,
          ),
        );
      }
    }
  }
  
  Future<void> _handleStopTimer(TimesheetStatusNotifier notifier, int entryId) async {
    try {
      await notifier.stop(entryId: entryId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timer stopped'),
            backgroundColor: IntraZeroColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop timer: ${e.toString()}'),
            backgroundColor: IntraZeroColors.danger,
          ),
        );
      }
    }
  }
}

