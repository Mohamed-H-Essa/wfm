import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/models/api_response.dart';

class LeaveRepository {
  final ApiClient _apiClient;
  
  LeaveRepository(this._apiClient);
  
  Future<ApiResponse<Map<String, dynamic>>> getBalance() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.leaveBalance);
      return ApiResponse(
        success: true,
        data: response.data['data'] as Map<String, dynamic>,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Failed to get leave balance',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<List<dynamic>>> getRequests() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.leaveRequests);
      return ApiResponse(
        success: true,
        data: response.data['data'] as List<dynamic>,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Failed to get leave requests',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<Map<String, dynamic>>> submitRequest({
    required String leaveType,
    required String startDate,
    required String endDate,
    required String reason,
    String? attachment,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.leaveRequest,
        data: {
          'leave_type': leaveType,
          'start_date': startDate,
          'end_date': endDate,
          'reason': reason,
          if (attachment != null) 'attachment': attachment,
        },
      );
      return ApiResponse(
        success: true,
        data: response.data['data'] as Map<String, dynamic>,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Failed to submit leave request',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

