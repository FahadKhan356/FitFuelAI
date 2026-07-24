import '../entities/barcode_product_entity.dart';

abstract class BarcodeRepository {
  Future<BarcodeProductEntity?> getProductByBarcode(String barcode);
  Future<void> saveBarcodeProduct(Map<String, dynamic> data);
}