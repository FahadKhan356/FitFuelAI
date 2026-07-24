class GoalEntity {
  final String id;
  final String userId;
  final int targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;
  final int dailyWaterMl;
  final String? goalType;
  final DateTime? updatedAt;

  const GoalEntity({
    required this.id,
    required this.userId,
    this.targetCalories = 2000,
    this.targetProtein = 150,
    this.targetCarbs = 200,
    this.targetFat = 65,
    this.dailyWaterMl = 2500,
    this.goalType,
    this.updatedAt,
  });
}