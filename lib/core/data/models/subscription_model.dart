class SubscriptionModel {
  final String id;
  final String userId;
  final String planType;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? paymentProvider;
  final String? paymentId;
  final DateTime? createdAt;

  const SubscriptionModel({
    required this.id,
    required this.userId,
    required this.planType,
    this.isActive = false,
    this.startDate,
    this.endDate,
    this.paymentProvider,
    this.paymentId,
    this.createdAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      planType: json['plan_type'] as String,
      isActive: json['is_active'] as bool? ?? false,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      paymentProvider: json['payment_provider'] as String?,
      paymentId: json['payment_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_type': planType,
      'is_active': isActive,
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      if (paymentProvider != null) 'payment_provider': paymentProvider,
      if (paymentId != null) 'payment_id': paymentId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}