import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
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
  ConsumerState<AttendanceHomeScreen> createState() => _AttendanceHomeScreenState();
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
                MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
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
                      _buildTimeCard('Check In', status.checkIn!.time, Icons.login, IntraZeroColors.success),
                      const SizedBox(height: 20),
                    ],
                    if (status.checkOut != null) ...[
                      _buildTimeCard('Check Out', status.checkOut!.time, Icons.logout, IntraZeroColors.danger),
                      const SizedBox(height: 20),
                    ],
                    _buildTimeCard('Work Hours', status.workHours, Icons.access_time, IntraZeroColors.info),
                    const SizedBox(height: 30),
                    if (status.status == 'NOT_CHECKED_IN')
                      GradientButton(
                        text: 'Check In',
                        gradient: IntraZeroColors.progressGradient,
                        icon: Icons.login,
                        isFullWidth: true,
                        onPressed: () => _handleCheckIn(attendanceNotifier),
                      )
                    else if (status.status == 'CHECKED_IN')
                      _buildCheckOutButton(attendanceNotifier),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForgotCheckinScreen()),
                  );
                },
                icon: const Icon(Icons.help_outline),
                label: const Text('Forgot to Check In/Out?'),
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
                onPressed: () => attendanceNotifier.loadStatus(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _handleCheckIn(AttendanceStatusNotifier notifier) async {
    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition();
      } catch (e) {
        // Location not available, continue without it
      }
      
      final responseData = await notifier.checkIn(
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
      
      if (mounted) {
        // Check morning plan status from response
        if (responseData != null) {
          final morningPlanRequired = responseData['morning_plan_required'] as bool? ?? false;
          final morningPlanSubmitted = responseData['morning_plan_submitted'] as bool? ?? false;
          
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
                content: Text('Checked in successfully! Morning plan already submitted.'),
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
              content: Text(checkoutStatus.blockingReason ?? 'Please complete your evening summary before checking out'),
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
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition();
      } catch (e) {
        // Location not available, continue without it
      }
      
      await notifier.checkOut(
        latitude: position?.latitude,
        longitude: position?.longitude,
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
                    Icon(Icons.warning, color: IntraZeroColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        checkoutStatus.blockingReason ?? 'Please complete your evening summary before checking out',
                        style: TextStyle(
                          fontSize: 12,
                          color: IntraZeroColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
}

