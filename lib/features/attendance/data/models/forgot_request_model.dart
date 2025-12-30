class ForgotRequestsListModel {
  final List<ForgotRequestModel> requests;
  final PaginationModel pagination;
  
  ForgotRequestsListModel({
    required this.requests,
    required this.pagination,
  });
  
  factory ForgotRequestsListModel.fromJson(Map<String, dynamic> json) {
    List<ForgotRequestModel> requestsList = [];
    if (json['requests'] != null && json['requests'] is List) {
      requestsList = (json['requests'] as List<dynamic>)
          .map((r) => ForgotRequestModel.fromJson(r as Map<String, dynamic>))
          .toList();
    }
    
    PaginationModel? paginationData;
    if (json['pagination'] != null && json['pagination'] is Map) {
      paginationData = PaginationModel.fromJson(json['pagination'] as Map<String, dynamic>);
    } else {
      paginationData = PaginationModel(
        currentPage: 1,
        totalPages: 1,
        totalRecords: requestsList.length,
      );
    }
    
    return ForgotRequestsListModel(
      requests: requestsList,
      pagination: paginationData,
    );
  }
}

class ForgotRequestModel {
  final int id;
  final String date;
  final String type; // CHECK_IN, CHECK_OUT, BOTH
  final String? requestedCheckInTime;
  final String? requestedCheckOutTime;
  final String reason;
  final String status; // PENDING, APPROVED, REJECTED
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  ForgotRequestModel({
    required this.id,
    required this.date,
    required this.type,
    this.requestedCheckInTime,
    this.requestedCheckOutTime,
    required this.reason,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
  });
  
  factory ForgotRequestModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }
    
    // Handle requested_time field (may be check_in_time or check_out_time depending on type)
    String? requestedCheckInTime;
    String? requestedCheckOutTime;
    if (json['requested_time'] != null) {
      final timeStr = json['requested_time'].toString();
      if (json['type'] == 'CHECK_IN' || json['type'] == 'BOTH') {
        requestedCheckInTime = timeStr;
      }
      if (json['type'] == 'CHECK_OUT' || json['type'] == 'BOTH') {
        requestedCheckOutTime = timeStr;
      }
    }
    // Also check for specific fields
    if (json['requested_check_in_time'] != null) {
      requestedCheckInTime = json['requested_check_in_time'].toString();
    }
    if (json['requested_check_out_time'] != null) {
      requestedCheckOutTime = json['requested_check_out_time'].toString();
    }
    
    return ForgotRequestModel(
      id: parseInt(json['id']),
      date: json['date']?.toString() ?? '',
      type: json['type']?.toString() ?? 'CHECK_IN',
      requestedCheckInTime: requestedCheckInTime,
      requestedCheckOutTime: requestedCheckOutTime,
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      approvedBy: json['approved_by']?.toString(),
      approvedAt: parseDateTime(json['approved_at']),
      rejectionReason: json['rejection_reason']?.toString(),
      createdAt: parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }
}

// PaginationModel is defined in notification_model.dart, we'll define it here to avoid circular dependency
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

