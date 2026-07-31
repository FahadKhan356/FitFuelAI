import '../../../../core/data/models/user_model.dart';

abstract class OnboardingRepository {
  /// Submits all onboarding form inputs:
  /// 1. Runs [FitnessCalculator] to compute target calories/protein/carbs/fat/water.
  /// 2. Upserts into `public.user_profiles` and `public.goals` tables.
  /// 3. Returns the updated unified [UserModel].
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
  });
}