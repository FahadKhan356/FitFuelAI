import '../../../../core/data/datasources/supabase_remote_datasource.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/services/home_data_cache.dart';
import '../../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final SupabaseRemoteDataSource _dataSource;

  OnboardingRepositoryImpl(this._dataSource);

  @override
  Future<UserModel> submitOnboardingData({
    required String userId,
    String? email,
    String? name,
    String? avatarUrl,
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    required String dietPreference,
    required int workoutFrequency,
    required String goalType,
    required double targetWeightKg,
    required double weeklyPaceKg,
    DateTime? targetDate,
  }) async {
    // 1. Build the profile model (no computed nutrition — server does that).
    final user = UserModel(
      id: userId,
      email: email,
      name: name,
      avatarUrl: avatarUrl,
      age: age,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
      activityLevel: activityLevel,
      dietPreference: dietPreference,
      workoutFrequency: workoutFrequency,
      goalType: goalType,
      targetWeightKg: targetWeightKg,
      weeklyPaceKg: weeklyPaceKg,
      targetDate: targetDate,
    );

    // 2. Upsert user_profiles — this is the data the RPC reads.
    //    toProfileJson() now includes: name, age, gender, height_cm,
    //    weight_kg, goal_weight_kg, activity_level, goal_type, etc.
    await _dataSource.updateUserProfile(userId, user.toProfileJson());

    // 3. Trigger server-side calculation.
    //    The RPC reads user_profiles and writes target_calories,
    //    target_protein, target_carbs, target_fat, daily_water_ml to goals.
    await _dataSource.calculateUserGoals(userId);

    // 4. Fetch the freshly computed goals back from Supabase.
    final goalsData = await _dataSource.getUserGoals(userId);

    double parseD(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int parseI(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? 0;
      return 0;
    }

    final computedModel = user.copyWith(
      targetCalories: parseI(goalsData?['target_calories']),
      targetProtein: parseD(goalsData?['target_protein']),
      targetCarbs: parseD(goalsData?['target_carbs']),
      targetFat: parseD(goalsData?['target_fat']),
      dailyWaterMl: parseI(goalsData?['daily_water_ml']),
    );

    // 5. Pre-populate HomeDataCache immediately so HomeScreen renders with 0ms delay and no flicker
    await HomeDataCache.save(
      userId,
      HomeCachedData(
        name: name,
        targetCalories: computedModel.targetCalories ?? 2000,
        targetProtein: computedModel.targetProtein ?? 0,
        targetCarbs: computedModel.targetCarbs ?? 0,
        targetFat: computedModel.targetFat ?? 0,
        targetWaterMl: computedModel.dailyWaterMl ?? 2000,
      ),
    );

    // 6. Return updated unified model with server-computed nutrition targets.
    return computedModel;
  }
}