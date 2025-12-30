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
    return NotificationListModel(
      notifications: (json['notifications'] as List<dynamic>)
          .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
          .toList(),
      unreadCount: json['unread_count'] as int? ?? 0,
      pagination: PaginationModel.fromJson(json['pagination'] as Map<String, dynamic>),
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
  
  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });
  
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] as String,
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
    return PaginationModel(
      currentPage: json['current_page'] as int? ?? 1,
      totalPages: json['total_pages'] as int? ?? 1,
      totalRecords: json['total_records'] as int? ?? 0,
    );
  }
}

