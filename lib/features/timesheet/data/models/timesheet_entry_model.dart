class TimesheetEntriesModel {
  final List<TimesheetEntryItemModel> entries;
  final TimesheetSummaryModel summary;
  
  TimesheetEntriesModel({
    required this.entries,
    required this.summary,
  });
  
  factory TimesheetEntriesModel.fromJson(Map<String, dynamic> json) {
    return TimesheetEntriesModel(
      entries: (json['entries'] as List<dynamic>)
          .map((e) => TimesheetEntryItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: TimesheetSummaryModel.fromJson(json['summary'] as Map<String, dynamic>),
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
    return TimesheetEntryItemModel(
      id: json['id'] as int,
      date: json['date'] as String,
      taskId: json['task_id'] as int?,
      taskName: json['task_name'] as String?,
      projectId: json['project_id'] as int?,
      projectName: json['project_name'] as String?,
      startedAt: json['started_at'] as String,
      endedAt: json['ended_at'] as String?,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      durationFormatted: json['duration_formatted'] as String? ?? '00:00:00',
      description: json['description'] as String?,
      isBillable: json['is_billable'] as bool? ?? true,
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
    return TimesheetSummaryModel(
      totalDurationSeconds: json['total_duration_seconds'] as int? ?? 0,
      totalDurationFormatted: json['total_duration_formatted'] as String? ?? '00:00:00',
      billableDuration: json['billable_duration'] as String? ?? '00:00:00',
      nonBillableDuration: json['non_billable_duration'] as String? ?? '00:00:00',
    );
  }
}

