import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/models/api_response.dart';
import '../models/attendance_status_model.dart';
import '../models/checkout_status_model.dart';
import '../models/forgot_request_model.dart';
import '../models/forgot_checkin_settings_model.dart';

class AttendanceRepository {
  final ApiClient _apiClient;
  
  AttendanceRepository(this._apiClient);
  
  Future<ApiResponse<AttendanceStatusModel>> getStatus() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.attendanceStatus);
      
      // API returns {"success": true, "data": {...}} or {"success": false, "message": "..."}
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        final success = responseMap['success'] as bool? ?? true;
        
        if (success && responseMap['data'] != null) {
          return ApiResponse(
            success: true,
            data: AttendanceStatusModel.fromJson(responseMap['data'] as Map<String, dynamic>),
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            message: responseMap['message']?.toString() ?? 'Failed to get attendance status',
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
        message: errorMessage ?? e.error?.toString() ?? 'Failed to get attendance status',
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
            message: responseMap['message']?.toString() ?? 'Check-in failed',
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
        message: errorMessage ?? e.error?.toString() ?? 'Check-in failed',
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
            message: responseMap['message']?.toString() ?? 'Check-out failed',
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
        message: errorMessage ?? e.error?.toString() ?? 'Check-out failed',
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
            message: responseMap['message']?.toString() ?? 'Failed to get attendance history',
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
        message: errorMessage ?? e.error?.toString() ?? 'Failed to get attendance history',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<List<dynamic>>> getOfficeLocations() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.officeLocations);
      
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        final success = responseMap['success'] as bool? ?? true;
        
        if (success && responseMap['data'] != null) {
          return ApiResponse(
            success: true,
            data: responseMap['data'] as List<dynamic>,
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            message: responseMap['message']?.toString() ?? 'Failed to get office locations',
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
        message: errorMessage ?? e.error?.toString() ?? 'Failed to get office locations',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<Map<String, dynamic>>> submitForgotCheckin({
    required String date,
    required String type,
    required String reason,
    String? requestedCheckInTime,
    String? requestedCheckOutTime,
    String? jiraProof,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.forgotCheckin,
        data: {
          'date': date,
          'type': type,
          'reason': reason,
          if (requestedCheckInTime != null) 'requested_check_in_time': requestedCheckInTime,
          if (requestedCheckOutTime != null) 'requested_check_out_time': requestedCheckOutTime,
          if (jiraProof != null && jiraProof.isNotEmpty) 'jira_proof': jiraProof,
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
            message: responseMap['message']?.toString() ?? 'Failed to submit forgot check-in request',
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
        message: errorMessage ?? e.error?.toString() ?? 'Failed to submit forgot check-in request',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<CheckoutStatusModel>> getCheckoutStatus() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.checkoutStatus);
      
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        final success = responseMap['success'] as bool? ?? true;
        
        if (success && responseMap['data'] != null) {
          return ApiResponse(
            success: true,
            data: CheckoutStatusModel.fromJson(responseMap['data'] as Map<String, dynamic>),
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            message: responseMap['message']?.toString() ?? 'Failed to get checkout status',
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
        message: errorMessage ?? e.error?.toString() ?? 'Failed to get checkout status',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<ForgotRequestsListModel>> getForgotRequests({
    String? status,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.forgotRequests,
        queryParameters: {
          if (status != null) 'status': status,
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
            data: ForgotRequestsListModel.fromJson(responseMap['data'] as Map<String, dynamic>),
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            message: responseMap['message']?.toString() ?? 'Failed to get forgot requests',
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
        message: errorMessage ?? e.error?.toString() ?? 'Failed to get forgot requests',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<ForgotRequestModel>> getForgotRequest(int requestId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.forgotRequest}/$requestId');
      
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        final success = responseMap['success'] as bool? ?? true;
        
        if (success && responseMap['data'] != null) {
          return ApiResponse(
            success: true,
            data: ForgotRequestModel.fromJson(responseMap['data'] as Map<String, dynamic>),
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            message: responseMap['message']?.toString() ?? 'Failed to get forgot request',
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
        message: errorMessage ?? e.error?.toString() ?? 'Failed to get forgot request',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<void>> cancelForgotRequest(int requestId) async {
    try {
      final response = await _apiClient.dio.delete('${ApiConstants.forgotRequest}/$requestId');
      
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
            message: responseMap['message']?.toString() ?? 'Failed to cancel forgot request',
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
        message: errorMessage ?? e.error?.toString() ?? 'Failed to cancel forgot request',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  /// Get forgot check-in/out settings from the system
  /// Returns system settings, user status, restrictions, and help text
  Future<ApiResponse<ForgotCheckinSettingsModel>> getForgotCheckinSettings() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.forgotCheckinSettings);
      
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        final success = responseMap['success'] as bool? ?? true;
        
        if (success && responseMap['data'] != null) {
          return ApiResponse(
            success: true,
            data: ForgotCheckinSettingsModel.fromJson(responseMap['data'] as Map<String, dynamic>),
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            message: responseMap['message']?.toString() ?? 'Failed to get forgot check-in settings',
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
        message: errorMessage ?? e.error?.toString() ?? 'Failed to get forgot check-in settings',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

