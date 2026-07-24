import '../entities/weight_entry_entity.dart';

abstract class WeightRepository {
  Future<List<WeightEntryEntity>> getWeightEntries(String userId);
  Future<WeightEntryEntity> addWeightEntry(String userId, double weightKg, double? bmi, double? bodyFat, String? notes);
}