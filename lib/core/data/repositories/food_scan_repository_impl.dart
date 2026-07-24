import '../../domain/entities/food_scan_result_entity.dart';
import '../../domain/repositories/food_scan_repository.dart';
import '../datasources/supabase_remote_datasource.dart';

class FoodScanRepositoryImpl implements FoodScanRepository {
  final SupabaseRemoteDataSource _dataSource;

  FoodScanRepositoryImpl(this._dataSource);

  @override
  Future<FoodScanResultEntity> saveScanResult({
    required String userId,
    required String imageUrl,
    required Map<String, dynamic> rawResult,
    required double confidence,
  }) async {
    final model = await _dataSource.saveScanResult({
      'user_id': userId,
      'scan_image_url': imageUrl,
      'scan_result': rawResult,
      'confidence': confidence,
    });
    return FoodScanResultEntity(
      id: model.id,
      userId: model.userId,
      scanImageUrl: model.scanImageUrl,
      scanResult: model.scanResult,
      confidence: model.confidence,
      scanType: model.scanType,
      createdAt: model.createdAt,
    );
  }

  @override
  Future<List<FoodScanResultEntity>> getScanHistory(String userId) async {
    final models = await _dataSource.getScanHistory(userId);
    return models.map((m) => FoodScanResultEntity(
      id: m.id,
      userId: m.userId,
      scanImageUrl: m.scanImageUrl,
      scanResult: m.scanResult,
      confidence: m.confidence,
      scanType: m.scanType,
      createdAt: m.createdAt,
    )).toList();
  }
}