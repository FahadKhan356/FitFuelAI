import '../entities/water_entry_entity.dart';

abstract class WaterRepository {
  Future<List<WaterEntryEntity>> getWaterEntries(String userId, DateTime date);
  Future<WaterEntryEntity> addWaterEntry(String userId, int amountMl, DateTime date);
}