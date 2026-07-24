import '../../data/models/subscription_model.dart';

abstract class SubscriptionRepository {
  Future<SubscriptionModel?> getUserSubscription(String userId);
  Future<bool> isSubscribed(String userId);
}
