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
      return ApiResponse(
        success: true,
        data: response.data['data'] as List<dynamic>,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Failed to get excuse requests',
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
      return ApiResponse(
        success: true,
        data: response.data['data'] as Map<String, dynamic>,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Failed to submit excuse request',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

