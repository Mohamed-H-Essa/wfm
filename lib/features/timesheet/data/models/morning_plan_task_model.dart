class MorningPlanTasksModel {
  final List<MorningPlanTaskModel> tasks;
  final int? standupId;
  final String workType;
  final bool isWfhDay;
  final int? wfhScheduleId;
  
  MorningPlanTasksModel({
    required this.tasks,
    this.standupId,
    required this.workType,
    required this.isWfhDay,
    this.wfhScheduleId,
  });
  
  factory MorningPlanTasksModel.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value, bool defaultValue) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) {
        return value == '1' || value.toLowerCase() == 'true' || value.toLowerCase() == 'yes';
      }
      if (value is int) return value != 0;
      return defaultValue;
    }
    
    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }
    
    List<MorningPlanTaskModel> tasksList = [];
    if (json['tasks'] != null && json['tasks'] is List) {
      tasksList = (json['tasks'] as List<dynamic>)
          .map((t) => MorningPlanTaskModel.fromJson(t as Map<String, dynamic>))
          .toList();
    }
    
    return MorningPlanTasksModel(
      tasks: tasksList,
      standupId: parseNullableInt(json['standup_id']),
      workType: json['work_type']?.toString() ?? 'OFFICE',
      isWfhDay: parseBool(json['is_wfh_day'], false),
      wfhScheduleId: parseNullableInt(json['wfh_schedule_id']),
    );
  }
}

class MorningPlanTaskModel {
  final int id;
  final String title;
  final double? estimatedHours;
  final int? projectId;
  final String? projectName;
  final String? category;
  final String priority;
  final String status;
  
  MorningPlanTaskModel({
    required this.id,
    required this.title,
    this.estimatedHours,
    this.projectId,
    this.projectName,
    this.category,
    required this.priority,
    required this.status,
  });
  
  factory MorningPlanTaskModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }
    
    double? parseNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }
    
    return MorningPlanTaskModel(
      id: parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      estimatedHours: parseNullableDouble(json['estimated_hours']),
      projectId: parseNullableInt(json['project_id']),
      projectName: json['project_name']?.toString(),
      category: json['category']?.toString(),
      priority: json['priority']?.toString() ?? 'MEDIUM',
      status: json['status']?.toString() ?? 'NOT_STARTED',
    );
  }
}

