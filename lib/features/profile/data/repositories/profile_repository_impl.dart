import '../../../../core/data/datasources/supabase_remote_datasource.dart';
import '../../../../core/utils/fitness_calculator.dart';
import '../../data/models/user_profile_model.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final SupabaseRemoteDataSource _dataSource;

  ProfileRepositoryImpl(this._dataSource);

  @override
  Future<UserProfileModel> fetchUserProfile(String userId) async {
    // Fetch profile and goals in parallel
    final results = await Future.wait([
      _dataSource.getUserProfile(userId),
      _dataSource.getUserGoals(userId),
    ]);

    final profileData = results[0];
    final goalsData = results[1];

    return _combine(profileData, goalsData, userId);
  }

  @override
  Future<UserProfileModel> updateUserProfile(UserProfileModel user) async {
    // Update both tables in parallel
    await Future.wait([
      _dataSource.updateUserProfile(user.userId, user.toProfileJson()),
      _dataSource.updateGoals(user.userId, user.toGoalsJson()),
    ]);

    // Return updated model by copying with the same values (already updated)
    return user;
  }

  @override
  Future<UserProfileModel> recalculateGoals(UserProfileModel user) async {
    // Guard: need age, gender, height, weight & activity to calculate.
    if (user.age == null ||
        user.gender == null ||
        user.heightCm == null ||
        user.weightKg == null ||
        user.activityLevel == null) {
      return user;
    }

    final goalType = user.goalType ?? 'maintain';
    final weeklyPace = user.weeklyPaceKg ?? 0.5;
    final targetWeight = user.goalWeightKg ?? user.weightKg!;

    // Re-run FitnessCalculator with current (possibly updated) metrics.
    final targets = FitnessCalculator.calculateAllTargets(
      weightKg: user.weightKg!,
      heightCm: user.heightCm!,
      age: user.age!,
      gender: user.gender!,
      activityLevel: user.activityLevel!,
      goalType: goalType,
      weeklyPaceKg: weeklyPace,
    );

    final updated = user.copyWith(
      goalWeightKg: targetWeight,
      weeklyPaceKg: weeklyPace,
      targetCalories: targets['target_calories'] as int,
      targetProtein: targets['target_protein'] as double,
      targetCarbs: targets['target_carbs'] as double,
      targetFat: targets['target_fat'] as double,
      dailyWaterMl: targets['daily_water_ml'] as int,
    );

    // Persist the recalculated targets to the goals table immediately.
    await _dataSource.updateGoals(user.userId, updated.toGoalsJson());

    return updated;
  }

  UserProfileModel _combine(Map<String, dynamic>? profile, Map<String, dynamic>? goals, String userId) {
    return UserProfileModel(
      userId: userId,
      name: profile?['name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      age: _toInt(profile?['age']),
      gender: profile?['gender'] as String?,
      heightCm: _toDouble(profile?['height_cm']),
      weightKg: _toDouble(profile?['weight_kg']),
      goalWeightKg: _toDouble(profile?['goal_weight_kg']),
      activityLevel: profile?['activity_level'] as String?,
      goalType: profile?['goal_type'] as String? ?? goals?['goal_type'] as String?,
      dietPreference: profile?['diet_preference'] as String?,
      workoutFrequency: _toInt(profile?['workout_frequency']),
      bio: profile?['bio'] as String?,
      createdAt: profile?['created_at'] is String
          ? DateTime.tryParse(profile!['created_at'] as String)
          : null,
      targetCalories: _toInt(goals?['target_calories']) ?? 2000,
      targetProtein: _toDouble(goals?['target_protein']) ?? 150,
      targetCarbs: _toDouble(goals?['target_carbs']) ?? 200,
      targetFat: _toDouble(goals?['target_fat']) ?? 65,
      dailyWaterMl: _toInt(goals?['daily_water_ml']) ?? 2500,
      weeklyPaceKg: _toDouble(goals?['weekly_pace_kg']),
      targetDate: goals?['target_date'] is String
          ? DateTime.tryParse(goals!['target_date'] as String)
          : null,
    );
  }

  /// Robust parser that accepts both native numbers and string-encoded numbers
  /// (e.g. `"160.00"`, `"3"`) since Supabase may return them as strings.
  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      return int.tryParse(v.trim()) ?? double.tryParse(v.trim())?.toInt();
    }
    return null;
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) {
      final d = double.tryParse(v.trim());
      if (d != null) return d;
      return int.tryParse(v.trim())?.toDouble();
    }
    return null;
  }
}