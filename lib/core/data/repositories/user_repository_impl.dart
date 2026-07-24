import '../../domain/entities/user_profile_entity.dart';
import '../../domain/entities/goal_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/supabase_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final SupabaseRemoteDataSource _dataSource;

  UserRepositoryImpl(this._dataSource);

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
    final data = await _dataSource.getUserGoals(userId);
    if (data == null) return null;
    return GoalEntity(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      targetCalories: (data['target_calories'] as int?) ?? 2000,
      targetProtein: (data['target_protein'] as num?)?.toDouble() ?? 150,
      targetCarbs: (data['target_carbs'] as num?)?.toDouble() ?? 200,
      targetFat: (data['target_fat'] as num?)?.toDouble() ?? 65,
      dailyWaterMl: (data['daily_water_ml'] as int?) ?? 2500,
      goalType: data['goal_type'] as String?,
      updatedAt: data['updated_at'] != null ? DateTime.parse(data['updated_at'] as String) : null,
    );
  }

  @override
  Future<void> updateGoals(String userId, Map<String, dynamic> data) async {
    await _dataSource.updateGoals(userId, data);
  }
}