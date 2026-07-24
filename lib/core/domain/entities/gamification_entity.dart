class GamificationEntity {
  final String userId;
  final int xpTotal;
  final int streakDays;
  final int level;
  final String tier;
  final DateTime? updatedAt;

  const GamificationEntity({
    required this.userId,
    this.xpTotal = 0,
    this.streakDays = 0,
    this.level = 1,
    this.tier = 'Bronze',
    this.updatedAt,
  });
}