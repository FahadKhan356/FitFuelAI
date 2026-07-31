import '../../../../core/data/datasources/supabase_remote_datasource.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/utils/fitness_calculator.dart';
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
    // 1. Run FitnessCalculator to compute all nutrition targets.
    final targets = FitnessCalculator.calculateAllTargets(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
      activityLevel: activityLevel,
      goalType: goalType,
      weeklyPaceKg: weeklyPaceKg,
    );

    // 2. Build the unified user model.
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
      targetCalories: targets['target_calories'] as int,
      targetProtein: targets['target_protein'] as double,
      targetCarbs: targets['target_carbs'] as double,
      targetFat: targets['target_fat'] as double,
      dailyWaterMl: targets['daily_water_ml'] as int,
    );

    // 3. Upsert into user_profiles and goals tables in parallel.
    await Future.wait([
      _dataSource.updateUserProfile(userId, user.toProfileJson()),
      _dataSource.updateGoals(userId, user.toGoalsJson()),
    ]);

    // 4. Return updated unified model.
    return user;
  }
}