import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/models/api_response.dart';

class SettingsRepository {
  final ApiClient _apiClient;
  
  SettingsRepository(this._apiClient);
  
  Future<ApiResponse<Map<String, dynamic>>> getAppSettings() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.settingsApp);
      return ApiResponse(
        success: true,
        data: response.data['data'] as Map<String, dynamic>,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Failed to get settings',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  // Note: User preferences (push notifications, location services) are stored locally
  // Only biometric settings are synced with backend via the biometric endpoint
}

