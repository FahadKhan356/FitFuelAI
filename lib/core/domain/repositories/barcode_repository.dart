import '../entities/barcode_product_entity.dart';

abstract class BarcodeRepository {
  /// Query Supabase barcode_products table first. Returns null if not found.
  Future<BarcodeProductEntity?> getProductByBarcode(String barcode);

  /// Upsert product details into barcode_products table.
  Future<void> saveBarcodeProduct(BarcodeProductEntity product);
}