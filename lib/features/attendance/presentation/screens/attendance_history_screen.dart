import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/themes/colors.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/models/attendance_history_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final attendanceHistoryProvider = FutureProvider.family<AttendanceHistoryModel, Map<String, int?>>((ref, params) async {
  final repository = AttendanceRepository(ref.watch(apiClientProvider));
  final response = await repository.getHistory(
    month: params['month'],
    year: params['year'],
    page: params['page'] ?? 1,
  );
  
  if (response.success && response.data != null) {
    return AttendanceHistoryModel.fromJson(response.data!);
  }
  throw Exception(response.message ?? 'Failed to load attendance history');
});

class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  ConsumerState<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends ConsumerState<AttendanceHistoryScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(attendanceHistoryProvider({
      'month': _selectedMonth,
      'year': _selectedYear,
      'page': 1,
    }));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showMonthYearPicker(context),
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
              _buildRecordsList(history.records),
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
                onPressed: () => ref.refresh(attendanceHistoryProvider({
                  'month': _selectedMonth,
                  'year': _selectedYear,
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

  Widget _buildSummaryCard(AttendanceSummaryModel summary) {
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
                child: _buildStatItem('Present', summary.presentDays.toString(), IntraZeroColors.success),
              ),
              Expanded(
                child: _buildStatItem('Absent', summary.absentDays.toString(), IntraZeroColors.danger),
              ),
              Expanded(
                child: _buildStatItem('Late', summary.lateDays.toString(), IntraZeroColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Work Hours',
                style: TextStyle(color: IntraZeroColors.textSecondary),
              ),
              Text(
                summary.totalWorkHours,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: IntraZeroColors.textPrimary,
                ),
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

  Widget _buildRecordsList(List<AttendanceRecordModel> records) {
    if (records.isEmpty) {
      return const Center(
        child: Text('No attendance records found'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Records',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: IntraZeroColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...records.map((record) => _buildRecordCard(record)),
      ],
    );
  }

  Widget _buildRecordCard(AttendanceRecordModel record) {
    Color statusColor;
    IconData statusIcon;
    
    switch (record.status) {
      case 'PRESENT':
        statusColor = IntraZeroColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'ABSENT':
        statusColor = IntraZeroColors.danger;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = IntraZeroColors.warning;
        statusIcon = Icons.pending;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IntraZeroColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IntraZeroColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM d, y').format(DateTime.parse(record.date)),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: IntraZeroColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (record.checkIn != null)
                  Text(
                    'In: ${record.checkIn}',
                    style: TextStyle(
                      fontSize: 14,
                      color: IntraZeroColors.textSecondary,
                    ),
                  ),
                if (record.checkOut != null)
                  Text(
                    'Out: ${record.checkOut}',
                    style: TextStyle(
                      fontSize: 14,
                      color: IntraZeroColors.textSecondary,
                    ),
                  ),
                Text(
                  'Hours: ${record.workHours}',
                  style: TextStyle(
                    fontSize: 14,
                    color: IntraZeroColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (record.isLate)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: IntraZeroColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Late',
                style: TextStyle(
                  fontSize: 12,
                  color: IntraZeroColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showMonthYearPicker(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear, _selectedMonth),
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
    );
    
    if (picked != null) {
      setState(() {
        _selectedMonth = picked.month;
        _selectedYear = picked.year;
      });
    }
  }
}
