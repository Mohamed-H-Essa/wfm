import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/themes/colors.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../data/repositories/timesheet_repository.dart';
import '../../data/models/timesheet_entry_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final timesheetEntriesProvider = FutureProvider.family<TimesheetEntriesModel, Map<String, String?>>((ref, params) async {
  final repository = TimesheetRepository(ref.watch(apiClientProvider));
  final response = await repository.getEntries(
    startDate: params['start_date'],
    endDate: params['end_date'],
    projectId: params['project_id'] != null ? int.tryParse(params['project_id']!) : null,
  );
  
  if (response.success && response.data != null) {
    return TimesheetEntriesModel.fromJson(response.data!);
  }
  throw Exception(response.message ?? 'Failed to load timesheet entries');
});

class TimesheetEntriesScreen extends ConsumerStatefulWidget {
  const TimesheetEntriesScreen({super.key});

  @override
  ConsumerState<TimesheetEntriesScreen> createState() => _TimesheetEntriesScreenState();
}

class _TimesheetEntriesScreenState extends ConsumerState<TimesheetEntriesScreen> {
  DateTime _startDate = DateTime.now().copyWith(day: 1);
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(timesheetEntriesProvider({
      'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
      'end_date': DateFormat('yyyy-MM-dd').format(_endDate),
    }));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timesheet Entries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _showDateRangePicker(context),
          ),
        ],
      ),
      body: entriesAsync.when(
        data: (entries) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(entries.summary),
              const SizedBox(height: 20),
              _buildEntriesList(entries.entries),
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
                onPressed: () => ref.refresh(timesheetEntriesProvider({
                  'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
                  'end_date': DateFormat('yyyy-MM-dd').format(_endDate),
                })),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(TimesheetSummaryModel summary) {
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
                child: _buildStatItem('Total', summary.totalDurationFormatted, IntraZeroColors.info),
              ),
              Expanded(
                child: _buildStatItem('Billable', summary.billableDuration, IntraZeroColors.success),
              ),
              Expanded(
                child: _buildStatItem('Non-Billable', summary.nonBillableDuration, IntraZeroColors.textSecondary),
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
            fontSize: 20,
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

  Widget _buildEntriesList(List<TimesheetEntryItemModel> entries) {
    if (entries.isEmpty) {
      return const Center(
        child: Text('No timesheet entries found'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Entries',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: IntraZeroColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...entries.map((entry) => _buildEntryCard(entry)),
      ],
    );
  }

  Widget _buildEntryCard(TimesheetEntryItemModel entry) {
    return Container(
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
                  entry.taskName ?? 'General Work',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: IntraZeroColors.textPrimary,
                  ),
                ),
              ),
              if (entry.isBillable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: IntraZeroColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Billable',
                    style: TextStyle(
                      fontSize: 12,
                      color: IntraZeroColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (entry.projectName != null) ...[
            const SizedBox(height: 4),
            Text(
              entry.projectName!,
              style: TextStyle(
                fontSize: 14,
                color: IntraZeroColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: IntraZeroColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${entry.startedAt} - ${entry.endedAt ?? "Running"}',
                style: TextStyle(
                  fontSize: 14,
                  color: IntraZeroColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                entry.durationFormatted,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: IntraZeroColors.textPrimary,
                ),
              ),
            ],
          ),
          if (entry.description != null) ...[
            const SizedBox(height: 8),
            Text(
              entry.description!,
              style: TextStyle(
                fontSize: 14,
                color: IntraZeroColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }
}
