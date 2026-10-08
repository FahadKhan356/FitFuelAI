import '../../domain/entities/user_ai_limits_entity.dart';

class UserAiLimitsModel extends UserAiLimitsEntity {
  const UserAiLimitsModel({
    required super.userId,
    required super.planType,
    required super.dailyChatLimit,
    required super.dailyScanLimit,
    required super.chatsUsedToday,
    required super.scansUsedToday,
    required super.lastResetDate,
  });

  factory UserAiLimitsModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic val, int fallback) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? fallback;
      return fallback;
    }

    DateTime toDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return UserAiLimitsModel(
      userId: json['user_id']?.toString() ?? '',
      planType: json['plan_type']?.toString() ?? 'free',
      dailyChatLimit: toInt(json['daily_chat_limit'], 3),
      dailyScanLimit: toInt(json['daily_scan_limit'], 2),
      chatsUsedToday: toInt(json['chats_used_today'], 0),
      scansUsedToday: toInt(json['scans_used_today'], 0),
      lastResetDate: toDate(json['last_reset_date']),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'plan_type': planType,
        'daily_chat_limit': dailyChatLimit,
        'daily_scan_limit': dailyScanLimit,
        'chats_used_today': chatsUsedToday,
        'scans_used_today': scansUsedToday,
        'last_reset_date': lastResetDate.toIso8601String().split('T').first,
      };
}
