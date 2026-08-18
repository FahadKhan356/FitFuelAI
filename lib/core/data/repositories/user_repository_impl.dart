import '../../utils/fitness_calculator.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/entities/goal_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/supabase_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final SupabaseRemoteDataSource _dataSource;

  UserRepositoryImpl(this._dataSource);

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? 0;
    }
    return 0;
  }

  @override
  Future<UserProfileEntity?> getUserProfile(String userId) async {
    final data = await _dataSource.getUserProfile(userId);
    if (data == null) return null;
    return UserProfileEntity(
      userId: data['user_id'] as String,
      name: data['name'] as String?,
      avatarUrl: data['avatar_url'] as String?,
      age: data['age'] as int?,
      gender: data['gender'] as String?,
      heightCm: (data['height_cm'] as num?)?.toDouble(),
      weightKg: (data['weight_kg'] as num?)?.toDouble(),
      goalWeightKg: (data['goal_weight_kg'] as num?)?.toDouble(),
      activityLevel: data['activity_level'] as String?,
      goalType: data['goal_type'] as String?,
      bio: data['bio'] as String?,
      createdAt: data['created_at'] != null ? DateTime.parse(data['created_at'] as String) : null,
    );
  }

  @override
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _dataSource.updateUserProfile(userId, data);
  }

  @override
  Future<GoalEntity?> getUserGoals(String userId) async {
    final profileData = await _dataSource.getUserProfile(userId);
    final data = await _dataSource.getUserGoals(userId);

    if (profileData == null && data == null) return null;

    final age = (profileData?['age'] as num?)?.toInt() ?? 30;
    final gender = (profileData?['gender'] as String?) ?? 'male';
    final heightCm = (profileData?['height_cm'] as num?)?.toDouble() ?? 170.0;
    final weightKg = (profileData?['weight_kg'] as num?)?.toDouble() ?? 70.0;
    final activityLevel = (profileData?['activity_level'] as String?) ?? 'moderately_active';
    final goalType = (profileData?['goal_type'] as String?) ??
        (data?['goal_type'] as String?) ??
        'maintain';
    final weeklyPaceKg = ((profileData?['weekly_pace_kg'] as num?) ??
            (data?['weekly_pace_kg'] as num?) ??
            0.5)
        .toDouble();
    final targetWeightKg = ((profileData?['goal_weight_kg'] as num?) ??
            (data?['target_weight_kg'] as num?) ??
            weightKg)
        .toDouble();
    final targetDate = data?['target_date'] != null
        ? DateTime.tryParse(data!['target_date'] as String)
        : null;

    final targets = FitnessCalculator.calculateAllTargets(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
      activityLevel: activityLevel,
      goalType: goalType,
      weeklyPaceKg: weeklyPaceKg,
    );

    final refreshed = GoalEntity(
      id: data?['id'] as String? ?? '',
      userId: userId,
      targetCalories: targets['target_calories'] as int,
      targetProtein: targets['target_protein'] as double,
      targetCarbs: targets['target_carbs'] as double,
      targetFat: targets['target_fat'] as double,
      dailyWaterMl: targets['daily_water_ml'] as int,
      goalType: goalType,
      targetWeightKg: targetWeightKg,
      weeklyPaceKg: weeklyPaceKg,
      targetDate: targetDate,
      updatedAt: DateTime.now(),
    );

    final needsRefresh = data == null ||
        (data['goal_type'] as String?) != goalType ||
        (data['target_calories'] as num?)?.toInt() != refreshed.targetCalories ||
        (_parseDouble(data['target_protein']) - refreshed.targetProtein).abs() > 0.1 ||
        (_parseDouble(data['target_carbs']) - refreshed.targetCarbs).abs() > 0.1 ||
        (_parseDouble(data['target_fat']) - refreshed.targetFat).abs() > 0.1 ||
        (_parseInt(data['daily_water_ml']) - refreshed.dailyWaterMl) != 0;

    if (needsRefresh) {
      await _dataSource.updateGoals(userId, {
        'user_id': userId,
        'goal_type': goalType,
        'target_weight_kg': targetWeightKg,
        'weekly_pace_kg': weeklyPaceKg,
        if (targetDate != null) 'target_date': targetDate.toIso8601String().split('T').first,
        'target_calories': refreshed.targetCalories,
        'target_protein': refreshed.targetProtein,
        'target_carbs': refreshed.targetCarbs,
        'target_fat': refreshed.targetFat,
        'daily_water_ml': refreshed.dailyWaterMl,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    return refreshed;
  }

  @override
  Future<void> updateGoals(String userId, Map<String, dynamic> data) async {
    await _dataSource.updateGoals(userId, data);
  }
}