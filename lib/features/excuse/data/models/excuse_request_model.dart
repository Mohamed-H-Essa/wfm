class ExcuseRequestModel {
  final int id;
  final String date;
  final String type;
  final String? fromTime;
  final String? toTime;
  final String reason;
  final String status;
  final bool hasAttachment;
  final String? createdAt;
  
  ExcuseRequestModel({
    required this.id,
    required this.date,
    required this.type,
    this.fromTime,
    this.toTime,
    required this.reason,
    required this.status,
    required this.hasAttachment,
    this.createdAt,
  });
  
  factory ExcuseRequestModel.fromJson(Map<String, dynamic> json) {
    return ExcuseRequestModel(
      id: json['id'] as int,
      date: json['date'] as String,
      type: json['type'] as String,
      fromTime: json['from_time'] as String?,
      toTime: json['to_time'] as String?,
      reason: json['reason'] as String,
      status: json['status'] as String,
      hasAttachment: json['has_attachment'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );
  }
}

