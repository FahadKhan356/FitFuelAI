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

  const HomeCachedData({
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
  });

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
        targetCalories: _parseInt(json['target_calories']) == 0 ? 2000 : _parseInt(json['target_calories']),
        consumedCalories: _parseInt(json['consumed_calories']),
        burnedCalories: _parseInt(json['burned_calories']),
        targetProtein: _parseDouble(json['target_protein']),
        consumedProtein: _parseDouble(json['consumed_protein']),
        targetCarbs: _parseDouble(json['target_carbs']),
        consumedCarbs: _parseDouble(json['consumed_carbs']),
        targetFat: _parseDouble(json['target_fat']),
        consumedFat: _parseDouble(json['consumed_fat']),
        targetWaterMl: _parseInt(json['target_water_ml']) == 0 ? 2000 : _parseInt(json['target_water_ml']),
        consumedWaterMl: _parseInt(json['consumed_water_ml']),
      );
}

class HomeDataCache {
  static final Map<String, HomeCachedData> _memoryCache = {};
  static const String _keyPrefix = 'home_data_cache_';

  /// Synchronously retrieve cached data from memory or null if not yet loaded.
  static HomeCachedData? getCached(String userId) {
    return _memoryCache[userId];
  }

  /// Initialize and preload cache from persistent SharedPreferences for current user.
  static Future<HomeCachedData?> loadPersistent(String userId) async {
    if (_memoryCache.containsKey(userId)) {
      return _memoryCache[userId];
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_keyPrefix$userId');
      if (raw != null && raw.isNotEmpty) {
        final data = HomeCachedData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        _memoryCache[userId] = data;
        return data;
      }
    } catch (_) {}
    return null;
  }

  /// Save data to memory cache immediately and persist asynchronously.
  static Future<void> save(String userId, HomeCachedData data) async {
    _memoryCache[userId] = data;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyPrefix$userId', jsonEncode(data.toJson()));
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
