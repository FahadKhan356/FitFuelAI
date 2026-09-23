/// Mirrors the public.subscriptions Supabase table.
class SubscriptionModel {
  final String id;
  final String userId;
  final String plan;
  final String status;
  final DateTime? expiresAt;
  final DateTime? startedAt;
  final DateTime? createdAt;

  const SubscriptionModel({required this.id, required this.userId, required this.plan, required this.status, this.expiresAt, this.startedAt, this.createdAt});

  bool get isActive => status == 'active' && (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) => json[key] == null ? null : DateTime.parse(json[key] as String);
    return SubscriptionModel(id: json['id'] as String, userId: json['user_id'] as String, plan: json['plan'] as String? ?? 'free', status: json['status'] as String? ?? 'expired', expiresAt: date('expires_at'), startedAt: date('started_at'), createdAt: date('created_at'));
  }

  Map<String, dynamic> toJson() => {'id': id, 'user_id': userId, 'plan': plan, 'status': status, if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(), if (startedAt != null) 'started_at': startedAt!.toIso8601String(), if (createdAt != null) 'created_at': createdAt!.toIso8601String()};
}
