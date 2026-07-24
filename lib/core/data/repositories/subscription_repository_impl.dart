import '../../domain/repositories/subscription_repository.dart';
import '../../data/models/subscription_model.dart';
import '../datasources/supabase_remote_datasource.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SupabaseRemoteDataSource _dataSource;

  SubscriptionRepositoryImpl(this._dataSource);

  @override
  Future<SubscriptionModel?> getUserSubscription(String userId) async {
    return await _dataSource.getSubscription(userId);
  }

  @override
  Future<bool> isSubscribed(String userId) async {
    final subscription = await _dataSource.getSubscription(userId);
    if (subscription == null) return false;
    
    // Check if subscription is active and not expired
    final now = DateTime.now();
    if (!subscription.isActive) return false;
    if (subscription.endDate != null && subscription.endDate!.isBefore(now)) return false;
    
    return true;
  }
}