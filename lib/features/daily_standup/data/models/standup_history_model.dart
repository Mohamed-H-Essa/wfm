class StandupHistoryModel {
  final List<StandupHistoryItemModel> standups;
  final StandupHistorySummaryModel summary;
  final PaginationModel pagination;
  
  StandupHistoryModel({
    required this.standups,
    required this.summary,
    required this.pagination,
  });
  
  factory StandupHistoryModel.fromJson(Map<String, dynamic> json) {
    return StandupHistoryModel(
      standups: (json['standups'] as List<dynamic>)
          .map((s) => StandupHistoryItemModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      summary: StandupHistorySummaryModel.fromJson(json['summary'] as Map<String, dynamic>),
      pagination: PaginationModel.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

class StandupHistoryItemModel {
  final int id;
  final String date;
  final String status;
  final String workType;
  final String? todayGoals;
  final int? completionPercentage;
  final double? productivityRating;
  final bool hasBlockers;
  final int tasksCompleted;
  final int tasksTotal;
  
  StandupHistoryItemModel({
    required this.id,
    required this.date,
    required this.status,
    required this.workType,
    this.todayGoals,
    this.completionPercentage,
    this.productivityRating,
    required this.hasBlockers,
    required this.tasksCompleted,
    required this.tasksTotal,
  });
  
  factory StandupHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return StandupHistoryItemModel(
      id: json['id'] as int,
      date: json['date'] as String,
      status: json['status'] as String,
      workType: json['work_type'] as String? ?? 'OFFICE',
      todayGoals: json['today_goals'] as String?,
      completionPercentage: json['completion_percentage'] as int?,
      productivityRating: json['productivity_rating'] != null
          ? (json['productivity_rating'] as num).toDouble()
          : null,
      hasBlockers: json['has_blockers'] as bool? ?? false,
      tasksCompleted: json['tasks_completed'] as int? ?? 0,
      tasksTotal: json['tasks_total'] as int? ?? 0,
    );
  }
}

class StandupHistorySummaryModel {
  final int totalSubmissions;
  final int workingDays;
  final double submissionRate;
  final double averageCompletion;
  final double averageProductivity;
  
  StandupHistorySummaryModel({
    required this.totalSubmissions,
    required this.workingDays,
    required this.submissionRate,
    required this.averageCompletion,
    required this.averageProductivity,
  });
  
  factory StandupHistorySummaryModel.fromJson(Map<String, dynamic> json) {
    return StandupHistorySummaryModel(
      totalSubmissions: json['total_submissions'] as int? ?? 0,
      workingDays: json['working_days'] as int? ?? 0,
      submissionRate: json['submission_rate'] != null
          ? (json['submission_rate'] as num).toDouble()
          : 0.0,
      averageCompletion: json['average_completion'] != null
          ? (json['average_completion'] as num).toDouble()
          : 0.0,
      averageProductivity: json['average_productivity'] != null
          ? (json['average_productivity'] as num).toDouble()
          : 0.0,
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

