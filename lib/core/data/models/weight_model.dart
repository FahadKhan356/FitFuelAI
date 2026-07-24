class WeightModel {
  final String id;
  final String userId;
  final DateTime date;
  final double weightKg;
  final double? bmi;
  final double? bodyFat;
  final String? notes;
  final DateTime? createdAt;

  const WeightModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.weightKg,
    this.bmi,
    this.bodyFat,
    this.notes,
    this.createdAt,
  });

  factory WeightModel.fromJson(Map<String, dynamic> json) {
    return WeightModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      weightKg: (json['weight_kg'] as num).toDouble(),
      bmi: (json['bmi'] as num?)?.toDouble(),
      bodyFat: (json['body_fat'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T').first,
      'weight_kg': weightKg,
      if (bmi != null) 'bmi': bmi,
      if (bodyFat != null) 'body_fat': bodyFat,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}