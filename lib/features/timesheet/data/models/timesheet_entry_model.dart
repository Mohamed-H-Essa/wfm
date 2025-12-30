class TimesheetEntriesModel {
  final List<TimesheetEntryItemModel> entries;
  final TimesheetSummaryModel summary;
  
  TimesheetEntriesModel({
    required this.entries,
    required this.summary,
  });
  
  factory TimesheetEntriesModel.fromJson(Map<String, dynamic> json) {
    // Handle entries list - may be null or empty
    List<TimesheetEntryItemModel> entriesList = [];
    if (json['entries'] != null && json['entries'] is List) {
      entriesList = (json['entries'] as List<dynamic>)
          .map((e) => TimesheetEntryItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    
    // Handle summary - may be null
    TimesheetSummaryModel? summaryData;
    if (json['summary'] != null && json['summary'] is Map) {
      summaryData = TimesheetSummaryModel.fromJson(json['summary'] as Map<String, dynamic>);
    } else {
      // Create default summary if missing
      summaryData = TimesheetSummaryModel(
        totalDurationSeconds: 0,
        totalDurationFormatted: '00:00:00',
        billableDuration: '00:00:00',
        nonBillableDuration: '00:00:00',
      );
    }
    
    return TimesheetEntriesModel(
      entries: entriesList,
      summary: summaryData,
    );
  }
}

class TimesheetEntryItemModel {
  final int id;
  final String date;
  final int? taskId;
  final String? taskName;
  final int? projectId;
  final String? projectName;
  final String startedAt;
  final String? endedAt;
  final int durationSeconds;
  final String durationFormatted;
  final String? description;
  final bool isBillable;
  
  TimesheetEntryItemModel({
    required this.id,
    required this.date,
    this.taskId,
    this.taskName,
    this.projectId,
    this.projectName,
    required this.startedAt,
    this.endedAt,
    required this.durationSeconds,
    required this.durationFormatted,
    this.description,
    required this.isBillable,
  });
  
  factory TimesheetEntryItemModel.fromJson(Map<String, dynamic> json) {
    // Handle int values that may come as String
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    int? parseIntNullable(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }
    
    // Helper to parse boolean from dynamic
    bool _parseBool(dynamic value, bool defaultValue) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) {
        return value == '1' || value.toLowerCase() == 'true' || value.toLowerCase() == 'yes';
      }
      if (value is int) return value != 0;
      return defaultValue;
    }
    
    return TimesheetEntryItemModel(
      id: parseInt(json['id']),
      date: json['date']?.toString() ?? '',
      taskId: parseIntNullable(json['task_id']),
      taskName: json['task_name']?.toString(),
      projectId: parseIntNullable(json['project_id']),
      projectName: json['project_name']?.toString(),
      startedAt: json['started_at']?.toString() ?? '',
      endedAt: json['ended_at']?.toString(),
      durationSeconds: parseInt(json['duration_seconds']),
      durationFormatted: json['duration_formatted']?.toString() ?? '00:00:00',
      description: json['description']?.toString(),
      isBillable: _parseBool(json['is_billable'], false),
    );
  }
}

class TimesheetSummaryModel {
  final int totalDurationSeconds;
  final String totalDurationFormatted;
  final String billableDuration;
  final String nonBillableDuration;
  
  TimesheetSummaryModel({
    required this.totalDurationSeconds,
    required this.totalDurationFormatted,
    required this.billableDuration,
    required this.nonBillableDuration,
  });
  
  factory TimesheetSummaryModel.fromJson(Map<String, dynamic> json) {
    // Handle int values that may come as String
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    return TimesheetSummaryModel(
      totalDurationSeconds: parseInt(json['total_duration_seconds']),
      totalDurationFormatted: json['total_duration_formatted']?.toString() ?? '00:00:00',
      billableDuration: json['billable_duration']?.toString() ?? '00:00:00',
      nonBillableDuration: json['non_billable_duration']?.toString() ?? '00:00:00',
    );
  }
}

