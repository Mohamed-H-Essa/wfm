import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/models/api_response.dart';
import '../models/project_model.dart';
import '../models/standup_status_model.dart';

class StandupRepository {
  final ApiClient _apiClient;
  
  StandupRepository(this._apiClient);
  
  Future<ApiResponse<List<Project>>> getProjects() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.standupProjects);
      
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        final success = responseMap['success'] as bool? ?? true;
        
        if (success && responseMap['data'] != null) {
          final List<dynamic> projectsJson = responseMap['data'] as List<dynamic>;
          final projects = projectsJson.map((json) => Project.fromJson(json as Map<String, dynamic>)).toList();
          return ApiResponse(
            success: true,
            data: projects,
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            message: responseMap['message']?.toString() ?? 'Failed to get projects',
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
        message: errorMessage ?? e.error?.toString() ?? 'Failed to get projects',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<Map<String, dynamic>>> submitMorning({
    required String? todayGoals,
    required String workType,
    required List<Map<String, dynamic>> tasks,
    bool? hasCarryoverBlockers,
    String? carryoverNotes,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.standupMorning,
        data: {
          if (todayGoals != null) 'today_goals': todayGoals,
          'work_type': workType,
          'tasks': tasks,
          if (hasCarryoverBlockers != null) 'has_carryover_blockers': hasCarryoverBlockers,
          if (carryoverNotes != null) 'carryover_notes': carryoverNotes,
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
            message: responseMap['message']?.toString() ?? 'Failed to submit morning plan',
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
        message: errorMessage ?? e.error?.toString() ?? 'Failed to submit morning plan',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<Map<String, dynamic>>> getToday() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.standupToday);
      
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
            message: responseMap['message']?.toString() ?? 'Failed to get today standup',
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
        message: errorMessage ?? e.error?.toString() ?? 'Failed to get today standup',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<Map<String, dynamic>>> getById(int standupId) async {
    try {
      // Use standup view endpoint if available, otherwise use today endpoint
      final response = await _apiClient.dio.get('${ApiConstants.standupView}/$standupId');
      
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
            message: responseMap['message']?.toString() ?? 'Failed to get standup',
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
      // If view endpoint fails, try using today endpoint (for current day standups)
      if (e.response?.statusCode == 404) {
        try {
          final todayResponse = await _apiClient.dio.get(ApiConstants.standupToday);
          if (todayResponse.data is Map<String, dynamic>) {
            final todayResponseMap = todayResponse.data as Map<String, dynamic>;
            final todaySuccess = todayResponseMap['success'] as bool? ?? true;
            
            if (todaySuccess && todayResponseMap['data'] != null) {
              final todayData = todayResponseMap['data'] as Map<String, dynamic>;
              // Check if the id matches
              final todayId = todayData['id'];
              final todayIdInt = todayId is int ? todayId : (todayId is String ? int.tryParse(todayId) : null);
              if (todayIdInt == standupId) {
                return ApiResponse(
                  success: true,
                  data: todayData,
                  statusCode: todayResponse.statusCode,
                );
              }
            }
          }
        } catch (_) {
          // Fall through to error
        }
      }
      
      String? errorMessage;
      if (e.response?.data is Map<String, dynamic>) {
        errorMessage = e.response?.data['message']?.toString();
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage ?? e.error?.toString() ?? 'Failed to get standup',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<StandupStatusModel>> getStatus() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.standupStatus);
      
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        final success = responseMap['success'] as bool? ?? true;
        
        if (success && responseMap['data'] != null) {
          return ApiResponse(
            success: true,
            data: StandupStatusModel.fromJson(responseMap['data'] as Map<String, dynamic>),
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            message: responseMap['message']?.toString() ?? 'Failed to get standup status',
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
        message: errorMessage ?? e.error?.toString() ?? 'Failed to get standup status',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<Map<String, dynamic>>> submitEvening({
    required String workSummary,
    int? productivityRating,
    String? blockerDescription,
    String? blockerPriority,
    List<Map<String, dynamic>>? unplannedTasks,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.standupEvening,
        data: {
          'work_summary': workSummary,
          if (productivityRating != null) 'productivity_rating': productivityRating,
          if (blockerDescription != null) 'blocker_description': blockerDescription,
          if (blockerPriority != null) 'blocker_priority': blockerPriority,
          if (unplannedTasks != null) 'unplanned_tasks': unplannedTasks,
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
            message: responseMap['message']?.toString() ?? 'Failed to submit evening summary',
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
        message: errorMessage ?? e.error?.toString() ?? 'Failed to submit evening summary',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<Map<String, dynamic>>> getHistory({
    int? month,
    int? year,
    int page = 1,
    int perPage = 31,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.standupHistory,
        queryParameters: {
          if (month != null) 'month': month,
          if (year != null) 'year': year,
          'page': page,
          'per_page': perPage,
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
            message: responseMap['message']?.toString() ?? 'Failed to get standup history',
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
        message: errorMessage ?? e.error?.toString() ?? 'Failed to get standup history',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

