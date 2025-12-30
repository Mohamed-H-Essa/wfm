import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/models/api_response.dart';
import '../models/timesheet_status_model.dart';
import '../models/morning_plan_task_model.dart';

class TimesheetRepository {
  final ApiClient _apiClient;
  
  TimesheetRepository(this._apiClient);
  
  Future<ApiResponse<TimesheetStatusModel>> getStatus() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.timesheetStatus);
      
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        final success = responseMap['success'] as bool? ?? true;
        
        if (success && responseMap['data'] != null) {
          return ApiResponse(
            success: true,
            data: TimesheetStatusModel.fromJson(responseMap['data'] as Map<String, dynamic>),
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            message: responseMap['message']?.toString() ?? 'Failed to get timesheet status',
            statusCode: response.statusCode,
          );
        }
      }
      
      return ApiResponse(
        success: false,
        message: 'Invalid response format',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      String? errorMessage;
      if (e.response?.data is Map<String, dynamic>) {
        errorMessage = e.response?.data['message']?.toString();
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage ?? e.error?.toString() ?? 'Failed to get timesheet status',
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
      
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        final success = responseMap['success'] as bool? ?? true;
        
        if (success && responseMap['data'] != null) {
          return ApiResponse(
            success: true,
            data: responseMap['data'] as Map<String, dynamic>,
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            message: responseMap['message']?.toString() ?? 'Failed to start timesheet',
            statusCode: response.statusCode,
          );
        }
      }
      
      return ApiResponse(
        success: false,
        message: 'Invalid response format',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      String? errorMessage;
      if (e.response?.data is Map<String, dynamic>) {
        errorMessage = e.response?.data['message']?.toString();
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage ?? e.error?.toString() ?? 'Failed to start timesheet',
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
      
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        final success = responseMap['success'] as bool? ?? true;
        
        if (success && responseMap['data'] != null) {
          return ApiResponse(
            success: true,
            data: responseMap['data'] as Map<String, dynamic>,
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            message: responseMap['message']?.toString() ?? 'Failed to stop timesheet',
            statusCode: response.statusCode,
          );
        }
      }
      
      return ApiResponse(
        success: false,
        message: 'Invalid response format',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      String? errorMessage;
      if (e.response?.data is Map<String, dynamic>) {
        errorMessage = e.response?.data['message']?.toString();
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage ?? e.error?.toString() ?? 'Failed to stop timesheet',
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
      
      // API returns {"success": true, "data": {...}} or {"success": false, "message": "..."}
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        final success = responseMap['success'] as bool? ?? true;
        
        if (success && responseMap['data'] != null) {
          return ApiResponse(
            success: true,
            data: responseMap['data'] as Map<String, dynamic>,
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            message: responseMap['message']?.toString() ?? 'Failed to get timesheet entries',
            statusCode: response.statusCode,
          );
        }
      }
      
      return ApiResponse(
        success: false,
        message: 'Invalid response format',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      // Extract message from error response
      String? errorMessage;
      if (e.response?.data is Map<String, dynamic>) {
        errorMessage = e.response?.data['message']?.toString();
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage ?? e.error?.toString() ?? 'Failed to get timesheet entries',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<MorningPlanTasksModel>> getMorningPlanTasks() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.timesheetMorningPlanTasks);
      
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        final success = responseMap['success'] as bool? ?? true;
        
        if (success && responseMap['data'] != null) {
          return ApiResponse(
            success: true,
            data: MorningPlanTasksModel.fromJson(responseMap['data'] as Map<String, dynamic>),
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            message: responseMap['message']?.toString() ?? 'Failed to get morning plan tasks',
            statusCode: response.statusCode,
          );
        }
      }
      
      return ApiResponse(
        success: false,
        message: 'Invalid response format',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      String? errorMessage;
      if (e.response?.data is Map<String, dynamic>) {
        errorMessage = e.response?.data['message']?.toString();
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage ?? e.error?.toString() ?? 'Failed to get morning plan tasks',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<Map<String, dynamic>>> startFromPlan({
    required int standupTaskId,
    int? projectId,
    int? taskId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.timesheetStartFromPlan,
        data: {
          'standup_task_id': standupTaskId,
          if (projectId != null) 'project_id': projectId,
          if (taskId != null) 'task_id': taskId,
        },
      );
      
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        final success = responseMap['success'] as bool? ?? true;
        
        if (success && responseMap['data'] != null) {
          return ApiResponse(
            success: true,
            data: responseMap['data'] as Map<String, dynamic>,
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            message: responseMap['message']?.toString() ?? 'Failed to start timer from plan',
            statusCode: response.statusCode,
          );
        }
      }
      
      return ApiResponse(
        success: false,
        message: 'Invalid response format',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      String? errorMessage;
      if (e.response?.data is Map<String, dynamic>) {
        errorMessage = e.response?.data['message']?.toString();
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage ?? e.error?.toString() ?? 'Failed to start timer from plan',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<Map<String, dynamic>>> getEntriesWithPlan({
    String? startDate,
    String? endDate,
    int? projectId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.timesheetEntriesWithPlan,
        queryParameters: {
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
          if (projectId != null) 'project_id': projectId,
        },
      );
      
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        final success = responseMap['success'] as bool? ?? true;
        
        if (success && responseMap['data'] != null) {
          return ApiResponse(
            success: true,
            data: responseMap['data'] as Map<String, dynamic>,
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            message: responseMap['message']?.toString() ?? 'Failed to get timesheet entries with plan',
            statusCode: response.statusCode,
          );
        }
      }
      
      return ApiResponse(
        success: false,
        message: 'Invalid response format',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      String? errorMessage;
      if (e.response?.data is Map<String, dynamic>) {
        errorMessage = e.response?.data['message']?.toString();
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage ?? e.error?.toString() ?? 'Failed to get timesheet entries with plan',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<void>> linkToPlanTask({
    required int timerId,
    required int standupTaskId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.timesheetLinkToPlanTask,
        data: {
          'timer_id': timerId,
          'standup_task_id': standupTaskId,
        },
      );
      
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        final success = responseMap['success'] as bool? ?? true;
        
        if (success) {
          return ApiResponse(
            success: true,
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            message: responseMap['message']?.toString() ?? 'Failed to link timesheet to plan task',
            statusCode: response.statusCode,
          );
        }
      }
      
      return ApiResponse(
        success: false,
        message: 'Invalid response format',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      String? errorMessage;
      if (e.response?.data is Map<String, dynamic>) {
        errorMessage = e.response?.data['message']?.toString();
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage ?? e.error?.toString() ?? 'Failed to link timesheet to plan task',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

