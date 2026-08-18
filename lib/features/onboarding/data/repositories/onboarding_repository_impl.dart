import '../../../../core/data/datasources/supabase_remote_datasource.dart';
import '../../../../core/data/models/user_model.dart';
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

    // 5. Return updated unified model with server-computed nutrition targets.
    return user.copyWith(
      targetCalories: (goalsData?['target_calories'] as num?)?.toInt(),
      targetProtein: (goalsData?['target_protein'] as num?)?.toDouble(),
      targetCarbs: (goalsData?['target_carbs'] as num?)?.toDouble(),
      targetFat: (goalsData?['target_fat'] as num?)?.toDouble(),
      dailyWaterMl: (goalsData?['daily_water_ml'] as num?)?.toInt(),
    );
  }
}