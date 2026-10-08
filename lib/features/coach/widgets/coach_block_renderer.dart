import 'package:flutter/material.dart';

import '../models/coach_response.dart';
import 'blocks/bar_chart_block.dart';
import 'blocks/line_chart_block.dart';
import 'blocks/progress_bars_block.dart';
import 'blocks/ring_block.dart';

/// Renders structured coach blocks safely with 10 px vertical spacing.
class CoachBlockRenderer extends StatelessWidget {
  const CoachBlockRenderer({super.key, required this.blocks});

  final List<CoachBlock> blocks;

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) return const SizedBox.shrink();

    final List<Widget> children = [];

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      Widget? rendered;

      switch (block.type) {
        case 'progress_bars':
          rendered = ProgressBarsBlock(block: block);
          break;
        case 'bar_chart':
          rendered = BarChartBlock(block: block);
          break;
        case 'line_chart':
          rendered = LineChartBlock(block: block);
          break;
        case 'ring':
          rendered = RingBlock(block: block);
          break;
        case 'stat_row':
          rendered = _buildStatRow(block);
          break;
        default:
          rendered = null; // Unknown types ignored safely
      }

      if (rendered != null) {
        if (children.isNotEmpty) {
          children.add(const SizedBox(height: 10));
        }
        children.add(rendered);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildStatRow(CoachBlock block) {
    final items = block.items.whereType<CoachStatRowItem>().toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FF).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    items[i].label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF7A7699),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    items[i].value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E1B3A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
