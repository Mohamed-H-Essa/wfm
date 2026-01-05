import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/themes/colors.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../providers/timesheet_provider.dart';
import 'timesheet_entries_screen.dart';
import '../../data/models/timesheet_status_model.dart';
import '../../data/models/morning_plan_task_model.dart';
import '../../data/repositories/timesheet_repository.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';

class TimesheetHomeScreen extends ConsumerStatefulWidget {
  const TimesheetHomeScreen({super.key});

  @override
  ConsumerState<TimesheetHomeScreen> createState() =>
      _TimesheetHomeScreenState();
}

class _TimesheetHomeScreenState extends ConsumerState<TimesheetHomeScreen> {
  Timer? _timer;
  DateTime? _timerStartTime;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timesheetStatusProvider.notifier).loadStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(DateTime startTime) {
    _timerStartTime = startTime;
    _timer?.cancel();
    // Calculate elapsed time locally from start time
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _timerStartTime != null) {
        final now = DateTime.now();
        final elapsed = now.difference(_timerStartTime!).inSeconds;
        setState(() {
          _elapsedSeconds = elapsed;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _timerStartTime = null;
    _elapsedSeconds = 0;
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _updateTimerFromStatus(TimesheetStatusModel? status) {
    if (status != null && status.isRunning && status.currentEntry != null) {
      // Parse started_at and start local timer - no API calls needed
      try {
        final startedAt = DateTime.parse(status.currentEntry!.startedAt);

        // Only start timer if it's not already running or if start time changed
        if (_timerStartTime == null ||
            _timerStartTime!.difference(startedAt).inSeconds.abs() > 1) {
          _startTimer(startedAt);
        }
        // Timer will update automatically via the periodic callback
      } catch (e) {
        // If parsing fails, use the duration from API as fallback
        if (_timerStartTime == null) {
          final now = DateTime.now();
          final fallbackStart = now.subtract(
              Duration(seconds: status.currentEntry!.durationSeconds));
          _startTimer(fallbackStart);
        }
      }
    } else {
      _stopTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timesheetStatus = ref.watch(timesheetStatusProvider);
    final timesheetNotifier = ref.read(timesheetStatusProvider.notifier);
    final attendanceStatus = ref.watch(attendanceStatusProvider);

    // Update timer when status changes (only once, not on every rebuild)
    timesheetStatus.whenData((status) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateTimerFromStatus(status);
      });
    });

    // Timer runs locally - no API polling needed

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
                MaterialPageRoute(
                    builder: (_) => const TimesheetEntriesScreen()),
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
        data: (status) {
          // Check if user is checked in at office
          final isCheckedIn = attendanceStatus.value?.checkIn != null &&
              attendanceStatus.value?.checkOut == null;

          if (isCheckedIn && !status.isRunning) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GlassmorphismCard(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.business,
                          size: 64,
                          color: IntraZeroColors.success,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Checked In at Office',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: IntraZeroColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'You are currently checked in at ${attendanceStatus.value?.checkIn?.location ?? "Office"}. Timesheet is disabled during office hours.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: IntraZeroColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: IntraZeroColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    IntraZeroColors.success.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.access_time,
                                  color: IntraZeroColors.success),
                              const SizedBox(width: 10),
                              Text(
                                'Check-in Time: ${attendanceStatus.value?.checkIn?.time ?? "--:--"}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: IntraZeroColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
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
                          _formatDuration(_elapsedSeconds),
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
                      if (!status.isRunning) ...[
                        GradientButton(
                          text: 'Start Timer',
                          gradient: IntraZeroColors.progressGradient,
                          icon: Icons.play_arrow,
                          isFullWidth: true,
                          onPressed: () =>
                              _showStartTimerOptions(timesheetNotifier),
                        ),
                        const SizedBox(height: 12),
                        GradientButton(
                          text: 'Start from Morning Plan',
                          gradient: IntraZeroColors.morningGradient,
                          icon: Icons.list_alt,
                          isFullWidth: true,
                          onPressed: () =>
                              _handleStartFromPlan(timesheetNotifier),
                        ),
                      ] else if (status.currentEntry != null)
                        GradientButton(
                          text: 'Stop Timer',
                          gradient: IntraZeroColors.eveningGradient,
                          icon: Icons.stop,
                          isFullWidth: true,
                          onPressed: () => _handleStopTimer(
                              timesheetNotifier, status.currentEntry!.id),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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

  Future<void> _showStartTimerOptions(TimesheetStatusNotifier notifier) async {
    if (!mounted) return;

    final option = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Timer'),
        content: const Text('How would you like to start the timer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'new'),
            child: const Text('Start New Timer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'plan'),
            child: const Text('Start from Morning Plan'),
          ),
        ],
      ),
    );

    if (option == 'new') {
      await _handleStartTimer(notifier);
    } else if (option == 'plan') {
      await _handleStartFromPlan(notifier);
    }
  }

  Future<void> _handleStartTimer(TimesheetStatusNotifier notifier) async {
    try {
      await notifier.start(description: 'General work tracking');
      if (mounted) {
        // Timer will start automatically when status updates
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

  Future<void> _handleStartFromPlan(TimesheetStatusNotifier notifier) async {
    try {
      final repository = TimesheetRepository(ref.read(apiClientProvider));
      final response = await repository.getMorningPlanTasks();

      if (!response.success ||
          response.data == null ||
          response.data!.tasks.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No morning plan tasks available. Please submit your morning plan first.'),
              backgroundColor: IntraZeroColors.warning,
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      // Show task selector dialog with better UI
      final selectedTask = await showDialog<MorningPlanTaskModel>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: GlassmorphismCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.list_alt,
                          color: IntraZeroColors.primaryGradient.colors.first),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Select Task from Morning Plan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: response.data!.tasks.length,
                      itemBuilder: (context, index) {
                        final task = response.data!.tasks[index];
                        return InkWell(
                          onTap: () => Navigator.pop(context, task),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: IntraZeroColors.surfaceLight,
                              border: Border.all(
                                  color: IntraZeroColors.borderLight, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        task.projectName ??
                                            task.category ??
                                            'No project',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: IntraZeroColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (task.estimatedHours != null) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color:
                                          IntraZeroColors.info.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${task.estimatedHours!.toStringAsFixed(1)}h',
                                      style: TextStyle(
                                        color: IntraZeroColors.info,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (selectedTask == null) return;

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Starting timer...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Start timer with selected plan task
      print(
          '🔄 [TIMESHEET] Starting timer from plan - taskId: ${selectedTask.id}, projectId: ${selectedTask.projectId}');
      final startResponse = await repository.startFromPlan(
        standupTaskId: selectedTask.id,
        projectId: selectedTask.projectId,
      );

      print(
          '📥 [TIMESHEET] Start from plan response - success: ${startResponse.success}, message: ${startResponse.message}');
      if (startResponse.data != null) {
        print('📥 [TIMESHEET] Response data: ${startResponse.data}');
      }

      if (startResponse.success && startResponse.data != null) {
        // Get the timer start time from response
        final timerData = startResponse.data!;
        final startedAt = timerData['started_at']?.toString() ??
            timerData['start_time']?.toString() ??
            timerData['start']?.toString();
        final timerId = timerData['timer_id'] ?? timerData['id'];
        final entryId = timerData['entry_id'] ?? timerData['id'];

        print(
            '📥 [TIMESHEET] Parsed - startedAt: $startedAt, timerId: $timerId, entryId: $entryId');

        // Start local timer immediately with the start time from response
        DateTime? startTime;
        if (startedAt != null) {
          try {
            startTime = DateTime.parse(startedAt);
            print('📥 [TIMESHEET] Parsed start time: $startTime');
          } catch (e) {
            print('⚠️ [TIMESHEET] Failed to parse start time: $e');
            startTime = DateTime.now();
          }
        } else {
          print('⚠️ [TIMESHEET] No start time in response, using current time');
          startTime = DateTime.now();
        }

        // Start the timer immediately
        _startTimer(startTime);
        print('✅ [TIMESHEET] Local timer started at: $startTime');

        // Refresh status to get updated timer state (this will sync with server)
        await notifier.loadStatus();
        print('🔄 [TIMESHEET] Status refreshed');

        // Wait a bit and verify the timer actually started
        await Future.delayed(const Duration(milliseconds: 800));
        final updatedStatus = ref.read(timesheetStatusProvider);

        await updatedStatus.when(
          data: (status) async {
            print(
                '📊 [TIMESHEET] Status check - isRunning: ${status.isRunning}, hasEntry: ${status.currentEntry != null}');
            if (status.isRunning && status.currentEntry != null) {
              // Timer confirmed running
              print('✅ [TIMESHEET] Timer confirmed running');
              if (mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Timer started: ${selectedTask.title}'),
                    backgroundColor: IntraZeroColors.success,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            } else {
              // Timer didn't start - try fallback to regular start
              print(
                  '⚠️ [TIMESHEET] Timer not running, trying fallback to regular start method');
              try {
                await notifier.start(
                  projectId: selectedTask.projectId,
                  description: selectedTask.title,
                );
                await notifier.loadStatus();
                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Timer started (fallback): ${selectedTask.title}'),
                      backgroundColor: IntraZeroColors.success,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                print('❌ [TIMESHEET] Fallback also failed: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Failed to start timer. Please try again or contact support.'),
                      backgroundColor: IntraZeroColors.danger,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            }
          },
          loading: () {},
          error: (error, stack) {
            print('❌ [TIMESHEET] Error checking status: $error');
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error verifying timer: ${error.toString()}'),
                  backgroundColor: IntraZeroColors.danger,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  startResponse.message ?? 'Failed to start timer from plan'),
              backgroundColor: IntraZeroColors.danger,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: IntraZeroColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleStopTimer(
      TimesheetStatusNotifier notifier, int entryId) async {
    try {
      _stopTimer();
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
