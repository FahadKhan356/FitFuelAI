import '../entities/user_ai_limits_entity.dart';

abstract class AiQuotaRepository {
  /// Fetches current AI quotas and usage without consuming.
  Future<UserAiLimitsEntity> getLimits(String userId);

  /// Atomically checks whether the user has remaining quota for [quotaType]
  /// ('chat' or 'scan'). If allowed, increments consumption by 1 and returns result.
  Future<QuotaCheckResult> checkAndConsumeQuota({
    required String userId,
    required String quotaType,
  });

  /// Syncs user limits record when a subscription is purchased or updated.
  Future<void> syncPlanTier({
    required String userId,
    required String planType,
  });
}
