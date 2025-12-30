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
      return ApiResponse(
        success: true,
        data: response.data['data'] as Map<String, dynamic>,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Failed to get profile',
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

