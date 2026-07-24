class WeightEntryEntity {
  final String id;
  final String userId;
  final DateTime date;
  final double weightKg;
  final double? bmi;
  final double? bodyFat;
  final String? notes;
  final DateTime? createdAt;

  const WeightEntryEntity({
    required this.id,
    required this.userId,
    required this.date,
    required this.weightKg,
    this.bmi,
    this.bodyFat,
    this.notes,
    this.createdAt,
  });
}