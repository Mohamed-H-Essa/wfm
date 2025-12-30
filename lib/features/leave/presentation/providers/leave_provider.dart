import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/leave_repository.dart';
import '../../data/models/leave_balance_model.dart';
import '../../data/models/leave_request_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  return LeaveRepository(ref.watch(apiClientProvider));
});

final leaveBalanceProvider = FutureProvider<LeaveBalanceModel>((ref) async {
  final repository = ref.watch(leaveRepositoryProvider);
  final response = await repository.getBalance();
  if (response.success && response.data != null) {
    return LeaveBalanceModel.fromJson(response.data!);
  }
  throw Exception(response.message ?? 'Failed to load leave balance');
});

final leaveRequestsProvider = FutureProvider<List<LeaveRequestModel>>((ref) async {
  final repository = ref.watch(leaveRepositoryProvider);
  final response = await repository.getRequests();
  if (response.success && response.data != null) {
    return (response.data as List<dynamic>)
        .map((r) => LeaveRequestModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }
  throw Exception(response.message ?? 'Failed to load leave requests');
});

