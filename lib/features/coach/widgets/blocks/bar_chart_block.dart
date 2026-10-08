import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/coach_response.dart';

/// Interactive 160px BarChart block with dashed target line and rounded bars.
class BarChartBlock extends StatelessWidget {
  const BarChartBlock({super.key, required this.block});

  final CoachBlock block;

  @override
  Widget build(BuildContext context) {
    final xLabels = block.x;
    final yValues = block.y;
    final double target = block.target > 0 ? block.target : 2500;

    double maxY = target * 1.15;
    for (final v in yValues) {
      if (v > maxY) maxY = v * 1.15;
    }
    if (maxY <= 0) maxY = 100;

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
                'Target: ${target.toInt()} ${block.unit}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5B4BDB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              minY: 0,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF1E1B3A),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final label = groupIndex < xLabels.length ? xLabels[groupIndex] : '';
                    return BarTooltipItem(
                      '$label: ${rod.toY.toInt()} ${block.unit}',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    );
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
                horizontalInterval: target > 0 ? target : 1000,
                getDrawingHorizontalLine: (value) {
                  if ((value - target).abs() < (target * 0.1)) {
                    // Dashed target line
                    return const FlLine(
                      color: Color(0xFF5B4BDB),
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
              barGroups: [
                for (int i = 0; i < yValues.length; i++)
                  BarChartGroupData(
                    x: i,
                    showingTooltipIndicators: (i >= yValues.length - 2 && yValues[i] > 0) ? [0] : [],
                    barRods: [
                      BarChartRodData(
                        toY: yValues[i],
                        color: const Color(0xFF5B4BDB),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: const Color(0xFFEDE9FF).withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
