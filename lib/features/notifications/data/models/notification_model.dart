class NotificationListModel {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final PaginationModel pagination;
  
  NotificationListModel({
    required this.notifications,
    required this.unreadCount,
    required this.pagination,
  });
  
  factory NotificationListModel.fromJson(Map<String, dynamic> json) {
    // Handle int values that may come as String
    int parseInt(dynamic value, int defaultValue) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }
    
    // Handle notifications list - may be null or empty
    List<NotificationModel> notificationsList = [];
    if (json['notifications'] != null && json['notifications'] is List) {
      notificationsList = (json['notifications'] as List<dynamic>)
          .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
          .toList();
    }
    
    // Handle pagination - may be null
    PaginationModel? paginationData;
    if (json['pagination'] != null && json['pagination'] is Map) {
      paginationData = PaginationModel.fromJson(json['pagination'] as Map<String, dynamic>);
    } else {
      // Create default pagination if missing
      paginationData = PaginationModel(
        currentPage: 1,
        totalPages: 1,
        totalRecords: notificationsList.length,
      );
    }
    
    return NotificationListModel(
      notifications: notificationsList,
      unreadCount: parseInt(json['unread_count'], 0),
      pagination: paginationData,
    );
  }
}

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String createdAt;
  final Map<String, dynamic>? data; // API includes data field with link
  
  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.data,
  });
  
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Handle int values that may come as String
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    // Helper to parse boolean from dynamic (handles bool, String, int)
    bool parseBool(dynamic value, bool defaultValue) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) {
        final lower = value.toLowerCase();
        return lower == 'true' || lower == '1' || lower == 'yes';
      }
      if (value is int) return value != 0;
      return defaultValue;
    }
    
    // Handle data field - may be null or Map
    Map<String, dynamic>? dataValue;
    if (json['data'] != null && json['data'] is Map) {
      dataValue = json['data'] as Map<String, dynamic>;
    }
    
    return NotificationModel(
      id: parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'GENERAL',
      isRead: parseBool(json['is_read'], false),
      createdAt: json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      data: dataValue,
    );
  }
}

class PaginationModel {
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  
  PaginationModel({
    required this.currentPage,
    required this.totalPages,
    required this.totalRecords,
  });
  
  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    // Handle int values that may come as String
    int parseInt(dynamic value, int defaultValue) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }
    
    return PaginationModel(
      currentPage: parseInt(json['current_page'], 1),
      totalPages: parseInt(json['total_pages'], 1),
      totalRecords: parseInt(json['total_records'], 0),
    );
  }
}

