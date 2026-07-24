class UserProfileEntity {
  final String userId;
  final String? name;
  final String? avatarUrl;
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final double? goalWeightKg;
  final String? activityLevel;
  final String? goalType;
  final String? bio;
  final DateTime? createdAt;

  const UserProfileEntity({
    required this.userId,
    this.name,
    this.avatarUrl,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.goalWeightKg,
    this.activityLevel,
    this.goalType,
    this.bio,
    this.createdAt,
  });
}