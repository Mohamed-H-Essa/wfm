import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/themes/colors.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../data/repositories/timesheet_repository.dart';
import '../../data/models/timesheet_entry_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/api_response.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Typed params class for proper equality
@immutable
class TimesheetEntriesParams {
  final String startDate;
  final String endDate;
  final String? projectId;

  const TimesheetEntriesParams({
    required this.startDate,
    required this.endDate,
    this.projectId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimesheetEntriesParams &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          projectId == other.projectId;

  @override
  int get hashCode => Object.hash(startDate, endDate, projectId);
}

// Cache to prevent repeated API calls
final _timesheetEntriesCache = <String, _TimesheetCache>{};
class _TimesheetCache {
  final TimesheetEntriesModel data;
  final DateTime timestamp;
  _TimesheetCache(this.data, this.timestamp);
}
const _timesheetCacheDuration = Duration(minutes: 5);

final timesheetEntriesProvider = FutureProvider.family<TimesheetEntriesModel, TimesheetEntriesParams>((ref, params) async {
  final cacheKey = '${params.startDate}_${params.endDate}_${params.projectId ?? ''}';
  final cached = _timesheetEntriesCache[cacheKey];
  
  // Return cached data if still valid (less than 5 minutes old)
  if (cached != null && DateTime.now().difference(cached.timestamp) < _timesheetCacheDuration) {
    print('💾 [TIMESHEET_ENTRIES] Returning cached data');
    return cached.data;
  }
  
  final emptyModel = TimesheetEntriesModel(
    entries: [],
    summary: TimesheetSummaryModel(
      totalDurationSeconds: 0,
      totalDurationFormatted: '00:00:00',
      billableDuration: '00:00:00',
      nonBillableDuration: '00:00:00',
    ),
  );
  
  return (() async {
      try {
        final apiClient = ref.read(apiClientProvider); // Use read instead of watch to prevent rebuilds
        final token = await apiClient.getAccessToken();
        if (token == null) {
          return emptyModel;
        }
        
        final repository = TimesheetRepository(apiClient);
        print('🔍 [TIMESHEET_ENTRIES] Making API call - startDate: ${params.startDate}, endDate: ${params.endDate}');
        
        final response = await repository.getEntries(
          startDate: params.startDate,
          endDate: params.endDate,
          projectId: params.projectId != null ? int.tryParse(params.projectId!) : null,
        );
        
        print('📥 [TIMESHEET_ENTRIES] Response received - success: ${response.success}, statusCode: ${response.statusCode}');
        print('📥 [TIMESHEET_ENTRIES] Response data is null: ${response.data == null}');
        if (response.data != null) {
          print('📥 [TIMESHEET_ENTRIES] Response data keys: ${(response.data as Map).keys.toList()}');
        }
        
        if (response.success && response.data != null) {
          try {
            print('📥 [TIMESHEET_ENTRIES] Parsing data...');
            final model = TimesheetEntriesModel.fromJson(response.data!);
            print('✅ [TIMESHEET_ENTRIES] Parsed - entries: ${model.entries.length}');
            // Cache the result
            _timesheetEntriesCache[cacheKey] = _TimesheetCache(model, DateTime.now());
            return model;
          } catch (e, stack) {
            print('❌ [TIMESHEET_ENTRIES] Parse error: $e');
            print('❌ [TIMESHEET_ENTRIES] Stack: $stack');
            print('❌ [TIMESHEET_ENTRIES] Response data: ${response.data}');
            return emptyModel;
          }
        } else {
          print('⚠️ [TIMESHEET_ENTRIES] Response not successful or data is null');
          print('⚠️ [TIMESHEET_ENTRIES] Message: ${response.message}');
        }
        return emptyModel;
      } catch (e) {
        return emptyModel;
      }
    })().timeout(
    const Duration(seconds: 12),
    onTimeout: () {
      return emptyModel;
    },
  );
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
    final params = TimesheetEntriesParams(
      startDate: DateFormat('yyyy-MM-dd').format(_startDate),
      endDate: DateFormat('yyyy-MM-dd').format(_endDate),
    );
    
    final entriesAsync = ref.watch(timesheetEntriesProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timesheet Entries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Clear cache and refresh
              final cacheKey = '${params.startDate}_${params.endDate}_${params.projectId ?? ''}';
              _timesheetEntriesCache.remove(cacheKey);
              ref.invalidate(timesheetEntriesProvider(params));
            },
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _showDateRangePicker(context),
          ),
        ],
      ),
      body: entriesAsync.when(
        data: (entries) {
          print('🎨 [TIMESHEET_ENTRIES] UI rendering with data - entries: ${entries.entries.length}');
          if (entries.entries.isEmpty) {
            return const Center(child: Text('No timesheet entries found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(entries.summary),
                const SizedBox(height: 20),
                _buildEntriesList(entries.entries),
              ],
            ),
          );
        },
        loading: () {
          print('⏳ [TIMESHEET_ENTRIES] UI showing loading state');
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stack) {
          print('❌ [TIMESHEET_ENTRIES] UI showing error: $error');
          print('❌ [TIMESHEET_ENTRIES] Stack: $stack');
          return const Center(child: Text('No timesheet entries found'));
        },
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
          _buildStatItem('Total Duration', summary.totalDurationFormatted, IntraZeroColors.info),
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
          Text(
            entry.taskName ?? 'General Work',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: IntraZeroColors.textPrimary,
            ),
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
