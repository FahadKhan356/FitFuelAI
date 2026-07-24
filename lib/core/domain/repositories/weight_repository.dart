import '../entities/weight_entry_entity.dart';

abstract class WeightRepository {
  Future<List<WeightEntryEntity>> getWeightHistory(String userId);
  Future<WeightEntryEntity> addWeightEntry(String userId, double weightKg, double heightCm, double? bodyFat, String? notes);
}