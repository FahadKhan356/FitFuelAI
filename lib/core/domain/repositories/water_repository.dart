import '../entities/water_entry_entity.dart';

abstract class WaterRepository {
  Future<List<WaterEntryEntity>> getWaterEntries(String userId, DateTime date);
  Future<WaterEntryEntity> addWaterEntry(String userId, int amountMl, DateTime date);
  Future<void> deleteWaterEntry(String id);

  /// Get total water consumed for a date
  Future<int> getDailyWaterTotal(String userId, DateTime date);

  /// Total water consumed per date within a range. Key = 'yyyy-MM-dd'.
  Future<Map<String, int>> getWaterTotalsByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  );
}