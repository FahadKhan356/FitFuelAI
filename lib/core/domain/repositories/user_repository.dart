import '../entities/user_profile_entity.dart';
import '../entities/goal_entity.dart';

abstract class UserRepository {
  Future<UserProfileEntity?> getUserProfile(String userId);
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data);
  Future<GoalEntity?> getUserGoals(String userId);
  Future<void> updateGoals(String userId, Map<String, dynamic> data);
}