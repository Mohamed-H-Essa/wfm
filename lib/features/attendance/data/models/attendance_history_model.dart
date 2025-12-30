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
    return AttendanceHistoryModel(
      records: (json['records'] as List<dynamic>)
          .map((r) => AttendanceRecordModel.fromJson(r as Map<String, dynamic>))
          .toList(),
      summary: AttendanceSummaryModel.fromJson(json['summary'] as Map<String, dynamic>),
      pagination: PaginationModel.fromJson(json['pagination'] as Map<String, dynamic>),
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
    return AttendanceRecordModel(
      date: json['date'] as String,
      checkIn: json['check_in'] as String?,
      checkOut: json['check_out'] as String?,
      workHours: json['work_hours'] as String? ?? '00:00:00',
      status: json['status'] as String,
      isLate: json['is_late'] as bool? ?? false,
      isEarlyDeparture: json['is_early_departure'] as bool? ?? false,
      overtime: json['overtime'] as String? ?? '00:00:00',
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
    return AttendanceSummaryModel(
      totalDays: json['total_days'] as int? ?? 0,
      presentDays: json['present_days'] as int? ?? 0,
      absentDays: json['absent_days'] as int? ?? 0,
      lateDays: json['late_days'] as int? ?? 0,
      totalWorkHours: json['total_work_hours'] as String? ?? '00:00:00',
      averageWorkHours: json['average_work_hours'] as String? ?? '00:00:00',
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

