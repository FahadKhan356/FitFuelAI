import 'package:flutter_test/flutter_test.dart';
import 'package:fitfuel_ai/core/domain/entities/user_ai_limits_entity.dart';
import 'package:fitfuel_ai/core/data/models/user_ai_limits_model.dart';
import 'package:fitfuel_ai/core/domain/repositories/ai_coach_repository.dart';
import 'package:fitfuel_ai/core/domain/repositories/ai_quota_repository.dart';
import 'package:fitfuel_ai/core/domain/entities/ai_chat_message_entity.dart';
import 'package:fitfuel_ai/core/data/repositories/ai_quota_repository_impl.dart';
import 'package:fitfuel_ai/features/ai_coach/presentation/bloc/ai_coach_bloc.dart';
import 'package:fitfuel_ai/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:fitfuel_ai/core/domain/repositories/subscription_repository.dart';
import 'package:fitfuel_ai/core/data/models/subscription_model.dart';
import 'package:fitfuel_ai/core/domain/entities/coach_insight.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAiCoachRepository implements AiCoachRepository {
  int sendCount = 0;

  @override
  Future<String> generateCoachReply(
    String userId,
    String prompt, {
    CoachInsight? insight,
  }) async {
    return 'Here is your personalized nutrition advice!';
  }

  @override
  Future<void> sendMessage(String userId, String userMessage, String aiResponse) async {
    sendCount++;
  }

  @override
  Future<List<AiChatMessageEntity>> getChatHistory(String userId) async {
    return [];
  }
}

class FakeAiQuotaRepository implements AiQuotaRepository {
  UserAiLimitsEntity limits;
  int checkCount = 0;
  String? lastSyncedPlan;

  FakeAiQuotaRepository({required this.limits});

  @override
  Future<UserAiLimitsEntity> getLimits(String userId) async {
    return limits;
  }

  @override
  Future<QuotaCheckResult> checkAndConsumeQuota({
    required String userId,
    required String quotaType,
  }) async {
    checkCount++;
    if (quotaType == 'chat') {
      if (limits.chatsUsedToday >= limits.dailyChatLimit) {
        return QuotaCheckResult(
          allowed: false,
          quotaType: quotaType,
          usedToday: limits.chatsUsedToday,
          dailyLimit: limits.dailyChatLimit,
          remaining: 0,
          planType: limits.planType,
        );
      }
      limits = limits.copyWith(chatsUsedToday: limits.chatsUsedToday + 1);
      return QuotaCheckResult(
        allowed: true,
        quotaType: quotaType,
        usedToday: limits.chatsUsedToday,
        dailyLimit: limits.dailyChatLimit,
        remaining: limits.chatsRemaining,
        planType: limits.planType,
      );
    } else {
      if (limits.scansUsedToday >= limits.dailyScanLimit) {
        return QuotaCheckResult(
          allowed: false,
          quotaType: quotaType,
          usedToday: limits.scansUsedToday,
          dailyLimit: limits.dailyScanLimit,
          remaining: 0,
          planType: limits.planType,
        );
      }
      limits = limits.copyWith(scansUsedToday: limits.scansUsedToday + 1);
      return QuotaCheckResult(
        allowed: true,
        quotaType: quotaType,
        usedToday: limits.scansUsedToday,
        dailyLimit: limits.dailyScanLimit,
        remaining: limits.scansRemaining,
        planType: limits.planType,
      );
    }
  }

  @override
  Future<void> syncPlanTier({
    required String userId,
    required String planType,
  }) async {
    lastSyncedPlan = planType;
    int chatLimit = 3;
    int scanLimit = 2;
    if (planType.contains('lifetime')) {
      chatLimit = 50;
      scanLimit = 20;
    } else if (planType.contains('month') || planType.contains('year') || planType.contains('annual')) {
      chatLimit = 100;
      scanLimit = 30;
    }
    limits = limits.copyWith(
      planType: planType,
      dailyChatLimit: chatLimit,
      dailyScanLimit: scanLimit,
    );
  }
}

class FakeSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<SubscriptionModel?> getUserSubscription(String userId) async {
    return null;
  }

  @override
  Future<bool> isSubscribed(String userId) async => true;

  @override
  Future<SubscriptionModel> purchasePackage({
    required String userId,
    required String plan,
  }) async {
    return SubscriptionModel(
      id: 'sub-test',
      userId: userId,
      plan: plan,
      status: 'active',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  @override
  Future<SubscriptionModel?> restorePurchases(String userId) async {
    return SubscriptionModel(
      id: 'sub-restore',
      userId: userId,
      plan: 'premium_monthly',
      status: 'active',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }
}

void main() {
  group('UserAiLimitsEntity Unit Tests', () {
    test('Free tier defaults: 3 chats / 2 scans per day', () {
      final freeLimits = UserAiLimitsEntity.freeDefault('user-123');
      expect(freeLimits.dailyChatLimit, 3);
      expect(freeLimits.dailyScanLimit, 2);
      expect(freeLimits.chatsUsedToday, 0);
      expect(freeLimits.scansUsedToday, 0);
      expect(freeLimits.chatsRemaining, 3);
      expect(freeLimits.scansRemaining, 2);
      expect(freeLimits.isChatLimitReached, false);
      expect(freeLimits.isScanLimitReached, false);
      expect(freeLimits.isPremium, false);
    });

    test('Chat and scan remaining calculations clamp to 0', () {
      final exhausted = UserAiLimitsEntity(
        userId: 'user-123',
        planType: 'free',
        dailyChatLimit: 3,
        dailyScanLimit: 2,
        chatsUsedToday: 5,
        scansUsedToday: 3,
        lastResetDate: DateTime(2026, 10, 8),
      );
      expect(exhausted.chatsRemaining, 0);
      expect(exhausted.scansRemaining, 0);
      expect(exhausted.isChatLimitReached, true);
      expect(exhausted.isScanLimitReached, true);
    });

    test('Premium tier detection', () {
      final monthly = UserAiLimitsEntity(
        userId: 'user-123',
        planType: 'monthly',
        dailyChatLimit: 100,
        dailyScanLimit: 30,
        chatsUsedToday: 10,
        scansUsedToday: 5,
        lastResetDate: DateTime(2026, 10, 8),
      );
      expect(monthly.isPremium, true);
      expect(monthly.chatsRemaining, 90);
      expect(monthly.scansRemaining, 25);
    });
  });

  group('UserAiLimitsModel Serialization', () {
    test('fromJson and toJson round trip', () {
      final json = {
        'user_id': 'u-99',
        'plan_type': 'lifetime',
        'daily_chat_limit': 50,
        'daily_scan_limit': 20,
        'chats_used_today': 12,
        'scans_used_today': 4,
        'last_reset_date': '2026-10-08',
      };
      final model = UserAiLimitsModel.fromJson(json);
      expect(model.userId, 'u-99');
      expect(model.planType, 'lifetime');
      expect(model.dailyChatLimit, 50);
      expect(model.dailyScanLimit, 20);
      expect(model.chatsUsedToday, 12);
      expect(model.scansUsedToday, 4);

      final out = model.toJson();
      expect(out['user_id'], 'u-99');
      expect(out['plan_type'], 'lifetime');
      expect(out['daily_chat_limit'], 50);
    });

    test('fromJson fallback with missing or partial data', () {
      final model = UserAiLimitsModel.fromJson({'user_id': 'fallback-user'});
      expect(model.userId, 'fallback-user');
      expect(model.planType, 'free');
      expect(model.dailyChatLimit, 3);
      expect(model.dailyScanLimit, 2);
    });
  });

  group('AiQuotaRepositoryImpl Local Resilience & 24h Reset', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Local fallback resets counters when local date changes', () async {
      final repo = AiQuotaRepositoryImpl();

      // Day 1: Consume 3 chats (reaching limit)
      await repo.checkAndConsumeQuota(userId: 'test-user', quotaType: 'chat');
      await repo.checkAndConsumeQuota(userId: 'test-user', quotaType: 'chat');
      final result3 = await repo.checkAndConsumeQuota(userId: 'test-user', quotaType: 'chat');
      expect(result3.allowed, true);
      expect(result3.usedToday, 3);

      // 4th attempt on Day 1 is blocked
      final blocked = await repo.checkAndConsumeQuota(userId: 'test-user', quotaType: 'chat');
      expect(blocked.allowed, false);
      expect(blocked.usedToday, 3);

      // Simulate next calendar day by setting lastResetDate in SharedPreferences to yesterday
      final prefs = await SharedPreferences.getInstance();
      const key = 'ai_limits_test-user';
      final cachedJson = prefs.getString(key);
      expect(cachedJson, isNotNull);

      final modifiedJson = cachedJson!.replaceAll(RegExp(r'"last_reset_date":"[^"]+"'), '"last_reset_date":"2020-01-01"');
      await prefs.setString(key, modifiedJson);

      // Next call detects new date and resets counters
      final newDayResult = await repo.checkAndConsumeQuota(userId: 'test-user', quotaType: 'chat');
      expect(newDayResult.allowed, true);
      expect(newDayResult.usedToday, 1);
    });

    test('syncPlanTier updates limits to 100/30 for annual and 50/20 for lifetime', () async {
      final repo = AiQuotaRepositoryImpl();

      await repo.syncPlanTier(userId: 'u1', planType: 'premium_yearly');
      final limitsYearly = await repo.getLimits('u1');
      expect(limitsYearly.dailyChatLimit, 100);
      expect(limitsYearly.dailyScanLimit, 30);
      expect(limitsYearly.isPremium, true);

      await repo.syncPlanTier(userId: 'u1', planType: 'premium_lifetime');
      final limitsLifetime = await repo.getLimits('u1');
      expect(limitsLifetime.dailyChatLimit, 50);
      expect(limitsLifetime.dailyScanLimit, 20);
    });
  });

  group('AiCoachBloc Quota Enforcement & States', () {
    test('SendMessage succeeds and increments quota when under limit', () async {
      final fakeQuota = FakeAiQuotaRepository(
        limits: UserAiLimitsEntity.freeDefault('user-test'),
      );
      final fakeCoach = FakeAiCoachRepository();

      final bloc = AiCoachBloc(
        aiCoachRepository: fakeCoach,
        aiQuotaRepository: fakeQuota,
      );

      final states = <AiCoachState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const SendMessage('user-test', 'How many grams of protein should I eat?'));
      await pumpEventQueue();

      expect(states, [
        isA<AiCoachLoading>(),
        isA<AiCoachMessageSent>(),
      ]);
      expect(fakeQuota.limits.chatsUsedToday, 1);
      expect(fakeCoach.sendCount, 1);

      await sub.cancel();
      await bloc.close();
    });

    test('SendMessage blocks and emits AiQuotaExceededState when 3 chat limit reached', () async {
      final fakeQuota = FakeAiQuotaRepository(
        limits: UserAiLimitsEntity(
          userId: 'user-test',
          planType: 'free',
          dailyChatLimit: 3,
          dailyScanLimit: 2,
          chatsUsedToday: 3, // Already reached limit
          scansUsedToday: 0,
          lastResetDate: DateTime(2026, 10, 8),
        ),
      );
      final fakeCoach = FakeAiCoachRepository();

      final bloc = AiCoachBloc(
        aiCoachRepository: fakeCoach,
        aiQuotaRepository: fakeQuota,
      );

      final states = <AiCoachState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const SendMessage('user-test', 'Give me lunch ideas'));
      await pumpEventQueue();

      expect(states.length, 1);
      expect(states.first, isA<AiQuotaExceededState>());
      final quotaState = states.first as AiQuotaExceededState;
      expect(quotaState.quotaType, 'chat');
      expect(quotaState.usedToday, 3);
      expect(quotaState.dailyLimit, 3);
      expect(quotaState.planType, 'free');

      // Coach repository was not called
      expect(fakeCoach.sendCount, 0);

      await sub.cancel();
      await bloc.close();
    });

    test('CheckAiQuota event emits AiQuotaLoaded with remaining counts', () async {
      final fakeQuota = FakeAiQuotaRepository(
        limits: UserAiLimitsEntity(
          userId: 'user-test',
          planType: 'monthly',
          dailyChatLimit: 100,
          dailyScanLimit: 30,
          chatsUsedToday: 15,
          scansUsedToday: 5,
          lastResetDate: DateTime(2026, 10, 8),
        ),
      );
      final fakeCoach = FakeAiCoachRepository();

      final bloc = AiCoachBloc(
        aiCoachRepository: fakeCoach,
        aiQuotaRepository: fakeQuota,
      );

      final states = <AiCoachState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const CheckAiQuota('user-test'));
      await pumpEventQueue();

      expect(states.length, 1);
      expect(states.first, isA<AiQuotaLoaded>());
      final loadedState = states.first as AiQuotaLoaded;
      expect(loadedState.chatsRemaining, 85);
      expect(loadedState.scansRemaining, 25);
      expect(loadedState.planType, 'monthly');

      await sub.cancel();
      await bloc.close();
    });
  });

  group('SubscriptionBloc Quota Sync Integration', () {
    test('PurchasePlanRequested triggers syncPlanTier in AiQuotaRepository', () async {
      final fakeQuota = FakeAiQuotaRepository(
        limits: UserAiLimitsEntity.freeDefault('user-test'),
      );
      final fakeSubRepo = FakeSubscriptionRepository();

      final bloc = SubscriptionBloc(
        subscriptionRepository: fakeSubRepo,
        aiQuotaRepository: fakeQuota,
      );

      bloc.add(const PurchasePlanRequested(userId: 'user-test', plan: 'premium_yearly'));
      await pumpEventQueue();

      expect(fakeQuota.lastSyncedPlan, 'premium_yearly');
      expect(fakeQuota.limits.dailyChatLimit, 100);
      expect(fakeQuota.limits.dailyScanLimit, 30);

      await bloc.close();
    });
  });
}
