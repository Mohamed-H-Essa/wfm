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
      final List<dynamic> projectsJson = response.data['data'] as List<dynamic>;
      final projects = projectsJson.map((json) => Project.fromJson(json as Map<String, dynamic>)).toList();
      return ApiResponse(
        success: true,
        data: projects,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Failed to get projects',
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
      return ApiResponse(
        success: true,
        data: response.data['data'] as Map<String, dynamic>,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Failed to submit morning plan',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<Map<String, dynamic>>> getToday() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.standupToday);
      return ApiResponse(
        success: true,
        data: response.data['data'] as Map<String, dynamic>,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Failed to get today standup',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<StandupStatusModel>> getStatus() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.standupStatus);
      return ApiResponse(
        success: true,
        data: StandupStatusModel.fromJson(response.data['data']),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Failed to get standup status',
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
      return ApiResponse(
        success: true,
        data: response.data['data'] as Map<String, dynamic>,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Failed to submit evening summary',
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
      return ApiResponse(
        success: true,
        data: response.data['data'] as Map<String, dynamic>,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Failed to get standup history',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

