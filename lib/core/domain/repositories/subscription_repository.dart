import '../../data/models/subscription_model.dart';

abstract class SubscriptionRepository {
  Future<SubscriptionModel?> getUserSubscription(String userId);
  Future<bool> isSubscribed(String userId);
  Future<SubscriptionModel> purchasePackage({required String userId, required String plan});
  Future<SubscriptionModel?> restorePurchases(String userId);
}
