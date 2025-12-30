class AttendanceStatusModel {
  final String date;
  final CheckInOutModel? checkIn;
  final CheckInOutModel? checkOut;
  final String workHours;
  final String status;
  final bool isLate;
  final int lateMinutes;
  // Morning plan fields (from check-in response)
  final bool? morningPlanRequired;
  final bool? morningPlanSubmitted;
  final String? morningPlanMessage;
  final int? standupId; // null if not submitted, standup ID if submitted
  // Evening summary fields (from check-out response)
  final bool? eveningSummaryRequired;
  final bool? eveningSummarySubmitted;
  final bool? eveningSummaryBlocking;
  final String? eveningSummaryMessage;
  
  AttendanceStatusModel({
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.workHours,
    required this.status,
    required this.isLate,
    required this.lateMinutes,
    this.morningPlanRequired,
    this.morningPlanSubmitted,
    this.morningPlanMessage,
    this.standupId,
    this.eveningSummaryRequired,
    this.eveningSummarySubmitted,
    this.eveningSummaryBlocking,
    this.eveningSummaryMessage,
  });
  
  factory AttendanceStatusModel.fromJson(Map<String, dynamic> json) {
    // Helper to parse boolean from dynamic
    bool parseBool(dynamic value, bool defaultValue) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) {
        return value == '1' || value.toLowerCase() == 'true' || value.toLowerCase() == 'yes';
      }
      if (value is int) return value != 0;
      return defaultValue;
    }
    
    // Handle int values that may come as String
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    // Parse morning plan fields
    bool? parseNullableBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is String) {
        return value == '1' || value.toLowerCase() == 'true' || value.toLowerCase() == 'yes';
      }
      if (value is int) return value != 0;
      return null;
    }
    
    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }
    
    return AttendanceStatusModel(
      date: json['date']?.toString() ?? '',
      checkIn: json['check_in'] != null && json['check_in'] is Map
          ? CheckInOutModel.fromJson(json['check_in'] as Map<String, dynamic>)
          : null,
      checkOut: json['check_out'] != null && json['check_out'] is Map
          ? CheckInOutModel.fromJson(json['check_out'] as Map<String, dynamic>)
          : null,
      workHours: json['work_hours']?.toString() ?? '00:00:00',
      status: json['status']?.toString() ?? '',
      isLate: parseBool(json['is_late'], false),
      lateMinutes: parseInt(json['late_minutes']),
      // Morning plan fields
      morningPlanRequired: parseNullableBool(json['morning_plan_required']),
      morningPlanSubmitted: parseNullableBool(json['morning_plan_submitted']),
      morningPlanMessage: json['morning_plan_message']?.toString(),
      standupId: parseNullableInt(json['standup_id']),
      // Evening summary fields
      eveningSummaryRequired: parseNullableBool(json['evening_summary_required']),
      eveningSummarySubmitted: parseNullableBool(json['evening_summary_submitted']),
      eveningSummaryBlocking: parseNullableBool(json['evening_summary_blocking']),
      eveningSummaryMessage: json['evening_summary_message']?.toString(),
    );
  }
}

class CheckInOutModel {
  final String time;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String method;
  
  CheckInOutModel({
    required this.time,
    this.location,
    this.latitude,
    this.longitude,
    required this.method,
  });
  
  factory CheckInOutModel.fromJson(Map<String, dynamic> json) {
    // Handle time - may be just time string or full datetime
    String timeValue = json['time']?.toString() ?? '';
    
    // Handle location - may be null
    String? locationValue = json['location']?.toString();
    
    // Handle latitude/longitude - may be null
    double? latValue;
    if (json['latitude'] != null) {
      if (json['latitude'] is num) {
        latValue = (json['latitude'] as num).toDouble();
      } else if (json['latitude'] is String) {
        latValue = double.tryParse(json['latitude'] as String);
      }
    }
    
    double? lonValue;
    if (json['longitude'] != null) {
      if (json['longitude'] is num) {
        lonValue = (json['longitude'] as num).toDouble();
      } else if (json['longitude'] is String) {
        lonValue = double.tryParse(json['longitude'] as String);
      }
    }
    
    // Method may be missing for check_out
    String methodValue = json['method']?.toString() ?? 'GPS';
    
    return CheckInOutModel(
      time: timeValue,
      location: locationValue,
      latitude: latValue,
      longitude: lonValue,
      method: methodValue,
    );
  }
}

