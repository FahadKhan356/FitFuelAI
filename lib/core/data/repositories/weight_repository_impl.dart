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
  Future<WeightEntryEntity> addWeightEntry(String userId, double weightKg, double heightCm, double? bodyFat, String? notes) async {
    // Auto-calculate BMI
    final heightM = heightCm / 100;
    final bmi = double.parse((weightKg / (heightM * heightM)).toStringAsFixed(1));

    // Insert into weight_entries
    final model = await _dataSource.addWeightEntry({
      'user_id': userId,
      'weight_kg': weightKg,
      'bmi': bmi,
      if (bodyFat != null) 'body_fat': bodyFat,
      if (notes != null) 'notes': notes,
    });

    // Sync current weight to user_profiles table
    await _dataSource.updateUserProfile(userId, {'weight_kg': weightKg});

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