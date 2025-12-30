class StandupEditabilityModel {
  final MorningEditability morning;
  
  StandupEditabilityModel({
    required this.morning,
  });
  
  factory StandupEditabilityModel.fromJson(Map<String, dynamic> json) {
    return StandupEditabilityModel(
      morning: MorningEditability.fromJson(json['morning'] as Map<String, dynamic>),
    );
  }
}

class MorningEditability {
  final bool canEdit;
  final bool submitted;
  final String? submittedAt;
  final String? editDeadline;
  final bool editDeadlinePassed;
  final String? reason;
  
  MorningEditability({
    required this.canEdit,
    required this.submitted,
    this.submittedAt,
    this.editDeadline,
    required this.editDeadlinePassed,
    this.reason,
  });
  
  factory MorningEditability.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value, bool defaultValue) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) {
        return value == '1' || value.toLowerCase() == 'true' || value.toLowerCase() == 'yes';
      }
      if (value is int) return value != 0;
      return defaultValue;
    }
    
    return MorningEditability(
      canEdit: parseBool(json['can_edit'], false),
      submitted: parseBool(json['submitted'], false),
      submittedAt: json['submitted_at']?.toString(),
      editDeadline: json['edit_deadline']?.toString(),
      editDeadlinePassed: parseBool(json['edit_deadline_passed'], false),
      reason: json['reason']?.toString(),
    );
  }
}

