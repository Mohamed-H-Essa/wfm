class AttendanceStatusModel {
  final String date;
  final CheckInOutModel? checkIn;
  final CheckInOutModel? checkOut;
  final String workHours;
  final String status;
  final bool isLate;
  final int lateMinutes;
  
  AttendanceStatusModel({
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.workHours,
    required this.status,
    required this.isLate,
    required this.lateMinutes,
  });
  
  factory AttendanceStatusModel.fromJson(Map<String, dynamic> json) {
    return AttendanceStatusModel(
      date: json['date'] as String,
      checkIn: json['check_in'] != null
          ? CheckInOutModel.fromJson(json['check_in'] as Map<String, dynamic>)
          : null,
      checkOut: json['check_out'] != null
          ? CheckInOutModel.fromJson(json['check_out'] as Map<String, dynamic>)
          : null,
      workHours: json['work_hours'] as String? ?? '00:00:00',
      status: json['status'] as String,
      isLate: json['is_late'] as bool? ?? false,
      lateMinutes: json['late_minutes'] as int? ?? 0,
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
    return CheckInOutModel(
      time: json['time'] as String,
      location: json['location'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      method: json['method'] as String? ?? 'GPS',
    );
  }
}

