import '../entities/water_entry_entity.dart';

abstract class WaterRepository {
  Future<List<WaterEntryEntity>> getWaterEntries(String userId, DateTime date);
  Future<WaterEntryEntity> addWaterEntry(String userId, int amountMl, DateTime date);
  Future<void> deleteWaterEntry(String id);

  /// Get total water consumed for a date
  Future<int> getDailyWaterTotal(String userId, DateTime date);
}