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
            message: responseMap['message']?.toString() ?? 'Failed to get notifications',
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
        message: errorMessage ?? e.error?.toString() ?? 'Failed to get notifications',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  /// Mark notification(s) as read
  /// Supports both single notification ID or multiple notification IDs
  /// - [notificationId]: Single notification ID (optional if [notificationIds] is provided)
  /// - [notificationIds]: List of notification IDs (optional if [notificationId] is provided)
  Future<ApiResponse<void>> markAsRead({
    int? notificationId,
    List<int>? notificationIds,
  }) async {
    try {
      // Validate that at least one parameter is provided
      if (notificationId == null && (notificationIds == null || notificationIds.isEmpty)) {
        return ApiResponse(
          success: false,
          message: 'Either notificationId or notificationIds must be provided',
        );
      }
      
      // Prepare request data
      Map<String, dynamic> requestData;
      if (notificationIds != null && notificationIds.length > 1) {
        // Multiple notifications - use notification_ids array
        requestData = {'notification_ids': notificationIds};
      } else if (notificationIds != null && notificationIds.length == 1) {
        // Single notification in list - use notification_id
        requestData = {'notification_id': notificationIds.first};
      } else {
        // Single notification ID
        requestData = {'notification_id': notificationId!};
      }
      
      final response = await _apiClient.dio.post(
        ApiConstants.notificationsRead,
        data: requestData,
      );
      
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        final success = responseMap['success'] as bool? ?? true;
        
        if (success) {
          return ApiResponse(success: true);
        } else {
          return ApiResponse(
            success: false,
            message: responseMap['message']?.toString() ?? 'Failed to mark notification as read',
            statusCode: response.statusCode,
          );
        }
      }
      
      return ApiResponse(success: true);
    } on DioException catch (e) {
      String? errorMessage;
      if (e.response?.data is Map<String, dynamic>) {
        errorMessage = e.response?.data['message']?.toString();
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage ?? e.error?.toString() ?? 'Failed to mark notification as read',
        statusCode: e.response?.statusCode,
      );
    }
  }
  
  /// Mark a single notification as read (convenience method)
  Future<ApiResponse<void>> markAsReadSingle(int notificationId) async {
    return markAsRead(notificationId: notificationId);
  }
  
  /// Mark multiple notifications as read (convenience method)
  Future<ApiResponse<void>> markAsReadMultiple(List<int> notificationIds) async {
    return markAsRead(notificationIds: notificationIds);
  }
}

