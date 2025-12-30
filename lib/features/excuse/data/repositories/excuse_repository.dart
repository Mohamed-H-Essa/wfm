import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/models/api_response.dart';

class ExcuseRepository {
  final ApiClient _apiClient;
  
  ExcuseRepository(this._apiClient);
  
  Future<ApiResponse<List<dynamic>>> getRequests() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.excuseRequests);
      
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
            message: responseMap['message']?.toString() ?? 'Failed to get excuse requests',
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
        message: errorMessage ?? e.error?.toString() ?? 'Failed to get excuse requests',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<Map<String, dynamic>>> submitRequest({
    required String date,
    required String type,
    required String reason,
    String? fromTime,
    String? toTime,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.excuseRequest,
        data: {
          'date': date,
          'type': type,
          'reason': reason,
          if (fromTime != null) 'from_time': fromTime,
          if (toTime != null) 'to_time': toTime,
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
            message: responseMap['message']?.toString() ?? 'Failed to submit excuse request',
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
        message: errorMessage ?? e.error?.toString() ?? 'Failed to submit excuse request',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

