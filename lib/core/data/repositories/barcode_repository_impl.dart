import '../../domain/entities/barcode_product_entity.dart';
import '../../domain/repositories/barcode_repository.dart';
import '../datasources/supabase_remote_datasource.dart';

class BarcodeRepositoryImpl implements BarcodeRepository {
  final SupabaseRemoteDataSource _dataSource;

  BarcodeRepositoryImpl(this._dataSource);

  @override
  Future<BarcodeProductEntity?> getProductByBarcode(String barcode) async {
    final model = await _dataSource.getProductByBarcode(barcode);
    if (model == null) return null;
    return BarcodeProductEntity(
      id: model.id,
      barcode: model.barcode,
      productName: model.productName,
      brand: model.brand,
      calories: model.calories,
      nutritionData: model.nutritionData,
      source: model.source,
      createdAt: model.createdAt,
    );
  }

  @override
  Future<void> saveBarcodeProduct(Map<String, dynamic> data) async {
    await _dataSource.saveBarcodeProduct(data);
  }
}