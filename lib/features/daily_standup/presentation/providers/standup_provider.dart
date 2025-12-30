import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/standup_repository.dart';
import '../../data/models/project_model.dart';
import '../../data/models/standup_status_model.dart';
import '../../data/models/standup_reminder_status_model.dart';
import '../../data/models/standup_editability_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final standupRepositoryProvider = Provider<StandupRepository>((ref) {
  return StandupRepository(ref.watch(apiClientProvider));
});

final standupProjectsProvider = FutureProvider<List<Project>>((ref) async {
  try {
    final repository = ref.watch(standupRepositoryProvider);
    final response = await repository.getProjects().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Request timeout'),
    );
    
    if (response.success && response.data != null) {
      return response.data!;
    }
  } catch (e) {
    // Return empty list on error
    return [];
  }
  
  return [];
});

final standupStatusProvider = StateNotifierProvider<StandupStatusNotifier, AsyncValue<StandupStatusModel?>>((ref) {
  return StandupStatusNotifier(ref.watch(standupRepositoryProvider));
});

final standupReminderStatusProvider = FutureProvider<StandupReminderStatusModel>((ref) async {
  final repository = ref.watch(standupRepositoryProvider);
  final response = await repository.getReminderStatus();
  if (response.success && response.data != null) {
    return response.data!;
  } else {
    // Return default reminder status if API fails
    return StandupReminderStatusModel(
      morning: MorningReminderStatus(
        needsReminder: false,
        deadline: '12:00:00',
        deadlinePassed: false,
        submitted: false,
      ),
      evening: EveningReminderStatus(
        needsReminder: false,
        deadline: '20:00:00',
        deadlinePassed: false,
        submitted: false,
      ),
      settings: ReminderSettings(
        morningReminderEnabled: true,
        morningReminderTime: '10:30:00',
        eveningReminderEnabled: true,
        eveningReminderTime: '17:00:00',
      ),
    );
  }
});

final standupEditabilityProvider = FutureProvider<StandupEditabilityModel>((ref) async {
  final repository = ref.watch(standupRepositoryProvider);
  final response = await repository.getEditabilityStatus();
  if (response.success && response.data != null) {
    return response.data!;
  } else {
    // Return default editability status if API fails
    return StandupEditabilityModel(
      morning: MorningEditability(
        canEdit: false,
        submitted: false,
        editDeadlinePassed: false,
      ),
    );
  }
});

class StandupStatusNotifier extends StateNotifier<AsyncValue<StandupStatusModel?>> {
  final StandupRepository _repository;
  
  StandupStatusNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadStatus();
  }
  
  Future<void> loadStatus() async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.getStatus().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data!);
      } else {
        // Return null data instead of error - let UI handle it gracefully
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      // Return null data instead of error
      state = const AsyncValue.data(null);
    }
  }
}
