class AchievementEntity {
  final String id;
  final String userId;
  final String badge;
  final int progress;
  final bool completed;
  final DateTime? completedAt;

  const AchievementEntity({
    required this.id,
    required this.userId,
    required this.badge,
    this.progress = 0,
    this.completed = false,
    this.completedAt,
  });
}