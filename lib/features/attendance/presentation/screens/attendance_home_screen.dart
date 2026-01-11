import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/themes/colors.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../../../core/network/api_client.dart';
import '../providers/attendance_provider.dart';
import 'attendance_history_screen.dart';
import 'forgot_checkin_screen.dart';
import '../../../daily_standup/presentation/screens/morning_plan_screen.dart';
import '../../../daily_standup/presentation/screens/evening_summary_screen.dart';

class AttendanceHomeScreen extends ConsumerStatefulWidget {
  const AttendanceHomeScreen({super.key});

  @override
  ConsumerState<AttendanceHomeScreen> createState() =>
      _AttendanceHomeScreenState();
}

class _AttendanceHomeScreenState extends ConsumerState<AttendanceHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(attendanceStatusProvider.notifier).loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final attendanceStatus = ref.watch(attendanceStatusProvider);
    final attendanceNotifier = ref.read(attendanceStatusProvider.notifier);

    return Scaffold(
      backgroundColor: IntraZeroColors.background,
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AttendanceHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              attendanceNotifier.loadStatus();
            },
          ),
        ],
      ),
      body: attendanceStatus.when(
        data: (status) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              GlassmorphismCard(
                child: Column(
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: IntraZeroColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (status.checkIn != null) ...[
                      _buildTimeCard('Check In', status.checkIn!.time,
                          Icons.login, IntraZeroColors.success),
                      const SizedBox(height: 20),
                    ],
                    if (status.checkOut != null) ...[
                      _buildTimeCard('Check Out', status.checkOut!.time,
                          Icons.logout, IntraZeroColors.danger),
                      const SizedBox(height: 20),
                    ],
                    // CM-1 Fix: Hide timer screen (Work Hours) when checked in
                    if (status.status != 'CHECKED_IN') ...[
                      _buildTimeCard('Work Hours', status.workHours,
                          Icons.access_time, IntraZeroColors.info),
                      const SizedBox(height: 30),
                    ],
                    if (status.status == 'NOT_CHECKED_IN')
                      GradientButton(
                        text: 'Check In',
                        gradient: IntraZeroColors.progressGradient,
                        icon: Icons.login,
                        isFullWidth: true,
                        onPressed: () => _handleCheckIn(attendanceNotifier),
                      )
                    else if (status.status == 'CHECKED_IN') ...[
                      // Show active timer when checked in
                      _ActiveTimer(initialWorkHours: status.workHours),
                      const SizedBox(height: 30),
                      _buildCheckOutButton(attendanceNotifier),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ForgotCheckinScreen()),
                  );
                },
                icon: const Icon(Icons.help_outline),
                label: const Text('Forgot to Check In/Out?'),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          // Check if this is a holiday/weekend/not available message
          final errorMessage = error.toString().toLowerCase();
          final isHolidayOrWeekend = errorMessage.contains('holiday') ||
              errorMessage.contains('weekend') ||
              errorMessage.contains('not available') ||
              errorMessage.contains('day off') ||
              errorMessage.contains('closed') ||
              errorMessage.contains('unavailable') ||
              errorMessage.contains('off day');

          if (isHolidayOrWeekend) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 80,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enjoy your day off! 🎉',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Regular error with retry button
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => attendanceNotifier.loadStatus(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleCheckIn(AttendanceStatusNotifier notifier) async {
    try {
      final position = await _determinePosition();
      if (position == null) return;

      final responseData = await notifier.checkIn(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (mounted) {
        // Check morning plan status from response
        if (responseData != null) {
          final morningPlanRequired =
              responseData['morning_plan_required'] as bool? ?? false;
          final morningPlanSubmitted =
              responseData['morning_plan_submitted'] as bool? ?? false;

          if (morningPlanRequired && !morningPlanSubmitted) {
            // Auto-redirect to morning plan screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MorningPlanScreen(),
              ),
            ).then((_) {
              // Refresh status after returning from morning plan
              notifier.loadStatus();
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please submit your morning plan'),
                backgroundColor: IntraZeroColors.warning,
                duration: Duration(seconds: 3),
              ),
            );
          } else if (morningPlanRequired && morningPlanSubmitted) {
            // Morning plan already submitted - show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Checked in successfully! Morning plan already submitted.'),
                backgroundColor: IntraZeroColors.success,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Checked in successfully'),
                backgroundColor: IntraZeroColors.success,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Checked in successfully'),
              backgroundColor: IntraZeroColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in failed: ${e.toString()}'),
            backgroundColor: IntraZeroColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleCheckOut(AttendanceStatusNotifier notifier) async {
    try {
      // First check if checkout is allowed
      final checkoutStatusAsync = ref.read(checkoutStatusProvider.future);
      final checkoutStatus = await checkoutStatusAsync;

      if (!checkoutStatus.canCheckout) {
        // Show blocking dialog and navigate to evening summary
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Check-out Blocked'),
              content: Text(checkoutStatus.blockingReason ??
                  'Please complete your evening summary before checking out'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EveningSummaryScreen(),
                      ),
                    ).then((_) {
                      // Refresh status after returning from evening summary
                      notifier.loadStatus();
                      ref.invalidate(checkoutStatusProvider);
                    });
                  },
                  child: const Text('Complete Evening Summary'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Checkout is allowed, proceed
      final position = await _determinePosition();
      if (position == null) return;

      await notifier.checkOut(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checked out successfully'),
            backgroundColor: IntraZeroColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-out failed: ${e.toString()}'),
            backgroundColor: IntraZeroColors.danger,
          ),
        );
      }
    }
  }

  Widget _buildCheckOutButton(AttendanceStatusNotifier notifier) {
    final checkoutStatusAsync = ref.watch(checkoutStatusProvider);

    return checkoutStatusAsync.when(
      data: (checkoutStatus) {
        final isBlocked = !checkoutStatus.canCheckout;

        return Column(
          children: [
            if (isBlocked) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: IntraZeroColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: IntraZeroColors.warning),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning,
                        color: IntraZeroColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        checkoutStatus.blockingReason ??
                            'Please complete your evening summary before checking out',
                        style: TextStyle(
                          fontSize: 12,
                          color: IntraZeroColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GradientButton(
                text: 'Complete Evening Summary',
                gradient: IntraZeroColors.eveningGradient,
                icon: Icons.edit_note,
                isFullWidth: true,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EveningSummaryScreen(),
                    ),
                  ).then((_) {
                    notifier.loadStatus();
                    ref.invalidate(checkoutStatusProvider);
                  });
                },
              ),
            ],
            const SizedBox(height: 12),
            GradientButton(
              text: 'Check Out',
              gradient: IntraZeroColors.eveningGradient,
              icon: Icons.logout,
              isFullWidth: true,
              onPressed: isBlocked ? null : () => _handleCheckOut(notifier),
            ),
          ],
        );
      },
      loading: () => GradientButton(
        text: 'Check Out',
        gradient: IntraZeroColors.eveningGradient,
        icon: Icons.logout,
        isFullWidth: true,
        onPressed: () => _handleCheckOut(notifier),
      ),
      error: (error, stack) => GradientButton(
        text: 'Check Out',
        gradient: IntraZeroColors.eveningGradient,
        icon: Icons.logout,
        isFullWidth: true,
        onPressed: () => _handleCheckOut(notifier),
      ),
    );
  }

  Widget _buildTimeCard(String label, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IntraZeroColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: IntraZeroColors.textSecondary,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: IntraZeroColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Position?> _determinePosition() async {
    // Check app-specific location setting
    final prefs = await SharedPreferences.getInstance();
    final isLocationEnabled =
        prefs.getBool('location_services_enabled') ?? true;

    if (!isLocationEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled in App Settings.'),
            backgroundColor: IntraZeroColors.warning,
          ),
        );
      }
      return null;
    }

    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Location services are disabled. Please enable them.'),
            backgroundColor: IntraZeroColors.warning,
          ),
        );
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are denied'),
              backgroundColor: IntraZeroColors.warning,
            ),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Location permissions are permanently denied, we cannot request permissions.'),
            backgroundColor: IntraZeroColors.danger,
          ),
        );
      }
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }
}

class _ActiveTimer extends StatefulWidget {
  final String initialWorkHours;
  const _ActiveTimer({required this.initialWorkHours});

  @override
  State<_ActiveTimer> createState() => _ActiveTimerState();
}

class _ActiveTimerState extends State<_ActiveTimer> {
  late Duration _duration;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _parseDuration();
    _startTimer();
  }

  @override
  void didUpdateWidget(_ActiveTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialWorkHours != widget.initialWorkHours) {
      _parseDuration();
    }
  }

  void _parseDuration() {
    try {
      final parts = widget.initialWorkHours.split(':');
      _duration = Duration(
        hours: int.parse(parts[0]),
        minutes: int.parse(parts[1]),
        seconds: int.parse(parts[2]),
      );
    } catch (e) {
      _duration = Duration.zero;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _duration += const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(_duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(_duration.inSeconds.remainder(60));
    return "${twoDigits(_duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: IntraZeroColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                IntraZeroColors.primaryGradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Currently Working',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDuration(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Tracking time',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
