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
  Future<void> saveBarcodeProduct(BarcodeProductEntity product) async {
    await _dataSource.saveBarcodeProduct({
      'barcode': product.barcode,
      'product_name': product.productName,
      if (product.brand != null) 'brand': product.brand,
      if (product.calories != null) 'calories': product.calories,
      if (product.nutritionData != null) 'nutrition_data': product.nutritionData,
      'source': product.source,
    });
  }
}