import '../../../../core/data/datasources/supabase_remote_datasource.dart';
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

    final profileData = results[0] as Map<String, dynamic>?;
    final goalsData = results[1] as Map<String, dynamic>?;

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

  UserProfileModel _combine(Map<String, dynamic>? profile, Map<String, dynamic>? goals, String userId) {
    return UserProfileModel(
      userId: userId,
      name: profile?['name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      age: profile?['age'] as int?,
      gender: profile?['gender'] as String?,
      heightCm: (profile?['height_cm'] as num?)?.toDouble(),
      weightKg: (profile?['weight_kg'] as num?)?.toDouble(),
      goalWeightKg: (profile?['goal_weight_kg'] as num?)?.toDouble(),
      activityLevel: profile?['activity_level'] as String?,
      goalType: profile?['goal_type'] as String? ?? goals?['goal_type'] as String?,
      bio: profile?['bio'] as String?,
      createdAt: profile?['created_at'] != null ? DateTime.parse(profile!['created_at'] as String) : null,
      targetCalories: (goals?['target_calories'] as int?) ?? 2000,
      targetProtein: (goals?['target_protein'] as num?)?.toDouble() ?? 150,
      targetCarbs: (goals?['target_carbs'] as num?)?.toDouble() ?? 200,
      targetFat: (goals?['target_fat'] as num?)?.toDouble() ?? 65,
      dailyWaterMl: (goals?['daily_water_ml'] as int?) ?? 2500,
    );
  }
}