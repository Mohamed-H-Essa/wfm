class LeaveRequestModel {
  final int id;
  final String leaveType;
  final String startDate;
  final String endDate;
  final double numberOfDays;
  final String reason;
  final String status;
  final String? approvedBy;
  final String? approvedAt;
  final String createdAt;
  
  LeaveRequestModel({
    required this.id,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.numberOfDays,
    required this.reason,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
  });
  
  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['id'] as int,
      leaveType: json['leave_type'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      numberOfDays: json['number_of_days'] != null
          ? (json['number_of_days'] as num).toDouble()
          : 0.0,
      reason: json['reason'] as String,
      status: json['status'] as String,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] as String?,
      createdAt: json['created_at'] as String,
    );
  }
}

