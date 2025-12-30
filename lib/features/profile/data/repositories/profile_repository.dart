import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/models/api_response.dart';

class ProfileRepository {
  final ApiClient _apiClient;
  
  ProfileRepository(this._apiClient);
  
  Future<ApiResponse<Map<String, dynamic>>> getProfile() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.profile);
      
      // Handle API response structure: {"success": true, "data": {...}}
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
            message: responseMap['message']?.toString() ?? 'Failed to get profile',
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
        message: errorMessage ?? e.error?.toString() ?? 'Failed to get profile',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<void>> updateProfile({
    String? phone,
    String? profileImage,
  }) async {
    try {
      await _apiClient.dio.put(
        ApiConstants.profileUpdate,
        data: {
          if (phone != null) 'phone': phone,
          if (profileImage != null) 'profile_image': profileImage,
        },
      );
      return ApiResponse(success: true);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Failed to update profile',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

