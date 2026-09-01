import 'package:flutter/foundation.dart';

import '../../domain/entities/weight_entry_entity.dart';
import '../../domain/repositories/weight_repository.dart';
import '../datasources/supabase_remote_datasource.dart';

class WeightRepositoryImpl implements WeightRepository {
  final SupabaseRemoteDataSource _dataSource;

  WeightRepositoryImpl(this._dataSource);

  @override
  Future<List<WeightEntryEntity>> getWeightHistory(String userId) async {
    final models = await _dataSource.getWeightEntries(userId);
    return models.map((m) => WeightEntryEntity(
      id: m.id,
      userId: m.userId,
      date: m.date,
      weightKg: m.weightKg,
      bmi: m.bmi,
      bodyFat: m.bodyFat,
      notes: m.notes,
      createdAt: m.createdAt,
    )).toList();
  }

  @override
  Future<WeightEntryEntity> addWeightEntry(String userId, DateTime date, double weightKg, double heightCm, double? bodyFat, String? notes) async {
    // Auto-calculate BMI
    final heightM = heightCm / 100;
    final bmi = double.parse((weightKg / (heightM * heightM)).toStringAsFixed(1));

    // Insert into weight_entries (date is NOT NULL — must be forwarded so the
    // entry is stored on the exact day the user picked).
    final model = await _dataSource.addWeightEntry({
      'user_id': userId,
      'date': date.toIso8601String().split('T').first,
      'weight_kg': weightKg,
      'bmi': bmi,
      if (bodyFat != null) 'body_fat': bodyFat,
      if (notes != null) 'notes': notes,
    });

    // Sync current weight to user_profiles. `weight_kg` stays the starting
    // weight; the live value goes in `current_weight` (falls back to setting
    // weight_kg when the dedicated column predates this change).
    await _dataSource.updateUserProfile(userId, {'current_weight': weightKg});

    // Recompute nutrition targets (calories / protein / carbs / fat / water)
    // from the newly-synced weight. The `calculate_user_goals` RPC reads
    // `user_profiles` and rewrites the `goals` row — exactly like onboarding
    // does — so home, health-goals, calorie & water resolvers, and the calendar
    // all pick up the fresh targets based on the current weight.
    // Non-fatal: the weight entry + profile sync below already succeeded, so a
    // goal-recalc failure must never block logging a weight.
    try {
      await _dataSource.calculateUserGoals(userId);
    } catch (e) {
      debugPrint('addWeightEntry calculateUserGoals error: $e');
    }

    return WeightEntryEntity(
      id: model.id,
      userId: model.userId,
      date: model.date,
      weightKg: model.weightKg,
      bmi: model.bmi,
      bodyFat: model.bodyFat,
      notes: model.notes,
      createdAt: model.createdAt,
    );
  }
}