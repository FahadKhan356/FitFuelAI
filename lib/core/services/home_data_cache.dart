import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HomeCachedData {
  final String? name;
  final int targetCalories;
  final int consumedCalories;
  final int burnedCalories;
  final double targetProtein;
  final double consumedProtein;
  final double targetCarbs;
  final double consumedCarbs;
  final double targetFat;
  final double consumedFat;
  final int targetWaterMl;
  final int consumedWaterMl;

  /// The calendar day (`yyyy-MM-dd`) this cache snapshot was saved for. Used to
  /// invalidate stale data so a previous day's totals (e.g. consumed calories)
  /// are never shown as today's.
  final String savedAt;

  HomeCachedData({
    this.name,
    required this.targetCalories,
    this.consumedCalories = 0,
    this.burnedCalories = 0,
    required this.targetProtein,
    this.consumedProtein = 0.0,
    required this.targetCarbs,
    this.consumedCarbs = 0.0,
    required this.targetFat,
    this.consumedFat = 0.0,
    required this.targetWaterMl,
    this.consumedWaterMl = 0,
    String? savedAt,
  }) : savedAt = savedAt ?? '';

  /// True when this snapshot was saved for the current calendar day.
  bool get isCurrent => savedAt == HomeDataCache.todayStr();

  Map<String, dynamic> toJson() => {
        'name': name,
        'target_calories': targetCalories,
        'consumed_calories': consumedCalories,
        'burned_calories': burnedCalories,
        'target_protein': targetProtein,
        'consumed_protein': consumedProtein,
        'target_carbs': targetCarbs,
        'consumed_carbs': consumedCarbs,
        'target_fat': targetFat,
        'consumed_fat': consumedFat,
        'target_water_ml': targetWaterMl,
        'consumed_water_ml': consumedWaterMl,
        'saved_at': savedAt,
      };

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    return 0;
  }

  factory HomeCachedData.fromJson(Map<String, dynamic> json) => HomeCachedData(
        name: json['name'] as String?,
        targetCalories: _parseInt(json['target_calories']),
        consumedCalories: _parseInt(json['consumed_calories']),
        burnedCalories: _parseInt(json['burned_calories']),
        targetProtein: _parseDouble(json['target_protein']),
        consumedProtein: _parseDouble(json['consumed_protein']),
        targetCarbs: _parseDouble(json['target_carbs']),
        consumedCarbs: _parseDouble(json['consumed_carbs']),
        targetFat: _parseDouble(json['target_fat']),
        consumedFat: _parseDouble(json['consumed_fat']),
        targetWaterMl: _parseInt(json['target_water_ml']),
        consumedWaterMl: _parseInt(json['consumed_water_ml']),
        savedAt: json['saved_at'] as String?,
      );
}

class HomeDataCache {
  static final Map<String, HomeCachedData> _memoryCache = {};
  static const String _keyPrefix = 'home_data_cache_';

  /// Current calendar day as `yyyy-MM-dd` — matches the `date` column used for
  /// meals so the cache can never show a previous day's totals as today's.
  static String todayStr() => DateTime.now().toIso8601String().split('T').first;

  /// Synchronously retrieve cached data from memory, or null if not loaded or
  /// if the cached snapshot belongs to a different (previous) day.
  static HomeCachedData? getCached(String userId) {
    final data = _memoryCache[userId];
    if (data == null) return null;
    if (!data.isCurrent) {
      _memoryCache.remove(userId);
      return null;
    }
    return data;
  }

  /// Initialize and preload cache from persistent SharedPreferences for current user.
  /// Any snapshot saved for a previous day is ignored (and removed) so stale
  /// daily totals never appear on a fresh day.
  static Future<HomeCachedData?> loadPersistent(String userId) async {
    if (_memoryCache.containsKey(userId)) {
      return getCached(userId);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_keyPrefix$userId');
      if (raw != null && raw.isNotEmpty) {
        final data = HomeCachedData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (!data.isCurrent) {
          _memoryCache.remove(userId);
          await prefs.remove('$_keyPrefix$userId');
          return null;
        }
        _memoryCache[userId] = data;
        return data;
      }
    } catch (_) {}
    return null;
  }

  /// Save data to memory cache immediately and persist asynchronously.
  /// The snapshot is automatically tagged with the current day.
  static Future<void> save(String userId, HomeCachedData data) async {
    final current = HomeCachedData(
      name: data.name,
      targetCalories: data.targetCalories,
      consumedCalories: data.consumedCalories,
      burnedCalories: data.burnedCalories,
      targetProtein: data.targetProtein,
      consumedProtein: data.consumedProtein,
      targetCarbs: data.targetCarbs,
      consumedCarbs: data.consumedCarbs,
      targetFat: data.targetFat,
      consumedFat: data.consumedFat,
      targetWaterMl: data.targetWaterMl,
      consumedWaterMl: data.consumedWaterMl,
      savedAt: todayStr(),
    );
    _memoryCache[userId] = current;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyPrefix$userId', jsonEncode(current.toJson()));
    } catch (_) {}
  }

  /// Clear cache on sign out.
  static Future<void> clear(String userId) async {
    _memoryCache.remove(userId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keyPrefix$userId');
    } catch (_) {}
  }
}
