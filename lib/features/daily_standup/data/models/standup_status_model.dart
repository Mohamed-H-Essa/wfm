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
    // Helper to parse boolean from dynamic (handles bool, String "1"/"0", int)
    bool parseBool(dynamic value, bool defaultValue) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) {
        // API returns "1" for true, "0" for false
        return value == '1' || value.toLowerCase() == 'true' || value.toLowerCase() == 'yes';
      }
      if (value is int) return value != 0;
      return defaultValue;
    }
    
    return StandupStatusModel(
      date: json['date']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      morningSubmitted: parseBool(json['morning_submitted'], false),
      morningSubmittedAt: json['morning_submitted_at']?.toString(),
      eveningSubmitted: parseBool(json['evening_submitted'], false),
      tasks: StandupTasksModel.fromJson(json['tasks'] as Map<String, dynamic>),
      workType: json['work_type']?.toString() ?? 'OFFICE',
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
    // Handle int values that may come as String
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    return StandupTasksModel(
      total: parseInt(json['total']),
      completed: parseInt(json['completed']),
      inProgress: parseInt(json['in_progress']),
      pending: parseInt(json['pending']),
    );
  }
}

