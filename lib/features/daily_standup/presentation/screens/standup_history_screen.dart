import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/themes/colors.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../../../shared/widgets/progress_bar.dart';
import '../../data/repositories/standup_repository.dart';
import '../../data/models/standup_history_model.dart';
import '../../../../shared/models/api_response.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'standup_view_screen.dart';

// Typed params class for proper equality
@immutable
class StandupHistoryParams {
  final int month;
  final int year;
  final int page;

  const StandupHistoryParams({
    required this.month,
    required this.year,
    this.page = 1,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StandupHistoryParams &&
          month == other.month &&
          year == other.year &&
          page == other.page;

  @override
  int get hashCode => Object.hash(month, year, page);
}

// Cache to prevent repeated API calls
final _standupHistoryCache = <String, _StandupCache>{};
class _StandupCache {
  final StandupHistoryModel data;
  final DateTime timestamp;
  _StandupCache(this.data, this.timestamp);
}
const _standupCacheDuration = Duration(minutes: 5);

final standupHistoryProvider = FutureProvider.family<StandupHistoryModel, StandupHistoryParams>((ref, params) async {
  print('🚀 [STANDUP_HISTORY] Provider called with params: month=${params.month}, year=${params.year}, page=${params.page}');
  final cacheKey = '${params.month}_${params.year}_${params.page}';
  final cached = _standupHistoryCache[cacheKey];
  
  // Return cached data if still valid
  if (cached != null && DateTime.now().difference(cached.timestamp) < _standupCacheDuration) {
    print('💾 [STANDUP_HISTORY] Returning cached data');
    return cached.data;
  }
  print('🔄 [STANDUP_HISTORY] Cache miss or expired, fetching new data');
  
  // Create empty model as default
  final emptyModel = StandupHistoryModel(
    standups: [],
    summary: StandupHistorySummaryModel(
      totalSubmissions: 0,
      workingDays: 0,
      submissionRate: 0.0,
      averageCompletion: 0,
      averageProductivity: 0.0,
    ),
    pagination: PaginationModel(
      currentPage: 1,
      totalPages: 1,
      totalRecords: 0,
    ),
  );
  
  // Wrap entire operation in timeout to ensure it ALWAYS completes
  return (() async {
      try {
        print('🔍 [STANDUP_HISTORY] Starting provider execution');
        final apiClient = ref.read(apiClientProvider); // Use read instead of watch
        print('🔍 [STANDUP_HISTORY] Got API client');
        final token = await apiClient.getAccessToken();
        print('🔍 [STANDUP_HISTORY] Token: ${token != null ? "exists" : "null"}');
        if (token == null) {
          print('⚠️ [STANDUP_HISTORY] No token, returning empty model');
          return emptyModel;
        }
        
        final repository = StandupRepository(apiClient);
        print('🔍 [STANDUP_HISTORY] Calling repository.getHistory...');
        
        final response = await repository.getHistory(
          month: params.month,
          year: params.year,
          page: params.page,
        );
        
        print('📥 [STANDUP_HISTORY] Response received - success: ${response.success}, statusCode: ${response.statusCode}');
        print('📥 [STANDUP_HISTORY] Response data is null: ${response.data == null}');
        if (response.data != null) {
          print('📥 [STANDUP_HISTORY] Response data keys: ${(response.data as Map).keys.toList()}');
        }
        
        if (response.success && response.data != null) {
          try {
            print('📥 [STANDUP_HISTORY] Parsing data...');
            final model = StandupHistoryModel.fromJson(response.data!);
            print('✅ [STANDUP_HISTORY] Parsed successfully - standups: ${model.standups.length}');
            // Cache the result
            _standupHistoryCache[cacheKey] = _StandupCache(model, DateTime.now());
            return model;
          } catch (e, stack) {
            print('❌ [STANDUP_HISTORY] Parse error: $e');
            print('❌ [STANDUP_HISTORY] Stack: $stack');
            print('❌ [STANDUP_HISTORY] Response data: ${response.data}');
            return emptyModel;
          }
        } else {
          print('⚠️ [STANDUP_HISTORY] Response not successful or data is null');
          print('⚠️ [STANDUP_HISTORY] Message: ${response.message}');
        }
        print('⚠️ [STANDUP_HISTORY] Returning empty model (response not successful)');
        return emptyModel;
      } catch (e, stack) {
        print('❌ [STANDUP_HISTORY] Exception in provider: $e');
        print('❌ [STANDUP_HISTORY] Stack: $stack');
        return emptyModel;
      }
    })().timeout(
    const Duration(seconds: 12),
    onTimeout: () {
      print('⏰ [STANDUP_HISTORY] Timeout reached, returning empty model');
      return emptyModel;
    },
  );
});

class StandupHistoryScreen extends ConsumerStatefulWidget {
  const StandupHistoryScreen({super.key});

  @override
  ConsumerState<StandupHistoryScreen> createState() => _StandupHistoryScreenState();
}

class _StandupHistoryScreenState extends ConsumerState<StandupHistoryScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    print('🏗️ [STANDUP_HISTORY] Building widget - month: $_selectedMonth, year: $_selectedYear');
    final historyAsync = ref.watch(
      standupHistoryProvider(
        StandupHistoryParams(
          month: _selectedMonth,
          year: _selectedYear,
          page: 1,
        ),
      ),
    );
    print('📊 [STANDUP_HISTORY] AsyncValue state: ${historyAsync.isLoading ? "loading" : historyAsync.hasValue ? "hasValue" : historyAsync.hasError ? "hasError" : "unknown"}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Standup History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showMonthYearPicker(context),
          ),
        ],
      ),
      body: historyAsync.when(
        data: (history) {
          print('🎨 [STANDUP_HISTORY] UI rendering with data - standups: ${history.standups.length}');
          if (history.standups.isEmpty) {
            return const Center(
              child: Text('No standup history found'),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(history.summary),
                const SizedBox(height: 20),
                _buildStandupsList(history.standups),
              ],
            ),
          );
        },
        loading: () {
          print('⏳ [STANDUP_HISTORY] UI showing loading state');
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stack) {
          print('❌ [STANDUP_HISTORY] UI showing error: $error');
          print('❌ [STANDUP_HISTORY] Stack: $stack');
          // On error, show empty state instead of error message
          return const Center(
            child: Text('No standup history found'),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(StandupHistorySummaryModel summary) {
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
                child: _buildStatItem('Submissions', summary.totalSubmissions.toString(), IntraZeroColors.info),
              ),
              Expanded(
                child: _buildStatItem('Rate', '${summary.submissionRate.toStringAsFixed(1)}%', IntraZeroColors.success),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Avg Completion', '${summary.averageCompletion.toStringAsFixed(1)}%', IntraZeroColors.progressGradient.colors.first),
              ),
              Expanded(
                child: _buildStatItem('Avg Productivity', summary.averageProductivity.toStringAsFixed(1), IntraZeroColors.warning),
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

  Widget _buildStandupsList(List<StandupHistoryItemModel> standups) {
    if (standups.isEmpty) {
      return const Center(
        child: Text('No standup records found'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Standups',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: IntraZeroColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...standups.map((standup) => _buildStandupCard(standup)),
      ],
    );
  }

  Widget _buildStandupCard(StandupHistoryItemModel standup) {
    final progress = standup.tasksTotal > 0
        ? standup.tasksCompleted / standup.tasksTotal
        : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StandupViewScreen(standupId: standup.id),
          ),
        );
      },
      child: Container(
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
                    DateFormat('MMM d, y').format(DateTime.parse(standup.date)),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: IntraZeroColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(standup.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    standup.status,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(standup.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (standup.todayGoals != null) ...[
              const SizedBox(height: 8),
              Text(
                standup.todayGoals!,
                style: TextStyle(
                  fontSize: 14,
                  color: IntraZeroColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            ProgressBar(
              progress: progress,
              label: 'Tasks: ${standup.tasksCompleted}/${standup.tasksTotal}',
            ),
            if (standup.productivityRating != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: IntraZeroColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    standup.productivityRating!.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 14,
                      color: IntraZeroColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETE':
        return IntraZeroColors.success;
      case 'IN_PROGRESS':
        return IntraZeroColors.warning;
      default:
        return IntraZeroColors.textSecondary;
    }
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
