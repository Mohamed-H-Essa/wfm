import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/models/api_response.dart';
import '../models/timesheet_status_model.dart';

class TimesheetRepository {
  final ApiClient _apiClient;
  
  TimesheetRepository(this._apiClient);
  
  Future<ApiResponse<TimesheetStatusModel>> getStatus() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.timesheetStatus);
      return ApiResponse(
        success: true,
        data: TimesheetStatusModel.fromJson(response.data['data']),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Failed to get timesheet status',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<Map<String, dynamic>>> start({
    int? taskId,
    int? projectId,
    String? description,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.timesheetStart,
        data: {
          if (taskId != null) 'task_id': taskId,
          if (projectId != null) 'project_id': projectId,
          if (description != null) 'description': description,
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
        message: e.error?.toString() ?? 'Failed to start timesheet',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<Map<String, dynamic>>> stop({
    required int entryId,
    String? description,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.timesheetStop,
        data: {
          'entry_id': entryId,
          if (description != null) 'description': description,
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
        message: e.error?.toString() ?? 'Failed to stop timesheet',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<Map<String, dynamic>>> getEntries({
    String? startDate,
    String? endDate,
    int? projectId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.timesheetEntries,
        queryParameters: {
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
          if (projectId != null) 'project_id': projectId,
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
        message: e.error?.toString() ?? 'Failed to get timesheet entries',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

