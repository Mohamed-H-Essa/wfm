class TimesheetStatusModel {
  final bool isRunning;
  final TimesheetEntryModel? currentEntry;
  final TodayTotalModel todayTotal;
  
  TimesheetStatusModel({
    required this.isRunning,
    this.currentEntry,
    required this.todayTotal,
  });
  
  factory TimesheetStatusModel.fromJson(Map<String, dynamic> json) {
    return TimesheetStatusModel(
      isRunning: json['is_running'] as bool? ?? false,
      currentEntry: json['current_entry'] != null
          ? TimesheetEntryModel.fromJson(json['current_entry'] as Map<String, dynamic>)
          : null,
      todayTotal: TodayTotalModel.fromJson(json['today_total'] as Map<String, dynamic>),
    );
  }
}

class TimesheetEntryModel {
  final int id;
  final int? taskId;
  final String? taskName;
  final String? projectName;
  final String startedAt;
  final int durationSeconds;
  final String durationFormatted;
  
  TimesheetEntryModel({
    required this.id,
    this.taskId,
    this.taskName,
    this.projectName,
    required this.startedAt,
    required this.durationSeconds,
    required this.durationFormatted,
  });
  
  factory TimesheetEntryModel.fromJson(Map<String, dynamic> json) {
    return TimesheetEntryModel(
      id: json['id'] as int,
      taskId: json['task_id'] as int?,
      taskName: json['task_name'] as String?,
      projectName: json['project_name'] as String?,
      startedAt: json['started_at'] as String,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      durationFormatted: json['duration_formatted'] as String? ?? '00:00:00',
    );
  }
}

class TodayTotalModel {
  final int durationSeconds;
  final String durationFormatted;
  final int entriesCount;
  
  TodayTotalModel({
    required this.durationSeconds,
    required this.durationFormatted,
    required this.entriesCount,
  });
  
  factory TodayTotalModel.fromJson(Map<String, dynamic> json) {
    return TodayTotalModel(
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      durationFormatted: json['duration_formatted'] as String? ?? '00:00:00',
      entriesCount: json['entries_count'] as int? ?? 0,
    );
  }
}

