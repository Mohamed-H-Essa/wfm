class AttendanceHistoryModel {
  final List<AttendanceRecordModel> records;
  final AttendanceSummaryModel summary;
  final PaginationModel pagination;
  
  AttendanceHistoryModel({
    required this.records,
    required this.summary,
    required this.pagination,
  });
  
  factory AttendanceHistoryModel.fromJson(Map<String, dynamic> json) {
    // Handle records list - may be null or empty
    List<AttendanceRecordModel> recordsList = [];
    if (json['records'] != null && json['records'] is List) {
      recordsList = (json['records'] as List<dynamic>)
          .map((r) => AttendanceRecordModel.fromJson(r as Map<String, dynamic>))
          .toList();
    }
    
    // Handle summary - may be null
    AttendanceSummaryModel? summaryData;
    if (json['summary'] != null && json['summary'] is Map) {
      summaryData = AttendanceSummaryModel.fromJson(json['summary'] as Map<String, dynamic>);
    } else {
      // Create default summary if missing
      summaryData = AttendanceSummaryModel(
        totalDays: 0,
        presentDays: 0,
        absentDays: 0,
        lateDays: 0,
        totalWorkHours: '00:00:00',
        averageWorkHours: '00:00:00',
      );
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
        totalRecords: recordsList.length,
      );
    }
    
    return AttendanceHistoryModel(
      records: recordsList,
      summary: summaryData,
      pagination: paginationData,
    );
  }
}

class AttendanceRecordModel {
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String workHours;
  final String status;
  final bool isLate;
  final bool isEarlyDeparture;
  final String overtime;
  
  AttendanceRecordModel({
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.workHours,
    required this.status,
    required this.isLate,
    required this.isEarlyDeparture,
    required this.overtime,
  });
  
  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
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
    
    return AttendanceRecordModel(
      date: json['date']?.toString() ?? '',
      checkIn: json['check_in']?.toString(),
      checkOut: json['check_out']?.toString(),
      workHours: json['work_hours']?.toString() ?? '00:00:00',
      status: json['status']?.toString() ?? '',
      isLate: parseBool(json['is_late'], false),
      isEarlyDeparture: parseBool(json['is_early_departure'], false),
      overtime: json['overtime']?.toString() ?? '00:00:00',
    );
  }
}

class AttendanceSummaryModel {
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final String totalWorkHours;
  final String averageWorkHours;
  
  AttendanceSummaryModel({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.totalWorkHours,
    required this.averageWorkHours,
  });
  
  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    // Handle int values that may come as String
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    return AttendanceSummaryModel(
      totalDays: parseInt(json['total_days']),
      presentDays: parseInt(json['present_days']),
      absentDays: parseInt(json['absent_days']),
      lateDays: parseInt(json['late_days']),
      totalWorkHours: json['total_work_hours']?.toString() ?? '00:00:00',
      averageWorkHours: json['average_work_hours']?.toString() ?? '00:00:00',
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

