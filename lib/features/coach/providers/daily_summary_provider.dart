import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Single source of truth for daily metrics across Home, Coach, Stats and Profile.
class DailySummary {
  const DailySummary({
    required this.caloriesConsumed,
    required this.caloriesGoal,
    required this.waterMl,
    required this.waterGoalMl,
    required this.proteinG,
    required this.proteinGoalG,
    required this.carbsG,
    required this.carbsGoalG,
    required this.fatsG,
    required this.fatsGoalG,
    required this.streakDays,
    required this.lastSyncedAt,
    this.isSyncing = false,
  });

  final int caloriesConsumed;
  final int caloriesGoal;
  final int waterMl;
  final int waterGoalMl;
  final double proteinG;
  final double proteinGoalG;
  final double carbsG;
  final double carbsGoalG;
  final double fatsG;
  final double fatsGoalG;
  final int streakDays;
  final DateTime lastSyncedAt;
  final bool isSyncing;
  bool get isLoading => isSyncing;

  factory DailySummary.initial() => DailySummary(
        caloriesConsumed: 0,
        caloriesGoal: 2000,
        waterMl: 0,
        waterGoalMl: 2500,
        proteinG: 0,
        proteinGoalG: 140,
        carbsG: 0,
        carbsGoalG: 250,
        fatsG: 0,
        fatsGoalG: 65,
        streakDays: 1,
        lastSyncedAt: DateTime.now(),
        isSyncing: true,
      );

  factory DailySummary.fromJson(Map<String, dynamic> json, {bool isSyncing = false}) =>
      DailySummary(
        caloriesConsumed: _toInt(json['calories_consumed']),
        caloriesGoal: _toInt(json['calories_goal'], fallback: 2000),
        waterMl: _toInt(json['water_ml']),
        waterGoalMl: _toInt(json['water_goal_ml'], fallback: 2500),
        proteinG: _toDouble(json['protein_g']),
        proteinGoalG: _toDouble(json['protein_goal_g'], fallback: 140),
        carbsG: _toDouble(json['carbs_g']),
        carbsGoalG: _toDouble(json['carbs_goal_g'], fallback: 250),
        fatsG: _toDouble(json['fats_g']),
        fatsGoalG: _toDouble(json['fats_goal_g'], fallback: 65),
        streakDays: _toInt(json['streak_days'], fallback: 1),
        lastSyncedAt: json['last_synced_at'] != null
            ? DateTime.tryParse(json['last_synced_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        isSyncing: isSyncing,
      );

  DailySummary copyWith({
    int? caloriesConsumed,
    int? caloriesGoal,
    int? waterMl,
    int? waterGoalMl,
    double? proteinG,
    double? proteinGoalG,
    double? carbsG,
    double? carbsGoalG,
    double? fatsG,
    double? fatsGoalG,
    int? streakDays,
    DateTime? lastSyncedAt,
    bool? isSyncing,
  }) =>
      DailySummary(
        caloriesConsumed: caloriesConsumed ?? this.caloriesConsumed,
        caloriesGoal: caloriesGoal ?? this.caloriesGoal,
        waterMl: waterMl ?? this.waterMl,
        waterGoalMl: waterGoalMl ?? this.waterGoalMl,
        proteinG: proteinG ?? this.proteinG,
        proteinGoalG: proteinGoalG ?? this.proteinGoalG,
        carbsG: carbsG ?? this.carbsG,
        carbsGoalG: carbsGoalG ?? this.carbsGoalG,
        fatsG: fatsG ?? this.fatsG,
        fatsGoalG: fatsGoalG ?? this.fatsGoalG,
        streakDays: streakDays ?? this.streakDays,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        isSyncing: isSyncing ?? this.isSyncing,
      );

  // Formatted labels matching UI requirements
  String get caloriesLabel => '$caloriesConsumed kcal';
  String get waterL => '${(waterMl / 1000.0).toStringAsFixed(1)} L';
  String get proteinLabel => '${proteinG.toInt()} g';

  double get calorieRatio => caloriesGoal > 0 ? (caloriesConsumed / caloriesGoal).clamp(0.0, 1.0) : 0.0;
  double get waterRatio => waterGoalMl > 0 ? (waterMl / waterGoalMl).clamp(0.0, 1.0) : 0.0;
  double get proteinRatio => proteinGoalG > 0 ? (proteinG / proteinGoalG).clamp(0.0, 1.0) : 0.0;

  int get caloriePercent => (calorieRatio * 100).round();
  int get waterPercent => (waterRatio * 100).round();
  int get proteinPercent => (proteinRatio * 100).round();

  String get syncStatusText {
    if (isSyncing) return 'Syncing…';
    final diff = DateTime.now().difference(lastSyncedAt);
    if (diff.inMinutes < 1) return 'Synced with your logs · just now';
    if (diff.inMinutes < 60) return 'Synced with your logs · ${diff.inMinutes}m ago';
    return 'Synced with your logs · ${DateFormat.jm().format(lastSyncedAt)}';
  }

  static int _toInt(dynamic val, {int fallback = 0}) {
    if (val == null) return fallback;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }

  static double _toDouble(dynamic val, {double fallback = 0.0}) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? fallback;
    return fallback;
  }
}

/// Global provider singleton accessible across all tabs.
class DailySummaryNotifier extends ChangeNotifier {
  DailySummaryNotifier._();
  static final DailySummaryNotifier instance = DailySummaryNotifier._();

  DailySummary _summary = DailySummary.initial();
  DailySummary get summary => _summary;

  DailySummary get value => _summary;

  void update(DailySummary newSummary) {
    _summary = newSummary;
    notifyListeners();
  }

  void setSyncing(bool syncing) {
    if (_summary.isSyncing == syncing) return;
    _summary = _summary.copyWith(isSyncing: syncing);
    notifyListeners();
  }

  void addWaterMl(int ml) {
    _summary = _summary.copyWith(
      waterMl: _summary.waterMl + ml,
      lastSyncedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> refresh() async {
    // Triggers refresh through notifier
    setSyncing(true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    setSyncing(false);
  }
}

/// Direct shortcut to the provider
DailySummaryNotifier get dailySummaryProvider => DailySummaryNotifier.instance;
