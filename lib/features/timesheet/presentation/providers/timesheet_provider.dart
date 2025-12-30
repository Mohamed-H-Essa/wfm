import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/timesheet_repository.dart';
import '../../data/models/timesheet_status_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final timesheetRepositoryProvider = Provider<TimesheetRepository>((ref) {
  return TimesheetRepository(ref.watch(apiClientProvider));
});

final timesheetStatusProvider = StateNotifierProvider<TimesheetStatusNotifier, AsyncValue<TimesheetStatusModel>>((ref) {
  return TimesheetStatusNotifier(ref.watch(timesheetRepositoryProvider));
});

class TimesheetStatusNotifier extends StateNotifier<AsyncValue<TimesheetStatusModel>> {
  final TimesheetRepository _repository;
  
  TimesheetStatusNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadStatus();
  }
  
  Future<void> loadStatus() async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.getStatus();
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data!);
      } else {
        state = AsyncValue.error(response.message ?? 'Failed to load status', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> start({
    int? taskId,
    int? projectId,
    String? description,
  }) async {
    final response = await _repository.start(
      taskId: taskId,
      projectId: projectId,
      description: description,
    );
    
    if (response.success) {
      await loadStatus();
    } else {
      throw Exception(response.message ?? 'Failed to start timesheet');
    }
  }
  
  Future<void> stop({required int entryId, String? description}) async {
    final response = await _repository.stop(
      entryId: entryId,
      description: description,
    );
    
    if (response.success) {
      await loadStatus();
    } else {
      throw Exception(response.message ?? 'Failed to stop timesheet');
    }
  }
}

