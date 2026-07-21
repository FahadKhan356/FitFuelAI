import 'package:flutter/material.dart';


import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Advanced version with animations and provider integration

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool isWeekly = true;
  bool isLoading = false;

  // Chart data models
  late ChartData chartData;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      // Simulate API call
      await Future.delayed(Duration(milliseconds: 1200));
      chartData = ChartData.sample();
      _animationController.forward();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6366FF),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTabBar(),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16),
                        _buildStatsCardsAnimated(),
                        SizedBox(height: 24),
                        _buildCalorieActivityAnimated(),
                        SizedBox(height: 24),
                        _buildMacroDistributionAnimated(),
                        SizedBox(height: 24),
                        _buildWeightProgressAnimated(),
                        SizedBox(height: 24),
                        _buildOnTrackToGoal(),
                        SizedBox(height: 24),
                        _buildAICoachInsight(),
                        SizedBox(height: 40),
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
      leading: SizedBox(),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.trending_up, color: Colors.white, size: 18),
          ),
          SizedBox(width: 8),
          Text(
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

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isWeekly = true),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isWeekly ? Color(0xFF6366FF) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  '📊 Weekly',
                  style: TextStyle(
                    color: isWeekly ? Color(0xFF6366FF) : Colors.grey[600],
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
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: !isWeekly ? Color(0xFF6366FF) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  '📈 Monthly',
                  style: TextStyle(
                    color: !isWeekly ? Color(0xFF6366FF) : Colors.grey[600],
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

  Widget _buildStatsCardsAnimated() {
    return FadeTransition(
      opacity: _animationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        )),
        child: Row(
          children: [
            _buildStatCard(
              icon: Icons.local_fire_department,
              value: '2,045',
              label: 'Avg Calories',
              color: Color(0xFF6366FF),
            ),
            SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.water_drop,
              value: '2.4',
              label: 'Avg Water',
              color: Color(0xFF06B6D4),
            ),
            SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.speed,
              value: '10%',
              label: 'Activity',
              color: Color(0xFFFFA500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieActivityAnimated() {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
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
                    Text(
                      'Calorie Activity',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Intake vs Daily Budget',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFF3F2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Within Budget ✓',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6366FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildCalorieChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieChart() {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 500,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[200],
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  const titles = ['Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  if (value.toInt() < titles.length) {
                    return Text(
                      titles[value.toInt()],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${(value / 1000).toStringAsFixed(1)}k',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 35,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                FlSpot(0, 2100),
                FlSpot(1, 2300),
                FlSpot(2, 2050),
                FlSpot(3, 1950),
                FlSpot(4, 2200),
                FlSpot(5, 1850),
              ],
              isCurved: true,
              color: Color(0xFF6366FF),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Color(0xFF6366FF).withOpacity(0.1),
              ),
            ),
          ],
          minX: 0,
          maxX: 5,
          minY: 1500,
          maxY: 2500,
        ),
      ),
    );
  }

  Widget _buildMacroDistributionAnimated() {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Macro Distribution',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Daily average split',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20),
            _buildMacroChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroChart() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    color: Color(0xFF14B8A6),
                    value: 120,
                    title: '',
                    radius: 50,
                  ),
                  PieChartSectionData(
                    color: Color(0xFFFFA500),
                    value: 240,
                    title: '',
                    radius: 50,
                  ),
                  PieChartSectionData(
                    color: Color(0xFFEF4444),
                    value: 65,
                    title: '',
                    radius: 50,
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMacroLegendItem('Protein', '120g', Color(0xFF14B8A6)),
              SizedBox(height: 12),
              _buildMacroLegendItem('Carbs', '240g', Color(0xFFFFA500)),
              SizedBox(height: 12),
              _buildMacroLegendItem('Fats', '65g', Color(0xFFEF4444)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacroLegendItem(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeightProgressAnimated() {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weight Progress',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFF3F2FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Color(0xFF6366FF),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '🎯 Goal: 75.0',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6366FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'Current: 75.1 kg',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20),
            _buildWeightChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightChart() {
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[200],
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  const titles = ['Oct 04', 'Oct 11', 'Oct 18', 'Oct 25', 'Nov 01', 'Nov 05'];
                  if (value.toInt() < titles.length) {
                    return Text(
                      titles[value.toInt()],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  );
                },
                reservedSize: 25,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                FlSpot(0, 78.5),
                FlSpot(1, 77.2),
                FlSpot(2, 76.8),
                FlSpot(3, 76.5),
                FlSpot(4, 75.8),
                FlSpot(5, 75.3),
              ],
              isCurved: true,
              color: Color(0xFF06B6D4),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Color(0xFF06B6D4).withOpacity(0.1),
              ),
            ),
          ],
          minX: 0,
          maxX: 5,
          minY: 74,
          maxY: 79,
        ),
      ),
    );
  }

  Widget _buildOnTrackToGoal() {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFF06B6D4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.check_circle_outline,
                  color: Color(0xFF06B6D4), size: 22),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'On Track to Goal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Achieved complete: Day 15',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildAICoachInsight() {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF6366FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.auto_awesome,
                      color: Colors.white, size: 18),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI COACH INSIGHT!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your protein intake is 15% lower than last week.\nTry adding Greek yogurt or almonds to your afternoon snack to hit your muscle gain target.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.95),
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.2),
            ),
            SizedBox(height: 12),
            GestureDetector(
              onTap: () {},
              child: Row(
                children: [
                  Text(
                    'View recommendation',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios,
                      color: Colors.white, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data model for charts
class ChartData {
  final Map<String, double> weeklyCalories;
  final Map<String, double> monthlyWeight;
  final Map<String, double> macros;

  ChartData({
    required this.weeklyCalories,
    required this.monthlyWeight,
    required this.macros,
  });

  factory ChartData.sample() {
    return ChartData(
      weeklyCalories: {
        'Tue': 2100,
        'Wed': 2300,
        'Thu': 2050,
        'Fri': 1950,
        'Sat': 2200,
        'Sun': 1850,
      },
      monthlyWeight: {
        'Oct 04': 78.5,
        'Oct 11': 77.2,
        'Oct 18': 76.8,
        'Oct 25': 76.5,
        'Nov 01': 75.8,
        'Nov 05': 75.3,
      },
      macros: {
        'Protein': 120,
        'Carbs': 240,
        'Fats': 65,
      },
    );
  }
}