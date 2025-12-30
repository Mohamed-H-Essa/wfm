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
    // Handle standups list - may be null or empty
    List<StandupHistoryItemModel> standupsList = [];
    if (json['standups'] != null && json['standups'] is List) {
      standupsList = (json['standups'] as List<dynamic>)
          .map((s) => StandupHistoryItemModel.fromJson(s as Map<String, dynamic>))
          .toList();
    }
    
    // Handle summary - may be null
    StandupHistorySummaryModel? summaryData;
    if (json['summary'] != null && json['summary'] is Map) {
      summaryData = StandupHistorySummaryModel.fromJson(json['summary'] as Map<String, dynamic>);
    } else {
      // Create default summary if missing
      summaryData = StandupHistorySummaryModel(
        totalSubmissions: 0,
        workingDays: 0,
        submissionRate: 0.0,
        averageCompletion: 0.0,
        averageProductivity: 0.0,
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
        totalRecords: standupsList.length,
      );
    }
    
    return StandupHistoryModel(
      standups: standupsList,
      summary: summaryData,
      pagination: paginationData,
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
    
    double? parseDoubleNullable(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }
    
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
    
    // API returns id as string, parse it
    int standupId;
    if (json['id'] is int) {
      standupId = json['id'] as int;
    } else if (json['id'] is String) {
      standupId = int.tryParse(json['id'] as String) ?? 0;
    } else {
      standupId = 0;
    }
    
    return StandupHistoryItemModel(
      id: standupId,
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      workType: json['work_type']?.toString() ?? 'OFFICE',
      todayGoals: json['today_goals']?.toString(),
      completionPercentage: parseIntNullable(json['completion_percentage']),
      productivityRating: parseDoubleNullable(json['productivity_rating']),
      hasBlockers: parseBool(json['has_blockers'], false),
      tasksCompleted: parseInt(json['tasks_completed']),
      tasksTotal: parseInt(json['tasks_total']),
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
    // Handle int values that may come as String
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    
    return StandupHistorySummaryModel(
      totalSubmissions: parseInt(json['total_submissions']),
      workingDays: parseInt(json['working_days']),
      submissionRate: parseDouble(json['submission_rate']),
      averageCompletion: parseDouble(json['average_completion']),
      averageProductivity: parseDouble(json['average_productivity']),
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
    
    // API may return current_page as string or int
    int currentPageValue;
    if (json['current_page'] is int) {
      currentPageValue = json['current_page'] as int;
    } else if (json['current_page'] is String) {
      currentPageValue = int.tryParse(json['current_page'] as String) ?? 1;
    } else {
      currentPageValue = 1;
    }
    
    return PaginationModel(
      currentPage: currentPageValue,
      totalPages: parseInt(json['total_pages'], 1),
      totalRecords: parseInt(json['total_records'], 0),
    );
  }
}

