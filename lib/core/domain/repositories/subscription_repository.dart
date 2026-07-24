import '../entities/barcode_product_entity.dart';

abstract class SubscriptionRepository {
  Future<bool> isSubscribed(String userId);
}