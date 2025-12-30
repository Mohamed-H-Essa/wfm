class CheckoutStatusModel {
  final bool canCheckout;
  final String? blockingReason;
  final bool eveningSummaryRequired;
  final bool eveningSummarySubmitted;
  final int? standupId;
  
  CheckoutStatusModel({
    required this.canCheckout,
    this.blockingReason,
    required this.eveningSummaryRequired,
    required this.eveningSummarySubmitted,
    this.standupId,
  });
  
  factory CheckoutStatusModel.fromJson(Map<String, dynamic> json) {
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
    
    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }
    
    return CheckoutStatusModel(
      canCheckout: parseBool(json['can_checkout'], true),
      blockingReason: json['blocking_reason']?.toString(),
      eveningSummaryRequired: parseBool(json['evening_summary_required'], false),
      eveningSummarySubmitted: parseBool(json['evening_summary_submitted'], false),
      standupId: parseNullableInt(json['standup_id']),
    );
  }
}

