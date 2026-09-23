import 'package:purchases_flutter/purchases_flutter.dart';

import '../../constants/app_constants.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/supabase_remote_datasource.dart';
import '../models/subscription_model.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SupabaseRemoteDataSource _dataSource;
  bool _revenueCatConfigured = false;

  SubscriptionRepositoryImpl(this._dataSource);

  bool get _useMockPurchases => AppConstants.subscriptionDevelopmentMode || AppConstants.revenueCatApiKey.trim().isEmpty;

  /// Configures RevenueCat only when a production API key is available.
  Future<void> initialize({required String userId}) async {
    if (_useMockPurchases || _revenueCatConfigured) return;
    await Purchases.configure(PurchasesConfiguration(AppConstants.revenueCatApiKey)..appUserID = userId);
    _revenueCatConfigured = true;
  }

  @override
  Future<SubscriptionModel?> getUserSubscription(String userId) => _dataSource.getSubscription(userId);

  @override
  Future<bool> isSubscribed(String userId) async => (await getUserSubscription(userId))?.isActive ?? false;

  @override
  Future<SubscriptionModel> purchasePackage({required String userId, required String plan}) async {
    if (_useMockPurchases) return _activateMockPremium(userId: userId, plan: plan);
    await initialize(userId: userId);
    final packages = (await Purchases.getOfferings()).current?.availablePackages ?? const <Package>[];
    Package? selectedPackage;
    for (final package in packages) {
      if (package.identifier == plan) {
        selectedPackage = package;
        break;
      }
    }
    selectedPackage ??= packages.isNotEmpty ? packages.first : null;
    if (selectedPackage == null) throw StateError('No RevenueCat package is configured for $plan.');
    await Purchases.purchasePackage(selectedPackage);
    return _saveActiveSubscription(userId: userId, plan: plan);
  }

  @override
  Future<SubscriptionModel?> restorePurchases(String userId) async {
    if (_useMockPurchases) return _activateMockPremium(userId: userId, plan: 'premium_yearly');
    await initialize(userId: userId);
    final customerInfo = await Purchases.restorePurchases();
    if (customerInfo.entitlements.active.isEmpty) return null;
    return _saveActiveSubscription(userId: userId, plan: 'premium_yearly');
  }

  /// Local-development fallback: writes the same Supabase record without a store transaction.
  Future<SubscriptionModel> _activateMockPremium({required String userId, required String plan}) => _saveActiveSubscription(userId: userId, plan: plan);

  Future<SubscriptionModel> _saveActiveSubscription({required String userId, required String plan}) async {
    final now = DateTime.now().toUtc();
    final expiresAt = plan == 'premium_lifetime' ? null : now.add(plan == 'premium_monthly' ? const Duration(days: 30) : const Duration(days: 365));
    await _dataSource.saveSubscription({'user_id': userId, 'plan': plan, 'status': 'active', 'started_at': now.toIso8601String(), if (expiresAt != null) 'expires_at': expiresAt.toIso8601String()});
    return (await getUserSubscription(userId)) ?? SubscriptionModel(id: userId, userId: userId, plan: plan, status: 'active', startedAt: now, expiresAt: expiresAt);
  }
}
