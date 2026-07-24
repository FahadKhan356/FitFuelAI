class WaterEntryEntity {
  final String id;
  final String userId;
  final DateTime date;
  final int amountMl;
  final DateTime? createdAt;

  const WaterEntryEntity({
    required this.id,
    required this.userId,
    required this.date,
    required this.amountMl,
    this.createdAt,
  });
}