import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/models/attendance_status_model.dart';
import '../../data/models/checkout_status_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(apiClientProvider));
});

final attendanceStatusProvider = StateNotifierProvider<AttendanceStatusNotifier, AsyncValue<AttendanceStatusModel>>((ref) {
  return AttendanceStatusNotifier(ref.watch(attendanceRepositoryProvider));
});

final checkoutStatusProvider = FutureProvider<CheckoutStatusModel>((ref) async {
  final repository = ref.watch(attendanceRepositoryProvider);
  final response = await repository.getCheckoutStatus();
  if (response.success && response.data != null) {
    return response.data!;
  } else {
    // Return default allowing checkout if API fails
    return CheckoutStatusModel(
      canCheckout: true,
      eveningSummaryRequired: false,
      eveningSummarySubmitted: false,
    );
  }
});

class AttendanceStatusNotifier extends StateNotifier<AsyncValue<AttendanceStatusModel>> {
  final AttendanceRepository _repository;
  
  AttendanceStatusNotifier(this._repository) : super(const AsyncValue.loading()) {
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
  
  Future<Map<String, dynamic>?> checkIn({
    double? latitude,
    double? longitude,
  }) async {
    final response = await _repository.checkIn(
      latitude: latitude,
      longitude: longitude,
    );
    
    if (response.success) {
      await loadStatus();
      return response.data; // Return response data to check morning plan status
    } else {
      throw Exception(response.message ?? 'Check-in failed');
    }
  }
  
  Future<void> checkOut({
    double? latitude,
    double? longitude,
  }) async {
    final response = await _repository.checkOut(
      latitude: latitude,
      longitude: longitude,
    );
    
    if (response.success) {
      await loadStatus();
    } else {
      throw Exception(response.message ?? 'Check-out failed');
    }
  }
}

