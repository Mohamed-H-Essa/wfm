import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/models/api_response.dart';

class NotificationRepository {
  final ApiClient _apiClient;
  
  NotificationRepository(this._apiClient);
  
  Future<ApiResponse<Map<String, dynamic>>> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.notifications,
        queryParameters: {
          'unread_only': unreadOnly.toString(),
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
        message: e.error?.toString() ?? 'Failed to get notifications',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  Future<ApiResponse<void>> markAsRead(int notificationId) async {
    try {
      await _apiClient.dio.post(
        ApiConstants.notificationsRead,
        data: {'notification_id': notificationId},
      );
      return ApiResponse(success: true);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.error?.toString() ?? 'Failed to mark notification as read',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

