import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

double _clamp01(double value) => value.clamp(0.0, 1.0);

// ─────────────────────────────────────────────
//  Analytics / Insights Screen
// ─────────────────────────────────────────────
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  AnimationController? _mainController;
  AnimationController? _pulseController;
  AnimationController? _sparkleController;
  AnimationController? _shimmerController;
  bool isWeekly = true;
  bool isLoading = false;

  ChartData? chartData;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadData();
  }

  void _initControllers() {
    _mainController ??= AnimationController(
      duration: const Duration(milliseconds: 5800),
      vsync: this,
    );
    _pulseController ??= AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _sparkleController ??= AnimationController(
      duration: const Duration(milliseconds: 6000),
      vsync: this,
    )..repeat(reverse: true);
    _shimmerController ??= AnimationController(
      duration: const Duration(milliseconds: 6500),
      vsync: this,
    )..repeat();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      await Future.delayed(const Duration(milliseconds: 1200));
      chartData = ChartData.sample();
      _mainController?.forward();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _mainController?.dispose();
    _pulseController?.dispose();
    _sparkleController?.dispose();
    _shimmerController?.dispose();
    super.dispose();
  }

  AnimationController get mainCtrl => _mainController!;
  AnimationController get sparkleCtrl => _sparkleController!;
  AnimationController get shimmerCtrl => _shimmerController!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: isLoading || _mainController == null
          ? Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF6366FF),
              ),
            )
          : SingleChildScrollView(
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
                        _buildStatsCardsAnimated(),
                        const SizedBox(height: 24),
                        _buildCalorieActivityAnimated(),
                        const SizedBox(height: 24),
                        _buildMacroDistributionAnimated(),
                        const SizedBox(height: 24),
                        _buildWeightProgressAnimated(),
                        const SizedBox(height: 24),
                        _buildOnTrackToGoal(),
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
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: const SizedBox(),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.trending_up, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          const Text(
            'Insights',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings, color: Colors.grey[600], size: 22),
          onPressed: () {},
        ),
      ],
    );
  }

  // ── A. Tab Bar ──────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isWeekly = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isWeekly ? const Color(0xFF6366FF) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text('📊 Weekly',
                  style: TextStyle(
                    color: isWeekly ? const Color(0xFF6366FF) : Colors.grey[600],
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
              onTap: () => setState(() => isWeekly = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: !isWeekly ? const Color(0xFF6366FF) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text('📈 Monthly',
                  style: TextStyle(
                    color: !isWeekly ? const Color(0xFF6366FF) : Colors.grey[600],
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

  // ── B. KPI Cards ────────────────────────────
  Widget _buildStatsCardsAnimated() {
    final mc = mainCtrl;
    return Row(
      children: [
        _KpiCard(mainController: mc, index: 0, icon: Icons.local_fire_department, targetValue: '2045', suffix: '', label: 'Avg Calories', color: const Color(0xFF6366FF)),
        const SizedBox(width: 12),
        _KpiCard(mainController: mc, index: 1, icon: Icons.water_drop, targetValue: '2.4', suffix: '', label: 'Avg Water', color: const Color(0xFF06B6D4)),
        const SizedBox(width: 12),
        _KpiCard(mainController: mc, index: 2, icon: Icons.speed, targetValue: '10', suffix: '%', label: 'Activity', color: const Color(0xFFFFA500)),
      ],
    );
  }

  // ── C. Calorie Line Chart ───────────────────
  Widget _buildCalorieActivityAnimated() {
    final mc = mainCtrl;
    return AnimatedBuilder(
      animation: mc,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: mc,
          curve: const Interval(0.20, 0.52, curve: Curves.easeOutCubic),
        ).value);
        return Transform.translate(
          offset: Offset(0, 30 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
                    const Text('Calorie Activity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
                    const SizedBox(height: 4),
                    Text('Intake vs Daily Budget', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFF3F2FF), borderRadius: BorderRadius.circular(6)),
                  child: const Text('Within Budget ✓', style: TextStyle(fontSize: 11, color: Color(0xFF6366FF), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildCalorieChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieChart() {
    final mc = mainCtrl;
    return AnimatedBuilder(
      animation: mc,
      builder: (context, child) {
        // Progressively reveal from left to right by animating maxX
        final revealT = _clamp01(CurvedAnimation(
          parent: mc,
          curve: const Interval(0.20, 0.72, curve: Curves.easeInOutCubic),
        ).value);
        // Area fill fades in after line
        final areaT = _clamp01(CurvedAnimation(
          parent: mc,
          curve: const Interval(0.50, 0.80),
        ).value);

        final animatedMaxX = 0.0 + (revealT * 5.0);

        return SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 500,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200]!, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      const titles = ['Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      if (value.toInt() >= 0 && value.toInt() < titles.length) {
                        return Text(titles[value.toInt()], style: TextStyle(color: Colors.grey[600], fontSize: 12));
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Text(value % 1000 == 0 ? '${(value / 1000).toStringAsFixed(1)}k' : '', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                    reservedSize: 35,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 2100),
                    FlSpot(1, 2300),
                    FlSpot(2, 2050),
                    FlSpot(3, 1950),
                    FlSpot(4, 2200),
                    FlSpot(5, 1850),
                  ],
                  isCurved: true,
                  color: const Color(0xFF6366FF),
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (spot, barData) => spot.x % 1 == 0,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3.5,
                        color: const Color(0xFF6366FF),
                        strokeWidth: 0,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: areaT > 0,
                    color: const Color(0xFF6366FF).withOpacity(areaT * 0.15),
                  ),
                ),
              ],
              minX: 0,
              maxX: animatedMaxX.clamp(0.5, 5.0),
              minY: 0,
              maxY: 2500,
            ),
            duration: const Duration(milliseconds: 1),
          ),
        );
      },
    );
  }

  // ── D. Macro Donut ──────────────────────────
  Widget _buildMacroDistributionAnimated() {
    final mc = mainCtrl;
    return AnimatedBuilder(
      animation: mc,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: mc,
          curve: const Interval(0.36, 0.58, curve: Curves.easeOutCubic),
        ).value);
        return Transform.translate(
          offset: Offset(0, 30 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Macro Distribution', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
            const SizedBox(height: 4),
            Text('Daily average split', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 20),
            _buildMacroChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroChart() {
    final mc = mainCtrl;
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AnimatedBuilder(
            animation: mc,
            builder: (context, child) {
              final sweepT = _clamp01(CurvedAnimation(
                parent: mc,
                curve: const Interval(0.36, 0.72, curve: Curves.easeInOutQuart),
              ).value);
              final rotT = _clamp01(CurvedAnimation(
                parent: mc,
                curve: const Interval(0.36, 1.0, curve: Curves.easeInOut),
              ).value);
              return Transform.rotate(
                angle: rotT * math.pi / 6,
                child: SizedBox(
                  height: 160,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: const Color(0xFF14B8A6),
                          value: 120 * sweepT,
                          title: sweepT > 0.75 ? '120g' : '',
                          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                          radius: 52,
                          titlePositionPercentageOffset: 0.64,
                        ),
                        PieChartSectionData(
                          color: const Color(0xFFFFA500),
                          value: 240 * sweepT,
                          title: sweepT > 0.75 ? '240g' : '',
                          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                          radius: 52,
                          titlePositionPercentageOffset: 0.64,
                        ),
                        PieChartSectionData(
                          color: const Color(0xFFEF4444),
                          value: 65 * sweepT,
                          title: sweepT > 0.75 ? '65g' : '',
                          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                          radius: 52,
                          titlePositionPercentageOffset: 0.64,
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 42,
                    ),
                    duration: const Duration(milliseconds: 1),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MacroLegendItem(mainController: mc, index: 0, label: 'Protein', value: '120g', color: const Color(0xFF14B8A6)),
              const SizedBox(height: 12),
              _MacroLegendItem(mainController: mc, index: 1, label: 'Carbs', value: '240g', color: const Color(0xFFFFA500)),
              const SizedBox(height: 12),
              _MacroLegendItem(mainController: mc, index: 2, label: 'Fats', value: '65g', color: const Color(0xFFEF4444)),
            ],
          ),
        ),
      ],
    );
  }

  // ── E. Weight Progress Chart ────────────────
  Widget _buildWeightProgressAnimated() {
    final mc = mainCtrl;
    return AnimatedBuilder(
      animation: mc,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: mc,
          curve: const Interval(0.54, 0.76, curve: Curves.easeOutCubic),
        ).value);
        return Transform.translate(
          offset: Offset(0, 30 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Weight Progress', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
                AnimatedBuilder(
                  animation: mc,
                  builder: (context, child) {
                    final pulseT = _clamp01(CurvedAnimation(
                      parent: mc,
                      curve: const Interval(0.74, 0.90, curve: Curves.elasticOut),
                    ).value);
                    final scale = 0.95 + (pulseT * 0.08);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F2FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF6366FF), width: 1),
                        ),
                        child: const Text('🎯 Goal: 75.0', style: TextStyle(fontSize: 11, color: Color(0xFF6366FF), fontWeight: FontWeight.w600)),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Current: 75.1 kg', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 20),
            _buildWeightChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightChart() {
    final mc = mainCtrl;
    return AnimatedBuilder(
      animation: mc,
      builder: (context, child) {
        final revealT = _clamp01(CurvedAnimation(
          parent: mc,
          curve: const Interval(0.54, 0.90, curve: Curves.easeInOutCubic),
        ).value);
        final areaT = _clamp01(CurvedAnimation(
          parent: mc,
          curve: const Interval(0.70, 0.92),
        ).value);

        final animatedMaxX = 0.0 + (revealT * 5.0);

        return SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200]!, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      const titles = ['Oct 04', 'Oct 11', 'Oct 18', 'Oct 25', 'Nov 01', 'Nov 05'];
                      if (value.toInt() >= 0 && value.toInt() < titles.length) {
                        return Text(titles[value.toInt()], style: TextStyle(color: Colors.grey[600], fontSize: 11));
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                    reservedSize: 25,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 78.5),
                    FlSpot(1, 77.2),
                    FlSpot(2, 76.8),
                    FlSpot(3, 76.5),
                    FlSpot(4, 75.8),
                    FlSpot(5, 75.3),
                  ],
                  isCurved: true,
                  color: const Color(0xFF06B6D4),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: areaT > 0,
                    color: const Color(0xFF06B6D4).withOpacity(areaT * 0.1),
                  ),
                ),
              ],
              minX: 0,
              maxX: animatedMaxX.clamp(0.5, 5.0),
              minY: 74,
              maxY: 79,
            ),
            duration: const Duration(milliseconds: 1),
          ),
        );
      },
    );
  }

  // ── On Track to Goal ────────────────────────
  Widget _buildOnTrackToGoal() {
    final mc = mainCtrl;
    return AnimatedBuilder(
      animation: mc,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: mc,
          curve: const Interval(0.62, 0.82, curve: Curves.easeOutCubic),
        ).value);
        return Transform.translate(
          offset: Offset(0, 30 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
                  const Text('On Track to Goal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                  Text('Achieved complete: Day 15', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  // ── F. AI Coach Insight ─────────────────────
  Widget _buildAICoachInsight() {
    final mc = mainCtrl;
    return AnimatedBuilder(
      animation: mc,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: mc,
          curve: const Interval(0.70, 0.92, curve: Curves.easeOutBack),
        ).value);
        return Transform.translate(
          offset: Offset(0, 40 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF6366FF), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: sparkleCtrl,
                  builder: (context, child) {
                    final sparkleOpacity = 0.6 + (sparkleCtrl.value * 0.4);
                    final glowScale = 1.0 + (sparkleCtrl.value * 0.12);
                    return Transform.scale(
                      scale: glowScale,
                      child: Opacity(
                        opacity: sparkleOpacity,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AI COACH INSIGHT!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      Text(
                        'Your protein intake is 15% lower than last week.\nTry adding Greek yogurt or almonds to your afternoon snack to hit your muscle gain target.',
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
            Stack(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Row(
                    children: [
                      const Text('View recommendation', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                    ],
                  ),
                ),
                AnimatedBuilder(
                  animation: shimmerCtrl,
                  builder: (context, child) {
                    final shimmerX = -0.8 + (shimmerCtrl.value * 1.8);
                    return Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRect(
                          child: Transform.translate(
                            offset: Offset(shimmerX * 120, 0),
                            child: Transform.rotate(
                              angle: -0.25,
                              child: Container(
                                width: 80, height: 20,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft, end: Alignment.centerRight,
                                    colors: [Colors.transparent, Colors.white.withOpacity(0.5), Colors.transparent],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  KPI Card
// ─────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final Animation<double> mainController;
  final int index;
  final IconData icon;
  final String targetValue, suffix, label;
  final Color color;

  const _KpiCard({
    required this.mainController, required this.index, required this.icon,
    required this.targetValue, required this.suffix, required this.label, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final staggerDelay = 0.02 + (index * 0.05);
    return Expanded(
      child: AnimatedBuilder(
        animation: mainController,
        builder: (context, child) {
          final t = _clamp01(CurvedAnimation(
            parent: mainController,
            curve: Interval(staggerDelay, staggerDelay + 0.16, curve: Curves.elasticOut),
          ).value);
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: AnimatedBuilder(
            animation: mainController,
            builder: (context, child) {
              final countT = _clamp01(CurvedAnimation(
                parent: mainController,
                curve: Interval(staggerDelay + 0.04, staggerDelay + 0.22, curve: Curves.easeOutCubic),
              ).value);
              final displayValue = _animateValue(targetValue, countT);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: Colors.white, size: 20)),
                  const SizedBox(height: 12),
                  Text(displayValue, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _animateValue(String target, double t) {
    if (target.contains('.')) {
      final doubleVal = double.tryParse(target) ?? 0.0;
      return '${(doubleVal * t).toStringAsFixed(1)}$suffix';
    } else {
      final intVal = int.tryParse(target) ?? 0;
      return '${(intVal * t).round()}$suffix';
    }
  }
}

// ─────────────────────────────────────────────
//  Macro Legend Item
// ─────────────────────────────────────────────
class _MacroLegendItem extends StatelessWidget {
  final Animation<double> mainController;
  final int index;
  final String label, value;
  final Color color;

  const _MacroLegendItem({
    required this.mainController, required this.index,
    required this.label, required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final numericValue = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final suffix = value.replaceAll(RegExp(r'[0-9.]'), '');
    final staggerDelay = 0.38 + (index * 0.08);
    return AnimatedBuilder(
      animation: mainController,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: mainController,
          curve: Interval(staggerDelay, staggerDelay + 0.20, curve: Curves.easeOutCubic),
        ).value);
        return Transform.translate(
          offset: Offset(30 * (1 - t), 0),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
              AnimatedBuilder(
                animation: mainController,
                builder: (context, child) {
                  final t = _clamp01(CurvedAnimation(
                    parent: mainController,
                    curve: Interval(staggerDelay, staggerDelay + 0.20, curve: Curves.easeOutCubic),
                  ).value);
                  return Text('${(numericValue * t).round()}$suffix', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Data model
// ─────────────────────────────────────────────
class ChartData {
  final Map<String, double> weeklyCalories, monthlyWeight, macros;
  ChartData({required this.weeklyCalories, required this.monthlyWeight, required this.macros});

  factory ChartData.sample() {
    return ChartData(
      weeklyCalories: {'Tue': 2100, 'Wed': 2300, 'Thu': 2050, 'Fri': 1950, 'Sat': 2200, 'Sun': 1850},
      monthlyWeight: {'Oct 04': 78.5, 'Oct 11': 77.2, 'Oct 18': 76.8, 'Oct 25': 76.5, 'Nov 01': 75.8, 'Nov 05': 75.3},
      macros: {'Protein': 120, 'Carbs': 240, 'Fats': 65},
    );
  }
}