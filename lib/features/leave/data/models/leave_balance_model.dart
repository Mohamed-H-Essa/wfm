class LeaveBalanceModel {
  final LeaveTypeBalance annualLeave;
  final LeaveTypeBalance accidentalLeave;
  final LeaveTypeBalance marriageLeave;
  
  LeaveBalanceModel({
    required this.annualLeave,
    required this.accidentalLeave,
    required this.marriageLeave,
  });
  
  factory LeaveBalanceModel.fromJson(Map<String, dynamic> json) {
    return LeaveBalanceModel(
      annualLeave: LeaveTypeBalance.fromJson(json['annual_leave'] as Map<String, dynamic>),
      accidentalLeave: LeaveTypeBalance.fromJson(json['accidental_leave'] as Map<String, dynamic>),
      marriageLeave: LeaveTypeBalance.fromJson(json['marriage_leave'] as Map<String, dynamic>),
    );
  }
}

class LeaveTypeBalance {
  final int total;
  final int used;
  final int remaining;
  final int pending;
  
  LeaveTypeBalance({
    required this.total,
    required this.used,
    required this.remaining,
    required this.pending,
  });
  
  factory LeaveTypeBalance.fromJson(Map<String, dynamic> json) {
    return LeaveTypeBalance(
      total: json['total'] as int? ?? 0,
      used: json['used'] as int? ?? 0,
      remaining: json['remaining'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
    );
  }
}

