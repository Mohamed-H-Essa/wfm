class StandupStatusModel {
  final String date;
  final String state;
  final bool morningSubmitted;
  final String? morningSubmittedAt;
  final bool eveningSubmitted;
  final StandupTasksModel tasks;
  final String workType;
  
  StandupStatusModel({
    required this.date,
    required this.state,
    required this.morningSubmitted,
    this.morningSubmittedAt,
    required this.eveningSubmitted,
    required this.tasks,
    required this.workType,
  });
  
  factory StandupStatusModel.fromJson(Map<String, dynamic> json) {
    return StandupStatusModel(
      date: json['date'] as String,
      state: json['state'] as String,
      morningSubmitted: json['morning_submitted'] as bool? ?? false,
      morningSubmittedAt: json['morning_submitted_at'] as String?,
      eveningSubmitted: json['evening_submitted'] as bool? ?? false,
      tasks: StandupTasksModel.fromJson(json['tasks'] as Map<String, dynamic>),
      workType: json['work_type'] as String? ?? 'OFFICE',
    );
  }
}

class StandupTasksModel {
  final int total;
  final int completed;
  final int inProgress;
  final int pending;
  
  StandupTasksModel({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.pending,
  });
  
  factory StandupTasksModel.fromJson(Map<String, dynamic> json) {
    return StandupTasksModel(
      total: json['total'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      inProgress: json['in_progress'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
    );
  }
}

