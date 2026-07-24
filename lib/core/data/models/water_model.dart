class WaterModel {
  final String id;
  final String userId;
  final DateTime date;
  final int amountMl;
  final DateTime? createdAt;

  const WaterModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.amountMl,
    this.createdAt,
  });

  factory WaterModel.fromJson(Map<String, dynamic> json) {
    return WaterModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      amountMl: json['amount_ml'] as int,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T').first,
      'amount_ml': amountMl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}