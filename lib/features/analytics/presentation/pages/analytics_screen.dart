import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:fitfuel_ai/core/di/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/analytics_bloc.dart';
import '../../../../core/config/routes.dart';
import '../../../../core/domain/entities/calendar_tracking.dart';

const _bg = Color(0xFFF7F6FB);
const _surface = Colors.white;
const _purple = Color(0xFF6366FF);
const _textPrimary = Color(0xFF1F1F2E);

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnalyticsBloc _analyticsBloc;
  bool isWeekly = true;

  /// The dates shown by the charts/stats — always matches the active mode:
  /// - Weekly  → the last 7 days (today back 6).
  /// - Monthly → every day of the current calendar month up to today.
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
      duration: const Duration(milliseconds: 5800),
      vsync: this,
    )..forward();
    _analyticsBloc = sl<AnalyticsBloc>();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    _analyticsBloc.add(LoadAnalytics(userId, DateTime.now(), isWeekly: isWeekly));
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _analyticsBloc,
      child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          final isLoaded = state is AnalyticsLoaded;
          // Only render real data once it's actually loaded. Until then show a
          // loading spinner so the screen never flashes 0/empty values first
          // (the flicker the user reported on every visit).
          if (!isLoaded) {
            return Scaffold(
              backgroundColor: _bg,
              appBar: _buildAppBar(),
              body: const Center(
                child: CircularProgressIndicator(color: _purple),
              ),
            );
          }

          final calendarData = state.calendarData;

          return Scaffold(
            backgroundColor: _bg,
            appBar: _buildAppBar(),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTabBar(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildStatsCards(calendarData),
                        const SizedBox(height: 24),
                        _buildCalorieActivityChart(calendarData),
                        const SizedBox(height: 24),
                        _buildMacroDistribution(),
                        const SizedBox(height: 24),
                        _buildOnTrackToGoal(calendarData),
                        const SizedBox(height: 24),
                        _buildAICoachInsight(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: _surface,
      leading: const SizedBox(),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _purple,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.trending_up, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          const Text(
            'Insights',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: Colors.grey[600], size: 22),
          onPressed: _loadData,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => isWeekly = true);
                _loadData();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isWeekly ? _purple : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Weekly',
                  style: TextStyle(
                    color: isWeekly ? _purple : Colors.grey[600],
                    fontWeight: isWeekly ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => isWeekly = false);
                _loadData();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: !isWeekly ? _purple : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Monthly',
                  style: TextStyle(
                    color: !isWeekly ? _purple : Colors.grey[600],
                    fontWeight: !isWeekly ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(CalendarTracking? calendarData) {
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
        _KpiCard(controller: _mainController, index: 0, icon: Icons.local_fire_department, value: '$avgCal', suffix: '', label: 'Avg Calories', color: _purple),
        const SizedBox(width: 12),
        _KpiCard(controller: _mainController, index: 1, icon: Icons.water_drop, value: avgWater, suffix: 'L', label: 'Avg Water', color: const Color(0xFF06B6D4)),
        const SizedBox(width: 12),
        _KpiCard(controller: _mainController, index: 2, icon: Icons.speed, value: '$activityPercent', suffix: '%', label: 'Activity', color: const Color(0xFFFFA500)),
      ],
    );
  }

  Widget _buildCalorieActivityChart(CalendarTracking? calendarData) {
    final days = _rangeDays.map((d) {
      // Weekly → weekday initial (Mon); Monthly → day-of-month number.
      final label = isWeekly ? DateFormat('E').format(d) : '${d.day}';
      final cal = calendarData?.caloriesOn(d) ?? 0;
      return {'label': label, 'value': cal.toDouble()};
    }).toList();

    final maxCal = calendarData != null && calendarData.targetCalories > 0
        ? calendarData.targetCalories.toDouble()
        : 2000.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Calorie Activity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textPrimary)),
                  const SizedBox(height: 4),
                  Text('Intake vs Daily Budget', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF3F2FF), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  maxCal > 0 ? 'Target: ${maxCal.toInt()} kcal' : 'Set your goal',
                  style: const TextStyle(fontSize: 11, color: _purple, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              data: days,
              maxValue: maxCal * 1.2,
              targetLine: maxCal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroDistribution() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Macro Distribution', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textPrimary)),
          const SizedBox(height: 4),
          Text('Daily average split', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 160,
                  child: PieChart(
                    sections: [
                      PieChartSectionData(color: const Color(0xFF14B8A6), value: 30, title: '30%', titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white), radius: 52, titlePositionPercentageOffset: 0.64),
                      PieChartSectionData(color: const Color(0xFFFFA500), value: 50, title: '50%', titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white), radius: 52, titlePositionPercentageOffset: 0.64),
                      PieChartSectionData(color: const Color(0xFFEF4444), value: 20, title: '20%', titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white), radius: 52, titlePositionPercentageOffset: 0.64),
                    ],
                    sectionsSpace: 2,
                    centerSpaceRadius: 42,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _MacroLegendItem(label: 'Protein', value: '30%', color: Color(0xFF14B8A6)),
                    SizedBox(height: 12),
                    _MacroLegendItem(label: 'Carbs', value: '50%', color: Color(0xFFFFA500)),
                    SizedBox(height: 12),
                    _MacroLegendItem(label: 'Fats', value: '20%', color: Color(0xFFEF4444)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOnTrackToGoal(CalendarTracking? calendarData) {
    final hitCount = _rangeDays
        .where((d) => calendarData?.anyHitOn(d) ?? false)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: const Color(0xFF06B6D4).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.check_circle_outline, color: Color(0xFF06B6D4), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('On Track to Goal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary)),
                Text('Achieved complete: Day $hitCount', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
        ],
      ),
    );
  }

  Widget _buildAICoachInsight() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _purple, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI COACH INSIGHT!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Text(
                      'Your protein intake is 15% lower than last week. Try adding Greek yogurt or almonds to your afternoon snack to hit your muscle gain target.',
                      style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.95), height: 1.5, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push(AppRoutes.aiCoach),
            child: Row(
              children: [
                Text('View recommendation', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final Animation<double> controller;
  final int index;
  final IconData icon;
  final String value;
  final String suffix;
  final String label;
  final Color color;

  const _KpiCard({
    required this.controller,
    required this.index,
    required this.icon,
    required this.value,
    required this.suffix,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final staggerDelay = 0.02 + (index * 0.05);
    return Expanded(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final t = (CurvedAnimation(parent: controller, curve: Interval(staggerDelay, staggerDelay + 0.16, curve: Curves.elasticOut)).value).clamp(0.0, 1.0);
          final scale = 0.92 + (t * 0.08);
          return Transform.scale(
            scale: scale,
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - t)),
              child: Opacity(opacity: t, child: child),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.white, size: 20)),
              const SizedBox(height: 12),
              Text('$value$suffix', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textPrimary)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroLegendItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroLegendItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimary)),
          ],
        ),
      ],
    );
  }
}

class BarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final double maxValue;
  final double targetLine;

  const BarChart({required this.data, required this.maxValue, required this.targetLine});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = (constraints.maxWidth / data.length) * 0.5;
        final spacing = (constraints.maxWidth / data.length) * 0.5;

        return CustomPaint(
          size: Size(constraints.maxWidth, 180),
          painter: BarChartPainter(data: data, maxValue: maxValue, targetLine: targetLine, barWidth: barWidth, spacing: spacing),
        );
      },
    );
  }
}

class BarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxValue;
  final double targetLine;
  final double barWidth;
  final double spacing;

  BarChartPainter({
    required this.data,
    required this.maxValue,
    required this.targetLine,
    required this.barWidth,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    final chartHeight = size.height - 30;
    final chartWidth = size.width;

    for (var i = 0; i < data.length; i++) {
      final x = spacing + i * (barWidth + spacing) + barWidth / 2;
      final value = data[i]['value'] as double;
      final barHeight = (value / maxValue) * chartHeight;
      final y = chartHeight - barHeight;

      paint.color = const Color(0xFF6366FF);
      paint.style = PaintingStyle.fill;
      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(x - barWidth / 2, y, barWidth, barHeight), const Radius.circular(4));
      canvas.drawRRect(rect, paint);

      textPainter.text = TextSpan(text: data[i]['label'], style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500));
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, chartHeight + 8));

      final valueText = value.toInt().toString();
      textPainter.text = TextSpan(text: valueText, style: TextStyle(fontSize: 9, color: Colors.grey[600], fontWeight: FontWeight.w600));
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - 14));
    }

    if (targetLine > 0) {
      final targetY = chartHeight - (targetLine / maxValue) * chartHeight;
      paint.color = Colors.red.withOpacity(0.4);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1;
      canvas.drawLine(Offset(0, targetY), Offset(chartWidth, targetY), paint);

      textPainter.text = const TextSpan(text: 'Target', style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.w600));
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, targetY - 12));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PieChart extends StatelessWidget {
  final List<PieChartSectionData> sections;
  final double sectionsSpace;
  final double centerSpaceRadius;

  const PieChart({required this.sections, this.sectionsSpace = 2, this.centerSpaceRadius = 42});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(160, 160),
      painter: PieChartPainter(sections: sections, sectionsSpace: sectionsSpace, centerSpaceRadius: centerSpaceRadius),
    );
  }
}

class PieChartSectionData {
  final Color color;
  final double value;
  final String title;
  final TextStyle titleStyle;
  final double radius;
  final double titlePositionPercentageOffset;

  PieChartSectionData({
    required this.color,
    required this.value,
    required this.title,
    required this.titleStyle,
    required this.radius,
    required this.titlePositionPercentageOffset,
  });
}

class PieChartPainter extends CustomPainter {
  final List<PieChartSectionData> sections;
  final double sectionsSpace;
  final double centerSpaceRadius;

  PieChartPainter({required this.sections, required this.sectionsSpace, required this.centerSpaceRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final total = sections.fold<double>(0, (sum, s) => sum + s.value);
    var startAngle = -math.pi / 2;

    for (final section in sections) {
      final sweepAngle = (section.value / total) * 2 * math.pi;
      final paint = Paint()..color = section.color..style = PaintingStyle.fill;
      final rect = Rect.fromCircle(center: center, radius: section.radius);
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle + sectionsSpace / section.radius;
    }

    final centerPaint = Paint()..color = _surface..style = PaintingStyle.fill;
    canvas.drawCircle(center, centerSpaceRadius, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
