import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_ai_limits_entity.dart';
import '../../domain/repositories/ai_quota_repository.dart';
import '../models/user_ai_limits_model.dart';

class AiQuotaRepositoryImpl implements AiQuotaRepository {
  AiQuotaRepositoryImpl({
    SupabaseClient? client,
    SharedPreferences? prefs,
  })  : _client = client,
        _prefs = prefs;

  final SupabaseClient? _client;
  SharedPreferences? _prefs;

  SupabaseClient? get _effectiveClient {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  String _localDateStr() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  Future<UserAiLimitsEntity> getLimits(String userId) async {
    final localDate = _localDateStr();
    final client = _effectiveClient;

    // 1. Try remote RPC
    if (client != null) {
      try {
        final res = await client.rpc('get_user_ai_limits', params: {
          'p_user_id': userId,
          'p_local_date': localDate,
        });

        if (res != null && res is Map<String, dynamic>) {
          final model = UserAiLimitsModel.fromJson(res);
          await _saveLocalLimits(model);
          return model;
        }
      } catch (e) {
        debugPrint('AiQuotaRepository: RPC get_user_ai_limits failed ($e). Using local fallback.');
      }
    }

    // 2. Fallback to local cache or compute based on active subscriptions
    return _getLocalLimitsOrCompute(userId);
  }

  @override
  Future<QuotaCheckResult> checkAndConsumeQuota({
    required String userId,
    required String quotaType,
  }) async {
    final localDate = _localDateStr();
    final client = _effectiveClient;

    // 1. Try atomic Supabase RPC
    if (client != null) {
      try {
        final res = await client.rpc('check_and_consume_ai_quota', params: {
          'p_user_id': userId,
          'p_quota_type': quotaType,
          'p_local_date': localDate,
        });

        if (res != null && res is Map<String, dynamic>) {
          final result = QuotaCheckResult(
            allowed: res['allowed'] == true,
            quotaType: quotaType,
            usedToday: (res['used_today'] as num?)?.toInt() ?? 0,
            dailyLimit: (res['daily_limit'] as num?)?.toInt() ?? 0,
            remaining: (res['remaining'] as num?)?.toInt() ?? 0,
            planType: res['plan_type']?.toString() ?? 'free',
          );

          // Update local cache
          final current = await _getLocalLimitsOrCompute(userId);
          final updated = current.copyWith(
            planType: result.planType,
            chatsUsedToday: quotaType == 'chat' ? result.usedToday : current.chatsUsedToday,
            scansUsedToday: quotaType == 'scan' ? result.usedToday : current.scansUsedToday,
            dailyChatLimit: quotaType == 'chat' ? result.dailyLimit : current.dailyChatLimit,
            dailyScanLimit: quotaType == 'scan' ? result.dailyLimit : current.dailyScanLimit,
            lastResetDate: DateTime.now(),
          );
          await _saveLocalLimits(updated);

          return result;
        }
      } catch (e) {
        debugPrint('AiQuotaRepository: RPC check_and_consume_ai_quota unavailable ($e). Falling back to local check.');
      }
    }

    // 2. Resilient local quota evaluation
    final current = await _getLocalLimitsOrCompute(userId);
    final isChat = quotaType == 'chat';
    final limit = isChat ? current.dailyChatLimit : current.dailyScanLimit;
    final used = isChat ? current.chatsUsedToday : current.scansUsedToday;

    if (used < limit) {
      final newUsed = used + 1;
      final updated = current.copyWith(
        chatsUsedToday: isChat ? newUsed : current.chatsUsedToday,
        scansUsedToday: !isChat ? newUsed : current.scansUsedToday,
        lastResetDate: DateTime.now(),
      );
      await _saveLocalLimits(updated);

      // Best effort remote sync
      _tryUpdateRemoteLimits(updated);

      return QuotaCheckResult(
        allowed: true,
        quotaType: quotaType,
        usedToday: newUsed,
        dailyLimit: limit,
        remaining: (limit - newUsed).clamp(0, limit),
        planType: current.planType,
      );
    } else {
      return QuotaCheckResult(
        allowed: false,
        quotaType: quotaType,
        usedToday: used,
        dailyLimit: limit,
        remaining: 0,
        planType: current.planType,
      );
    }
  }

  @override
  Future<void> syncPlanTier({
    required String userId,
    required String planType,
  }) async {
    final int chatLimit;
    final int scanLimit;

    if (planType == 'monthly' ||
        planType == 'premium_monthly' ||
        planType == 'annual' ||
        planType == 'premium_yearly' ||
        planType == 'yearly') {
      chatLimit = 100;
      scanLimit = 30;
    } else if (planType == 'lifetime' || planType == 'premium_lifetime') {
      chatLimit = 50;
      scanLimit = 20;
    } else {
      chatLimit = 3;
      scanLimit = 2;
    }

    final current = await _getLocalLimitsOrCompute(userId);
    final updated = current.copyWith(
      planType: planType,
      dailyChatLimit: chatLimit,
      dailyScanLimit: scanLimit,
    );
    await _saveLocalLimits(updated);

    _tryUpdateRemoteLimits(updated);
  }

  // ── Local Storage Helpers ──

  Future<void> _saveLocalLimits(UserAiLimitsEntity entity) async {
    try {
      final prefs = await _getPrefs();
      final key = 'ai_limits_${entity.userId}';
      final jsonStr = jsonEncode({
        'user_id': entity.userId,
        'plan_type': entity.planType,
        'daily_chat_limit': entity.dailyChatLimit,
        'daily_scan_limit': entity.dailyScanLimit,
        'chats_used_today': entity.chatsUsedToday,
        'scans_used_today': entity.scansUsedToday,
        'last_reset_date': _localDateStr(),
      });
      await prefs.setString(key, jsonStr);
    } catch (_) {}
  }

  Future<UserAiLimitsEntity> _getLocalLimitsOrCompute(String userId) async {
    try {
      final prefs = await _getPrefs();
      final key = 'ai_limits_$userId';
      final jsonStr = prefs.getString(key);

      if (jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final lastReset = map['last_reset_date']?.toString();
        final today = _localDateStr();

        // Daily 24-hr reset check
        if (lastReset != today) {
          map['chats_used_today'] = 0;
          map['scans_used_today'] = 0;
          map['last_reset_date'] = today;
        }

        return UserAiLimitsModel.fromJson(map);
      }
    } catch (_) {}

    return UserAiLimitsEntity.freeDefault(userId);
  }

  void _tryUpdateRemoteLimits(UserAiLimitsEntity entity) {
    final client = _effectiveClient;
    if (client == null) return;
    try {
      client.from('user_ai_limits').upsert({
        'user_id': entity.userId,
        'plan_type': entity.planType,
        'daily_chat_limit': entity.dailyChatLimit,
        'daily_scan_limit': entity.dailyScanLimit,
        'chats_used_today': entity.chatsUsedToday,
        'scans_used_today': entity.scansUsedToday,
        'last_reset_date': _localDateStr(),
      }).then((_) {}).catchError((_) {});
    } catch (_) {}
  }
}
