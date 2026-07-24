import '../entities/food_scan_result_entity.dart';

abstract class FoodScanRepository {
  Future<FoodScanResultEntity> saveScanResult(Map<String, dynamic> data);
}