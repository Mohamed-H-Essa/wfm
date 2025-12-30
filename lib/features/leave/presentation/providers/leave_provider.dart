import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/leave_repository.dart';
import '../../data/models/leave_balance_model.dart';
import '../../data/models/leave_request_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  return LeaveRepository(ref.watch(apiClientProvider));
});

final leaveBalanceProvider = FutureProvider<LeaveBalanceModel>((ref) async {
  // Create empty model as default
  final emptyModel = LeaveBalanceModel(
    annualLeave: LeaveTypeBalance(total: 0, used: 0, remaining: 0, pending: 0),
    accidentalLeave: LeaveTypeBalance(total: 0, used: 0, remaining: 0, pending: 0),
    marriageLeave: LeaveTypeBalance(total: 0, used: 0, remaining: 0, pending: 0),
  );
  
  try {
    final repository = ref.watch(leaveRepositoryProvider);
    final response = await repository.getBalance().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Request timeout'),
    );
    
    if (response.success && response.data != null) {
      try {
        return LeaveBalanceModel.fromJson(response.data!);
      } catch (e) {
        return emptyModel;
      }
    }
  } catch (e) {
    // Return empty model on error
    return emptyModel;
  }
  
  return emptyModel;
});

final leaveRequestsProvider = FutureProvider<List<LeaveRequestModel>>((ref) async {
  try {
    final repository = ref.watch(leaveRepositoryProvider);
    final response = await repository.getRequests().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Request timeout'),
    );
    
    if (response.success && response.data != null) {
      try {
        // response.data is already List<dynamic> from repository
        final dataList = response.data!;
        return dataList
            .map((r) => LeaveRequestModel.fromJson(r as Map<String, dynamic>))
            .toList();
      } catch (e) {
        return [];
      }
    }
  } catch (e) {
    // Return empty list on error
    return [];
  }
  
  return [];
});
