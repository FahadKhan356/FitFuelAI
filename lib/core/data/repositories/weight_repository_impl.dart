import '../../domain/entities/weight_entry_entity.dart';
import '../../domain/repositories/weight_repository.dart';
import '../datasources/supabase_remote_datasource.dart';

class WeightRepositoryImpl implements WeightRepository {
  final SupabaseRemoteDataSource _dataSource;

  WeightRepositoryImpl(this._dataSource);

  @override
  Future<List<WeightEntryEntity>> getWeightEntries(String userId) async {
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
  Future<WeightEntryEntity> addWeightEntry(String userId, double weightKg, double? bmi, double? bodyFat, String? notes) async {
    final model = await _dataSource.addWeightEntry({
      'user_id': userId,
      'weight_kg': weightKg,
      if (bmi != null) 'bmi': bmi,
      if (bodyFat != null) 'body_fat': bodyFat,
      if (notes != null) 'notes': notes,
    });
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