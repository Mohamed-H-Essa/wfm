class ForgotCheckinSettingsModel {
  final ForgotCheckinSettings settings;
  final ForgotCheckinUserStatus userStatus;
  final ForgotCheckinRestrictions restrictions;
  final ForgotCheckinHelpText helpText;
  
  ForgotCheckinSettingsModel({
    required this.settings,
    required this.userStatus,
    required this.restrictions,
    required this.helpText,
  });
  
  factory ForgotCheckinSettingsModel.fromJson(Map<String, dynamic> json) {
    return ForgotCheckinSettingsModel(
      settings: ForgotCheckinSettings.fromJson(
        json['settings'] as Map<String, dynamic>,
      ),
      userStatus: ForgotCheckinUserStatus.fromJson(
        json['user_status'] as Map<String, dynamic>,
      ),
      restrictions: ForgotCheckinRestrictions.fromJson(
        json['restrictions'] as Map<String, dynamic>,
      ),
      helpText: ForgotCheckinHelpText.fromJson(
        json['help_text'] as Map<String, dynamic>,
      ),
    );
  }
}

class ForgotCheckinSettings {
  final int maxDaysBack;
  final int maxPerMonth;
  final int autoApproveHours;
  final bool deadlineSameWeek;
  final bool requireJiraProof;
  final double autoHours;
  final double penaltyDays;
  
  ForgotCheckinSettings({
    required this.maxDaysBack,
    required this.maxPerMonth,
    required this.autoApproveHours,
    required this.deadlineSameWeek,
    required this.requireJiraProof,
    required this.autoHours,
    required this.penaltyDays,
  });
  
  factory ForgotCheckinSettings.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value, int defaultValue) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }
    
    double parseDouble(dynamic value, double defaultValue) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }
    
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
    
    return ForgotCheckinSettings(
      maxDaysBack: parseInt(json['max_days_back'], 3),
      maxPerMonth: parseInt(json['max_per_month'], 2),
      autoApproveHours: parseInt(json['auto_approve_hours'], 24),
      deadlineSameWeek: parseBool(json['deadline_same_week'], false),
      requireJiraProof: parseBool(json['require_jira_proof'], false),
      autoHours: parseDouble(json['auto_hours'], 4.0),
      penaltyDays: parseDouble(json['penalty_days'], 0.5),
    );
  }
}

class ForgotCheckinUserStatus {
  final int monthlyCount;
  final int monthlyLimit;
  final int remainingRequests;
  final bool canSubmit;
  
  ForgotCheckinUserStatus({
    required this.monthlyCount,
    required this.monthlyLimit,
    required this.remainingRequests,
    required this.canSubmit,
  });
  
  factory ForgotCheckinUserStatus.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value, int defaultValue) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }
    
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
    
    return ForgotCheckinUserStatus(
      monthlyCount: parseInt(json['monthly_count'], 0),
      monthlyLimit: parseInt(json['monthly_limit'], 2),
      remainingRequests: parseInt(json['remaining_requests'], 0),
      canSubmit: parseBool(json['can_submit'], true),
    );
  }
}

class ForgotCheckinRestrictions {
  final DateTime earliestAllowedDate;
  final DateTime latestAllowedDate;
  final DeadlineInfo? deadlineInfo;
  
  ForgotCheckinRestrictions({
    required this.earliestAllowedDate,
    required this.latestAllowedDate,
    this.deadlineInfo,
  });
  
  factory ForgotCheckinRestrictions.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now().subtract(const Duration(days: 3));
        }
      }
      return DateTime.now().subtract(const Duration(days: 3));
    }
    
    DeadlineInfo? deadlineInfo;
    if (json['deadline_info'] != null && json['deadline_info'] is Map) {
      deadlineInfo = DeadlineInfo.fromJson(
        json['deadline_info'] as Map<String, dynamic>,
      );
    }
    
    return ForgotCheckinRestrictions(
      earliestAllowedDate: parseDate(json['earliest_allowed_date']),
      latestAllowedDate: parseDate(json['latest_allowed_date']),
      deadlineInfo: deadlineInfo,
    );
  }
}

class DeadlineInfo {
  final DateTime weekStart;
  final DateTime weekEnd;
  final String message;
  
  DeadlineInfo({
    required this.weekStart,
    required this.weekEnd,
    required this.message,
  });
  
  factory DeadlineInfo.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }
    
    return DeadlineInfo(
      weekStart: parseDate(json['week_start']),
      weekEnd: parseDate(json['week_end']),
      message: json['message']?.toString() ?? '',
    );
  }
}

class ForgotCheckinHelpText {
  final String? maxDaysBack;
  final String? monthlyLimit;
  final String? autoApprove;
  final String? jiraProof;
  
  ForgotCheckinHelpText({
    this.maxDaysBack,
    this.monthlyLimit,
    this.autoApprove,
    this.jiraProof,
  });
  
  factory ForgotCheckinHelpText.fromJson(Map<String, dynamic> json) {
    return ForgotCheckinHelpText(
      maxDaysBack: json['max_days_back']?.toString(),
      monthlyLimit: json['monthly_limit']?.toString(),
      autoApprove: json['auto_approve']?.toString(),
      jiraProof: json['jira_proof']?.toString(),
    );
  }
}

