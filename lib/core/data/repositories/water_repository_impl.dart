import '../../domain/entities/water_entry_entity.dart';
import '../../domain/repositories/water_repository.dart';
import '../datasources/supabase_remote_datasource.dart';

class WaterRepositoryImpl implements WaterRepository {
  final SupabaseRemoteDataSource _dataSource;

  WaterRepositoryImpl(this._dataSource);

  @override
  Future<List<WaterEntryEntity>> getWaterEntries(String userId, DateTime date) async {
    final models = await _dataSource.getWaterEntries(userId, date);
    return models.map((m) => WaterEntryEntity(
      id: m.id,
      userId: m.userId,
      date: m.date,
      amountMl: m.amountMl,
      createdAt: m.createdAt,
    )).toList();
  }

  @override
  Future<WaterEntryEntity> addWaterEntry(String userId, int amountMl, DateTime date) async {
    final model = await _dataSource.addWaterEntry({
      'user_id': userId,
      'date': date.toIso8601String().split('T').first,
      'amount_ml': amountMl,
    });
    return WaterEntryEntity(
      id: model.id,
      userId: model.userId,
      date: model.date,
      amountMl: model.amountMl,
      createdAt: model.createdAt,
    );
  }
}