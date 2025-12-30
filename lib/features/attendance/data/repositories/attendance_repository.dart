import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/models/api_response.dart';
import '../models/attendance_status_model.dart';

class AttendanceRepository {
  final ApiClient _apiClient;
  
  AttendanceRepository(this._apiClient);
  
  Future<ApiResponse<AttendanceStatusModel>> getStatus() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.attendanceStatus);
      return ApiResponse(
        success: true,
        data: AttendanceStatusModel.fromJson(response.data['data']),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Failed to get attendance status',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<Map<String, dynamic>>> checkIn({
    double? latitude,
    double? longitude,
    double? accuracy,
    String method = 'GPS',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.checkIn,
        data: {
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (accuracy != null) 'accuracy': accuracy,
          'method': method,
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
        message: e.error?.toString() ?? 'Check-in failed',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<Map<String, dynamic>>> checkOut({
    double? latitude,
    double? longitude,
    double? accuracy,
    String method = 'GPS',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.checkOut,
        data: {
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (accuracy != null) 'accuracy': accuracy,
          'method': method,
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
        message: e.error?.toString() ?? 'Check-out failed',
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
        ApiConstants.attendanceHistory,
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
        message: e.error?.toString() ?? 'Failed to get attendance history',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<List<dynamic>>> getForgotRequests() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.forgotRequests);
      return ApiResponse(
        success: true,
        data: response.data['data'] as List<dynamic>,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Failed to get forgot requests',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<List<dynamic>>> getOfficeLocations() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.officeLocations);
      return ApiResponse(
        success: true,
        data: response.data['data'] as List<dynamic>,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Failed to get office locations',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<Map<String, dynamic>>> submitForgotCheckin({
    required String date,
    required String type,
    required String reason,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.forgotCheckin,
        data: {
          'date': date,
          'type': type,
          'reason': reason,
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
        message: e.error?.toString() ?? 'Failed to submit forgot check-in request',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

