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
                      GradientButton(
                        text: 'Check Out',
                        gradient: IntraZeroColors.eveningGradient,
                        icon: Icons.logout,
                        isFullWidth: true,
                        onPressed: () => _handleCheckOut(attendanceNotifier),
                      ),
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
      
      await notifier.checkIn(
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checked in successfully'),
            backgroundColor: IntraZeroColors.success,
          ),
        );
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

