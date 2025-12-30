class StandupReminderStatusModel {
  final MorningReminderStatus morning;
  final EveningReminderStatus evening;
  final ReminderSettings settings;
  
  StandupReminderStatusModel({
    required this.morning,
    required this.evening,
    required this.settings,
  });
  
  factory StandupReminderStatusModel.fromJson(Map<String, dynamic> json) {
    return StandupReminderStatusModel(
      morning: MorningReminderStatus.fromJson(json['morning'] as Map<String, dynamic>),
      evening: EveningReminderStatus.fromJson(json['evening'] as Map<String, dynamic>),
      settings: ReminderSettings.fromJson(json['reminder_settings'] as Map<String, dynamic>),
    );
  }
}

class MorningReminderStatus {
  final bool needsReminder;
  final String deadline;
  final bool deadlinePassed;
  final bool submitted;
  final String? submittedAt;
  
  MorningReminderStatus({
    required this.needsReminder,
    required this.deadline,
    required this.deadlinePassed,
    required this.submitted,
    this.submittedAt,
  });
  
  factory MorningReminderStatus.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value, bool defaultValue) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) {
        return value == '1' || value.toLowerCase() == 'true' || value.toLowerCase() == 'yes';
      }
      if (value is int) return value != 0;
      return defaultValue;
    }
    
    return MorningReminderStatus(
      needsReminder: parseBool(json['needs_reminder'], false),
      deadline: json['deadline']?.toString() ?? '12:00:00',
      deadlinePassed: parseBool(json['deadline_passed'], false),
      submitted: parseBool(json['submitted'], false),
      submittedAt: json['submitted_at']?.toString(),
    );
  }
}

class EveningReminderStatus {
  final bool needsReminder;
  final String deadline;
  final bool deadlinePassed;
  final bool submitted;
  final String? submittedAt;
  
  EveningReminderStatus({
    required this.needsReminder,
    required this.deadline,
    required this.deadlinePassed,
    required this.submitted,
    this.submittedAt,
  });
  
  factory EveningReminderStatus.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value, bool defaultValue) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) {
        return value == '1' || value.toLowerCase() == 'true' || value.toLowerCase() == 'yes';
      }
      if (value is int) return value != 0;
      return defaultValue;
    }
    
    return EveningReminderStatus(
      needsReminder: parseBool(json['needs_reminder'], false),
      deadline: json['deadline']?.toString() ?? '20:00:00',
      deadlinePassed: parseBool(json['deadline_passed'], false),
      submitted: parseBool(json['submitted'], false),
      submittedAt: json['submitted_at']?.toString(),
    );
  }
}

class ReminderSettings {
  final bool morningReminderEnabled;
  final String morningReminderTime;
  final bool eveningReminderEnabled;
  final String eveningReminderTime;
  
  ReminderSettings({
    required this.morningReminderEnabled,
    required this.morningReminderTime,
    required this.eveningReminderEnabled,
    required this.eveningReminderTime,
  });
  
  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value, bool defaultValue) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) {
        return value == '1' || value.toLowerCase() == 'true' || value.toLowerCase() == 'yes';
      }
      if (value is int) return value != 0;
      return defaultValue;
    }
    
    return ReminderSettings(
      morningReminderEnabled: parseBool(json['morning_reminder_enabled'], true),
      morningReminderTime: json['morning_reminder_time']?.toString() ?? '10:30:00',
      eveningReminderEnabled: parseBool(json['evening_reminder_enabled'], true),
      eveningReminderTime: json['evening_reminder_time']?.toString() ?? '17:00:00',
    );
  }
}

