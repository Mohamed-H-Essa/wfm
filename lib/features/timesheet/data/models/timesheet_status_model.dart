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
    // Handle id as either int or String
    int entryId;
    if (json['id'] is int) {
      entryId = json['id'] as int;
    } else if (json['id'] is String) {
      entryId = int.tryParse(json['id'] as String) ?? 0;
    } else {
      entryId = 0;
    }
    
    // Handle task_id as either int or String
    int? taskIdValue;
    if (json['task_id'] != null) {
      if (json['task_id'] is int) {
        taskIdValue = json['task_id'] as int;
      } else if (json['task_id'] is String) {
        taskIdValue = int.tryParse(json['task_id'] as String);
      }
    }
    
    // Handle duration_seconds as either int or String
    int durationSecondsValue = 0;
    if (json['duration_seconds'] != null) {
      if (json['duration_seconds'] is int) {
        durationSecondsValue = json['duration_seconds'] as int;
      } else if (json['duration_seconds'] is String) {
        durationSecondsValue = int.tryParse(json['duration_seconds'] as String) ?? 0;
      }
    }
    
    return TimesheetEntryModel(
      id: entryId,
      taskId: taskIdValue,
      taskName: json['task_name']?.toString(),
      projectName: json['project_name']?.toString(),
      startedAt: json['started_at']?.toString() ?? '',
      durationSeconds: durationSecondsValue,
      durationFormatted: json['duration_formatted']?.toString() ?? '00:00:00',
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

