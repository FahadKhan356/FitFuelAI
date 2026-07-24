import '../../domain/entities/food_scan_result_entity.dart';
import '../../domain/repositories/food_scan_repository.dart';
import '../datasources/supabase_remote_datasource.dart';

class FoodScanRepositoryImpl implements FoodScanRepository {
  final SupabaseRemoteDataSource _dataSource;

  FoodScanRepositoryImpl(this._dataSource);

  @override
  Future<FoodScanResultEntity> saveScanResult(Map<String, dynamic> data) async {
    final model = await _dataSource.saveScanResult(data);
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
}