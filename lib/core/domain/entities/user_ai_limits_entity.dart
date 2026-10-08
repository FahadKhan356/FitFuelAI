import 'package:equatable/equatable.dart';

/// Entity representing daily AI quotas and usage consumption.
class UserAiLimitsEntity extends Equatable {
  const UserAiLimitsEntity({
    required this.userId,
    required this.planType,
    required this.dailyChatLimit,
    required this.dailyScanLimit,
    required this.chatsUsedToday,
    required this.scansUsedToday,
    required this.lastResetDate,
  });

  final String userId;
  final String planType; // 'free', 'monthly', 'annual', 'lifetime'
  final int dailyChatLimit;
  final int dailyScanLimit;
  final int chatsUsedToday;
  final int scansUsedToday;
  final DateTime lastResetDate;

  int get chatsRemaining => (dailyChatLimit - chatsUsedToday).clamp(0, dailyChatLimit);
  int get scansRemaining => (dailyScanLimit - scansUsedToday).clamp(0, dailyScanLimit);

  bool get isChatLimitReached => chatsUsedToday >= dailyChatLimit;
  bool get isScanLimitReached => scansUsedToday >= dailyScanLimit;

  bool get isPremium => planType != 'free';

  UserAiLimitsEntity copyWith({
    String? userId,
    String? planType,
    int? dailyChatLimit,
    int? dailyScanLimit,
    int? chatsUsedToday,
    int? scansUsedToday,
    DateTime? lastResetDate,
  }) {
    return UserAiLimitsEntity(
      userId: userId ?? this.userId,
      planType: planType ?? this.planType,
      dailyChatLimit: dailyChatLimit ?? this.dailyChatLimit,
      dailyScanLimit: dailyScanLimit ?? this.dailyScanLimit,
      chatsUsedToday: chatsUsedToday ?? this.chatsUsedToday,
      scansUsedToday: scansUsedToday ?? this.scansUsedToday,
      lastResetDate: lastResetDate ?? this.lastResetDate,
    );
  }

  factory UserAiLimitsEntity.freeDefault(String userId) => UserAiLimitsEntity(
        userId: userId,
        planType: 'free',
        dailyChatLimit: 3,
        dailyScanLimit: 2,
        chatsUsedToday: 0,
        scansUsedToday: 0,
        lastResetDate: DateTime.now(),
      );

  @override
  List<Object?> get props => [
        userId,
        planType,
        dailyChatLimit,
        dailyScanLimit,
        chatsUsedToday,
        scansUsedToday,
        lastResetDate,
      ];
}

/// Result of an atomic check-and-consume quota operation.
class QuotaCheckResult extends Equatable {
  const QuotaCheckResult({
    required this.allowed,
    required this.quotaType,
    required this.usedToday,
    required this.dailyLimit,
    required this.remaining,
    required this.planType,
  });

  final bool allowed;
  final String quotaType; // 'chat' or 'scan'
  final int usedToday;
  final int dailyLimit;
  final int remaining;
  final String planType;

  @override
  List<Object?> get props => [
        allowed,
        quotaType,
        usedToday,
        dailyLimit,
        remaining,
        planType,
      ];
}
