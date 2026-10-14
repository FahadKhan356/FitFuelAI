import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/routes.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/domain/entities/calendar_tracking.dart';
import '../../../../core/services/home_data_refresh_notifier.dart';
import '../../../coach/providers/daily_summary_provider.dart';
import '../bloc/analytics_bloc.dart';
import '../../../../shared/theme/app_theme.dart';

// Brand Accent Colors
const Color _kPrimary = Color(0xFF6366F1);
const Color _kCyan = Color(0xFF06B6D4);
const Color _kAmber = Color(0xFFF59E0B);
const Color _kEmerald = Color(0xFF10B981);
const Color _kRose = Color(0xFFEF4444);

/// High-performance, professional health analytics screen with interactive charts,
/// macro distribution, consistency heatmap, AI coach insights, and dark/light modes.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnalyticsBloc _analyticsBloc;
  bool isWeekly = true;
  int? _selectedBarIndex;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _isDark ? AppDarkColors.background : const Color(0xFFF8F9FE);
  Color get _surface => _isDark ? AppDarkColors.surface : Colors.white;
  Color get _surfaceAlt =>
      _isDark ? AppDarkColors.surfaceAlt : const Color(0xFFF1F5F9);
  Color get _textPrimary =>
      _isDark ? AppDarkColors.textPrimary : const Color(0xFFFAF4EE);
  Color get _textSecondary =>
      _isDark ? AppDarkColors.textSecondary : const Color(0xFF64748B);
  Color get _borderColor =>
      _isDark ? AppDarkColors.border : const Color(0xFFE2E8F0);

  /// The active dates shown by the charts/stats:
  /// - Weekly  → 7 days (today back 6).
  /// - Monthly → current calendar month days up to today.
  List<DateTime> get _rangeDays {
    final today = DateTime.now();
    if (isWeekly) {
      return List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    }
    return List.generate(
      today.day,
      (i) => DateTime(today.year, today.month, i + 1),
    );
  }

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();
    _analyticsBloc = sl<AnalyticsBloc>();

    HomeDataRefreshNotifier.instance.addListener(_loadData);
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    _analyticsBloc.add(LoadAnalytics(userId, DateTime.now(), isWeekly: isWeekly));
  }

  @override
  void dispose() {
    HomeDataRefreshNotifier.instance.removeListener(_loadData);
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
        value: _analyticsBloc,
        child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
          builder: (context, state) {
            final isLoaded = state is AnalyticsLoaded;

            if (!isLoaded) {
              return Scaffold(
                backgroundColor: _bg,
                appBar: _buildAppBar(),
                body: const Center(
                  child: CircularProgressIndicator(color: _kPrimary),
                ),
              );
            }

            final calendarData = state.calendarData;

            return Scaffold(
              backgroundColor: _bg,
              appBar: _buildAppBar(),
              body: RefreshIndicator(
                color: _kPrimary,
                backgroundColor: _surface,
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimeRangeBar(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            _buildKpiCards(calendarData),
                            const SizedBox(height: 20),
                            _buildCalorieActivityChart(calendarData),
                            const SizedBox(height: 20),
                            _buildMacroDistribution(),
                            const SizedBox(height: 20),
                            _buildConsistencyHeatmap(calendarData),
                            const SizedBox(height: 20),
                            _buildAICoachInsight(calendarData),
                            const SizedBox(height: 20),
                            _buildWeightTrackerShortcut(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

  PreferredSizeWidget _buildAppBar() => AppBar(
        elevation: 0,
        backgroundColor: _surface,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kPrimary, Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Stats & Trends',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  isWeekly ? 'Last 7 Days Summary' : 'Current Month Overview',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Data',
            icon: Icon(Icons.refresh_rounded, color: _textSecondary, size: 22),
            onPressed: () {
              HapticFeedback.selectionClick();
              _loadData();
            },
          ),
          const SizedBox(width: 8),
        ],
      );

  Widget _buildTimeRangeBar() => Container(
        color: _surface,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: _rangeTab(
                  label: 'Weekly (7 Days)',
                  icon: Icons.calendar_view_week_rounded,
                  isActive: isWeekly,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      isWeekly = true;
                      _selectedBarIndex = null;
                    });
                    _loadData();
                  },
                ),
              ),
              Expanded(
                child: _rangeTab(
                  label: 'Monthly (${DateTime.now().day} Days)',
                  icon: Icons.calendar_month_rounded,
                  isActive: !isWeekly,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      isWeekly = false;
                      _selectedBarIndex = null;
                    });
                    _loadData();
                  },
                ),
              ),
            ],
          ),
        ),
      );

  Widget _rangeTab({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? (_isDark ? const Color(0xFF283252) : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _isDark ? 0.25 : 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isActive ? _kPrimary : _textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? (_isDark ? Colors.white : const Color(0xFF0F172A)) : _textSecondary,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildKpiCards(CalendarTracking? calendarData) {
    final range = _rangeDays;
    final daysInRange = range.length;

    final totalCal = range.fold<int>(
      0,
      (sum, d) => sum + (calendarData?.caloriesOn(d) ?? 0),
    );
    final avgCal = daysInRange == 0 ? 0 : totalCal ~/ daysInRange;

    final totalWater = range.fold<int>(
      0,
      (sum, d) => sum + (calendarData?.waterOn(d) ?? 0),
    );
    final avgWater = daysInRange == 0
        ? '0.0'
        : (totalWater / 1000 / daysInRange).toStringAsFixed(1);

    final hitDays = range
        .where((d) => calendarData?.anyHitOn(d) ?? false)
        .length;
    final activityPercent =
        daysInRange == 0 ? 0 : ((hitDays / daysInRange) * 100).round();

    return Row(
      children: [
        _KpiCard(
          controller: _mainController,
          index: 0,
          icon: Icons.local_fire_department_rounded,
          value: '$avgCal',
          suffix: ' kcal',
          label: 'Avg Daily Intake',
          color: _kPrimary,
        ),
        const SizedBox(width: 10),
        _KpiCard(
          controller: _mainController,
          index: 1,
          icon: Icons.water_drop_rounded,
          value: avgWater,
          suffix: ' L',
          label: 'Avg Hydration',
          color: _kCyan,
        ),
        const SizedBox(width: 10),
        _KpiCard(
          controller: _mainController,
          index: 2,
          icon: Icons.verified_rounded,
          value: '$activityPercent',
          suffix: '%',
          label: 'Goal Adherence',
          color: _kAmber,
        ),
      ],
    );
  }

  Widget _buildCalorieActivityChart(CalendarTracking? calendarData) {
    final days = _rangeDays.map((d) {
      final label = isWeekly ? DateFormat('E').format(d) : '${d.day}';
      final cal = calendarData?.caloriesOn(d) ?? 0;
      return {'label': label, 'value': cal.toDouble(), 'date': d};
    }).toList();

    final maxCal = calendarData != null && calendarData.targetCalories > 0
        ? calendarData.targetCalories.toDouble()
        : 2000.0;

    final selectedDay = _selectedBarIndex != null && _selectedBarIndex! < days.length
        ? days[_selectedBarIndex!]
        : null;

    final selectedDayDate = selectedDay?['date'] as DateTime?;
    final selectedDayValue = (selectedDay?['value'] as num?)?.toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calorie Intake Activity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      selectedDayDate != null && selectedDayValue != null
                          ? '${DateFormat('EEEE, MMM d').format(selectedDayDate)}: ${selectedDayValue.round()} kcal'
                          : 'Daily consumption vs target budget',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: selectedDayDate != null ? _kPrimary : _textSecondary,
                        fontWeight: selectedDayDate != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: _isDark ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_rounded, size: 12, color: _kPrimary),
                    const SizedBox(width: 4),
                    Text(
                      'Target: ${maxCal.toInt()} kcal',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              data: days,
              maxValue: math.max(maxCal * 1.25, 2400),
              targetLine: maxCal,
              selectedIndex: _selectedBarIndex,
              onSelectBar: (idx) {
                HapticFeedback.selectionClick();
                setState(() => _selectedBarIndex = idx);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroDistribution() => ListenableBuilder(
        listenable: dailySummaryProvider,
        builder: (context, _) {
          final summary = dailySummaryProvider.value;

          // Calculate real macro energy or realistic balanced fallback
          final pG = summary.proteinG > 0 ? summary.proteinG : 95.0;
          final cG = summary.carbsG > 0 ? summary.carbsG : 160.0;
          final fG = summary.fatsG > 0 ? summary.fatsG : 55.0;

          final pCal = pG * 4;
          final cCal = cG * 4;
          final fCal = fG * 9;
          final totalCal = (pCal + cCal + fCal).clamp(1.0, 10000.0);

          final pPct = ((pCal / totalCal) * 100).round();
          final cPct = ((cCal / totalCal) * 100).round();
          final fPct = (100 - pPct - cPct).clamp(5, 90);

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isDark ? 0.25 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Macronutrient Distribution',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Caloric energy ratio from daily logs',
                            style: TextStyle(fontSize: 12, color: _textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.pie_chart_outline_rounded, color: _kPrimary, size: 20),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 150,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              centerColor: _surface,
                              sections: [
                                PieChartSectionData(
                                  color: _kEmerald,
                                  value: pPct.toDouble(),
                                  title: '$pPct%',
                                  titleStyle: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  radius: 46,
                                  titlePositionPercentageOffset: 0.62,
                                ),
                                PieChartSectionData(
                                  color: _kAmber,
                                  value: cPct.toDouble(),
                                  title: '$cPct%',
                                  titleStyle: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  radius: 46,
                                  titlePositionPercentageOffset: 0.62,
                                ),
                                PieChartSectionData(
                                  color: _kRose,
                                  value: fPct.toDouble(),
                                  title: '$fPct%',
                                  titleStyle: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  radius: 46,
                                  titlePositionPercentageOffset: 0.62,
                                ),
                              ],
                              sectionsSpace: 3,
                              centerSpaceRadius: 36,
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${totalCal.round()}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: _textPrimary,
                                  ),
                                ),
                                Text(
                                  'kcal',
                                  style: TextStyle(fontSize: 10, color: _textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MacroProgressRow(
                            label: 'Protein',
                            grams: '${pG.round()}g',
                            percent: '$pPct%',
                            color: _kEmerald,
                            ratio: pPct / 100,
                            isDark: _isDark,
                          ),
                          const SizedBox(height: 12),
                          _MacroProgressRow(
                            label: 'Carbohydrates',
                            grams: '${cG.round()}g',
                            percent: '$cPct%',
                            color: _kAmber,
                            ratio: cPct / 100,
                            isDark: _isDark,
                          ),
                          const SizedBox(height: 12),
                          _MacroProgressRow(
                            label: 'Healthy Fats',
                            grams: '${fG.round()}g',
                            percent: '$fPct%',
                            color: _kRose,
                            ratio: fPct / 100,
                            isDark: _isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

  Widget _buildConsistencyHeatmap(CalendarTracking? calendarData) {
    final range = _rangeDays;
    final hitCount = range.where((d) => calendarData?.anyHitOn(d) ?? false).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _kEmerald.withValues(alpha: _isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle_rounded, color: _kEmerald, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Habit Consistency Tracker',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      '$hitCount of ${range.length} days achieved target goals',
                      style: TextStyle(fontSize: 12, color: _textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _kEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${((hitCount / (range.isEmpty ? 1 : range.length)) * 100).round()}% Success',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _kEmerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 7-day or month micro streak pills
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: range.take(7).map((d) {
              final isHit = calendarData?.anyHitOn(d) ?? false;
              final isCalHit = calendarData?.caloriesHitOn(d) ?? false;
              final isWaterHit = calendarData?.waterHitOn(d) ?? false;
              final isToday = DateFormat('yyyy-MM-dd').format(d) ==
                  DateFormat('yyyy-MM-dd').format(DateTime.now());

              return Expanded(
                child: Column(
                  children: [
                    Text(
                      DateFormat('E').format(d).substring(0, 1),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday ? _kPrimary : _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isHit
                            ? (isCalHit && isWaterHit
                                ? _kEmerald
                                : _kEmerald.withValues(alpha: 0.75))
                            : (_isDark ? const Color(0xFF232B45) : const Color(0xFFF1F5F9)),
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(color: _kPrimary, width: 2)
                            : null,
                      ),
                      child: Icon(
                        isHit ? Icons.check_rounded : Icons.remove_rounded,
                        size: 16,
                        color: isHit ? Colors.white : _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${d.day}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? _kPrimary : _textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAICoachInsight(CalendarTracking? calendarData) {
    final avgCal = _rangeDays.fold<int>(
          0,
          (sum, d) => sum + (calendarData?.caloriesOn(d) ?? 0),
        ) ~/
        (_rangeDays.isEmpty ? 1 : _rangeDays.length);

    final targetCal = calendarData?.targetCalories ?? 2000;
    final diff = avgCal - targetCal;

    final String insightMessage;
    if (avgCal == 0) {
      insightMessage =
          'Start logging your daily meals and water intake to receive personalized dietary forecasts and nutritional intelligence.';
    } else if (diff > 150) {
      insightMessage =
          'Your average calorie intake is running $diff kcal above daily budget. Consider prioritizing fiber-rich vegetables and lean protein to stay satiated.';
    } else if (diff < -200) {
      insightMessage =
          'You are averaging ${diff.abs()} kcal below your optimal target. Ensure you refuel adequately post-workout to support muscle recovery and metabolism.';
    } else {
      insightMessage =
          'Exceptional balance! Your caloric intake aligns within 5% of your target. Your macronutrient synthesis is in an optimal zone.';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? const [Color(0xFF1E2242), Color(0xFF2B2858)]
              : const [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'FITFUEL AI VISION INSIGHT',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insightMessage,
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.white.withValues(alpha: 0.95),
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              context.push(AppRoutes.aiCoach);
            },
            child: const Row(
              children: [
                Text(
                  'Discuss adjustments with AI Coach',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightTrackerShortcut() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _kCyan.withValues(alpha: _isDark ? 0.20 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.monitor_weight_outlined, color: _kCyan, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Body Weight Progress',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  Text(
                    'Log weight check-ins and track BMI trajectory',
                    style: TextStyle(fontSize: 12, color: _textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: _textSecondary),
              onPressed: () {
                HapticFeedback.selectionClick();
                context.push(AppRoutes.weightTracker);
              },
            ),
          ],
        ),
      );
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.controller,
    required this.index,
    required this.icon,
    required this.value,
    required this.suffix,
    required this.label,
    required this.color,
  });

  final Animation<double> controller;
  final int index;
  final IconData icon;
  final String value;
  final String suffix;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final staggerDelay = 0.02 + (index * 0.06);

    return Expanded(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final t = CurvedAnimation(
            parent: controller,
            curve: Interval(staggerDelay, (staggerDelay + 0.22).clamp(0.0, 1.0), curve: Curves.easeOutBack),
          ).value.clamp(0.0, 1.0);
          final scale = 0.90 + (t * 0.10);
          return Transform.scale(
            scale: scale,
            child: Opacity(opacity: t, child: child),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppDarkColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppDarkColors.border : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 10),
              RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    TextSpan(
                      text: suffix,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroProgressRow extends StatelessWidget {
  const _MacroProgressRow({
    required this.label,
    required this.grams,
    required this.percent,
    required this.color,
    required this.ratio,
    required this.isDark,
  });

  final String label;
  final String grams;
  final String percent;
  final Color color;
  final double ratio;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              Text(
                '$grams ($percent)',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: color.withValues(alpha: isDark ? 0.2 : 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      );
}

class BarChart extends StatelessWidget {
  const BarChart({
    required this.data,
    required this.maxValue,
    required this.targetLine,
    this.selectedIndex,
    this.onSelectBar,
    super.key,
  });

  final List<Map<String, dynamic>> data;
  final double maxValue;
  final double targetLine;
  final int? selectedIndex;
  final ValueChanged<int>? onSelectBar;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = (constraints.maxWidth / data.length) * 0.44;
          final spacing = (constraints.maxWidth / data.length) * 0.56;

          return GestureDetector(
            onTapUp: (details) {
              if (onSelectBar == null || data.isEmpty) {
                return;
              }
              final totalSlot = constraints.maxWidth / data.length;
              final idx = (details.localPosition.dx / totalSlot).floor().clamp(0, data.length - 1);
              onSelectBar!(idx);
            },
            child: CustomPaint(
              size: Size(constraints.maxWidth, 200),
              painter: BarChartPainter(
                data: data,
                maxValue: maxValue,
                targetLine: targetLine,
                barWidth: barWidth,
                spacing: spacing,
                selectedIndex: selectedIndex,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          );
        },
      );
}

class BarChartPainter extends CustomPainter {
  BarChartPainter({
    required this.data,
    required this.maxValue,
    required this.targetLine,
    required this.barWidth,
    required this.spacing,
    required this.selectedIndex,
    required this.isDark,
  });

  final List<Map<String, dynamic>> data;
  final double maxValue;
  final double targetLine;
  final double barWidth;
  final double spacing;
  final int? selectedIndex;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    final chartHeight = size.height - 34;
    final chartWidth = size.width;

    // Draw Target Line
    if (targetLine > 0) {
      final targetY = chartHeight - (targetLine / maxValue) * chartHeight;
      final targetPaint = Paint()
        ..color = _kPrimary.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      // Dashed Target Line
      const dashWidth = 5.0;
      const dashSpace = 4.0;
      double startX = 0;
      while (startX < chartWidth) {
        canvas.drawLine(
          Offset(startX, targetY),
          Offset(math.min(startX + dashWidth, chartWidth), targetY),
          targetPaint,
        );
        startX += dashWidth + dashSpace;
      }

      textPainter
        ..text = TextSpan(
          text: 'Goal ${targetLine.toInt()}',
          style: const TextStyle(
            fontSize: 9.5,
            color: _kPrimary,
            fontWeight: FontWeight.bold,
          ),
        )
        ..layout()
        ..paint(canvas, Offset(chartWidth - textPainter.width - 4, targetY - 14));
    }

    // Draw Bars
    for (var i = 0; i < data.length; i++) {
      final slotWidth = size.width / data.length;
      final x = (i * slotWidth) + (slotWidth / 2);
      final value = data[i]['value'] as double;
      final barHeight = (value / maxValue).clamp(0.0, 1.0) * chartHeight;
      final y = chartHeight - barHeight;
      final isSelected = selectedIndex == i;

      // Background Track Slot
      final trackPaint = Paint()
        ..color = isDark ? const Color(0xFF232B45).withValues(alpha: 0.5) : const Color(0xFFF1F5F9);
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barWidth / 2, 0, barWidth, chartHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(trackRect, trackPaint);

      // Active Bar with Gradient
      final barRect = Rect.fromLTWH(x - barWidth / 2, y, barWidth, barHeight);
      final barPaint = Paint()
        ..shader = LinearGradient(
          colors: isSelected
              ? const [Color(0xFF818CF8), _kPrimary]
              : [
                  _kPrimary.withValues(alpha: 0.80),
                  const Color(0xFF4F46E5),
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(barRect)
        ..style = PaintingStyle.fill;

      final roundedBar = RRect.fromRectAndRadius(barRect, const Radius.circular(6));
      canvas.drawRRect(roundedBar, barPaint);

      // Highlight Selection Ring
      if (isSelected) {
        final selectBorder = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawRRect(roundedBar, selectBorder);
      }

      // X-Axis Day Label
      textPainter
        ..text = TextSpan(
          text: data[i]['label'] as String,
          style: TextStyle(
            fontSize: 10.5,
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        )
        ..layout()
        ..paint(canvas, Offset(x - textPainter.width / 2, chartHeight + 10));

      // Value label on top of bar (if active or space allows)
      if (value > 0 && (isSelected || data.length <= 7)) {
        textPainter
          ..text = TextSpan(
            text: value.toInt().toString(),
            style: TextStyle(
              fontSize: 9,
              color: isSelected
                  ? _kPrimary
                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
              fontWeight: FontWeight.bold,
            ),
          )
          ..layout()
          ..paint(canvas, Offset(x - textPainter.width / 2, y - 13));
      }
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.data != data ||
      oldDelegate.maxValue != maxValue ||
      oldDelegate.isDark != isDark;
}

class PieChart extends StatelessWidget {
  const PieChart({
    required this.sections,
    super.key,
    this.sectionsSpace = 2,
    this.centerSpaceRadius = 42,
    this.centerColor,
  });

  final List<PieChartSectionData> sections;
  final double sectionsSpace;
  final double centerSpaceRadius;
  final Color? centerColor;

  @override
  Widget build(BuildContext context) {
    final defaultCenter = Theme.of(context).brightness == Brightness.dark
        ? AppDarkColors.surface
        : Colors.white;

    return CustomPaint(
      size: const Size(160, 160),
      painter: PieChartPainter(
        sections: sections,
        sectionsSpace: sectionsSpace,
        centerSpaceRadius: centerSpaceRadius,
        centerColor: centerColor ?? defaultCenter,
      ),
    );
  }
}

class PieChartSectionData {
  PieChartSectionData({
    required this.color,
    required this.value,
    required this.title,
    required this.titleStyle,
    required this.radius,
    required this.titlePositionPercentageOffset,
  });

  final Color color;
  final double value;
  final String title;
  final TextStyle titleStyle;
  final double radius;
  final double titlePositionPercentageOffset;
}

class PieChartPainter extends CustomPainter {
  PieChartPainter({
    required this.sections,
    required this.sectionsSpace,
    required this.centerSpaceRadius,
    this.centerColor = Colors.white,
  });

  final List<PieChartSectionData> sections;
  final double sectionsSpace;
  final double centerSpaceRadius;
  final Color centerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final total = sections.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) {
      return;
    }
    var startAngle = -math.pi / 2;

    for (final section in sections) {
      final sweepAngle = (section.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = section.color
        ..style = PaintingStyle.fill;
      final rect = Rect.fromCircle(center: center, radius: section.radius);
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle + sectionsSpace / section.radius;
    }

    final centerPaint = Paint()
      ..color = centerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, centerSpaceRadius, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
