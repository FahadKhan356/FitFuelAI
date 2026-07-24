import '../entities/food_scan_result_entity.dart';

abstract class FoodScanRepository {
  /// Save a food scan result into food_scans table
  Future<FoodScanResultEntity> saveScanResult({
    required String userId,
    required String imageUrl,
    required Map<String, dynamic> rawResult,
    required double confidence,
  });

  /// Fetch past scan history for a user
  Future<List<FoodScanResultEntity>> getScanHistory(String userId);
}