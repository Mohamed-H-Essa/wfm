import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/models/api_response.dart';
import '../models/user_model.dart';
import '../models/login_response_model.dart';

class AuthRepository {
  final ApiClient _apiClient;
  
  AuthRepository(this._apiClient);
  
  Future<ApiResponse<LoginResponseModel>> login({
    required String email,
    required String password,
    String? deviceId,
    String? deviceName,
    String? fcmToken,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
          if (deviceId != null) 'device_id': deviceId,
          if (deviceName != null) 'device_name': deviceName,
          if (fcmToken != null) 'fcm_token': fcmToken,
        },
      );
      
      final loginData = LoginResponseModel.fromJson(response.data['data']);
      
      // Store tokens
      await _apiClient.setAccessToken(loginData.accessToken);
      await _apiClient.setRefreshToken(loginData.refreshToken);
      
      return ApiResponse(
        success: true,
        data: loginData,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Login failed',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<void>> logout({String? deviceId}) async {
    try {
      await _apiClient.dio.post(
        ApiConstants.logout,
        data: {'device_id': deviceId},
      );
      
      await _apiClient.clearTokens();
      
      return ApiResponse(success: true);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Logout failed',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<String>> refreshToken(String refreshToken) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.refresh,
        data: {'refresh_token': refreshToken},
      );
      
      final newToken = response.data['data']['access_token'] as String;
      await _apiClient.setAccessToken(newToken);
      
      return ApiResponse(
        success: true,
        data: newToken,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Token refresh failed',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<void>> updateBiometricSettings({
    required bool enabled,
    String? biometricToken,
    String? deviceId,
  }) async {
    try {
      await _apiClient.dio.post(
        ApiConstants.biometric,
        data: {
          'enabled': enabled,
          if (biometricToken != null) 'biometric_token': biometricToken,
          if (deviceId != null) 'device_id': deviceId,
        },
      );
      return ApiResponse(success: true);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Failed to update biometric settings',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

