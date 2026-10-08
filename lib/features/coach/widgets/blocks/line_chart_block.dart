import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/coach_response.dart';

/// Interactive 160px LineChart block with dashed target line and smooth curve.
class LineChartBlock extends StatelessWidget {
  const LineChartBlock({super.key, required this.block});

  final CoachBlock block;

  @override
  Widget build(BuildContext context) {
    final xLabels = block.x;
    final yValues = block.y;
    final double target = block.target > 0 ? block.target : 2.5;

    double maxY = target * 1.2;
    for (final v in yValues) {
      if (v > maxY) maxY = v * 1.2;
    }
    if (maxY <= 0) maxY = 5.0;

    final spots = <FlSpot>[];
    for (int i = 0; i < yValues.length; i++) {
      spots.add(FlSpot(i.toDouble(), yValues[i]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.title.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                block.title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A4670),
                ),
              ),
              Text(
                'Target: $target ${block.unit}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF06B6D4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              maxY: maxY,
              minY: 0,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF1E1B3A),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      final label = index < xLabels.length ? xLabels[index] : '';
                      return LineTooltipItem(
                        '$label: ${spot.y.toStringAsFixed(1)} ${block.unit}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= xLabels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          xLabels[index],
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF7A7699),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: target > 0 ? target : 1.0,
                getDrawingHorizontalLine: (value) {
                  if ((value - target).abs() < (target * 0.15)) {
                    // Dashed target line
                    return const FlLine(
                      color: Color(0xFF06B6D4),
                      strokeWidth: 1.2,
                      dashArray: [4, 4],
                    );
                  }
                  return const FlLine(
                    color: Color(0xFFEDE9FF),
                    strokeWidth: 0.8,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: const Color(0xFF06B6D4),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 3.5,
                      color: const Color(0xFF06B6D4),
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF06B6D4).withValues(alpha: 0.28),
                        const Color(0xFF06B6D4).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
