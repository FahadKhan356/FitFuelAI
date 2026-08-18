import 'package:flutter/foundation.dart';

import '../../domain/entities/goal_entity.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/supabase_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final SupabaseRemoteDataSource _dataSource;

  UserRepositoryImpl(this._dataSource);

  @override
  Future<UserProfileEntity?> getUserProfile(String userId) async {
    try {
      final data = await _dataSource.getUserProfile(userId);
      if (data == null) return null;
      return UserProfileEntity.fromJson(data);
    } catch (e) {
      debugPrint('getUserProfile error: $e');
      return null;
    }
  }

  @override
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    await _dataSource.updateUserProfile(userId, data);
  }

  @override
  Future<GoalEntity?> getUserGoals(String userId) async {
    try {
      final data = await _dataSource.getUserGoals(userId);

      // 1. If goals exist in DB, return directly
      if (data != null && data['target_calories'] != null) {
        return GoalEntity.fromJson(data);
      }

      // 2. If goals row is missing, trigger calculate_user_goals RPC
      try {
        await _dataSource.calculateUserGoals(userId);
        final freshlyCalculated = await _dataSource.getUserGoals(userId);
        if (freshlyCalculated != null &&
            freshlyCalculated['target_calories'] != null) {
          return GoalEntity.fromJson(freshlyCalculated);
        }
      } catch (rpcErr) {
        debugPrint('calculateUserGoals RPC fallback notice: $rpcErr');
      }

      return null;
    } catch (e) {
      debugPrint('getUserGoals error: $e');
      return null;
    }
  }

  @override
  Future<void> updateGoals(String userId, Map<String, dynamic> data) async {
    await _dataSource.updateGoals(userId, data);
  }
}
