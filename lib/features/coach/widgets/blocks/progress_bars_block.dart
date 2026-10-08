import 'package:flutter/material.dart';
import '../../models/coach_response.dart';

/// Progress bars block: height 6, rounded, track in soft tint, fill in given color.
class ProgressBarsBlock extends StatelessWidget {
  const ProgressBarsBlock({super.key, required this.block});

  final CoachBlock block;

  Color _resolveColor(String name) {
    switch (name.toLowerCase()) {
      case 'protein':
        return const Color(0xFFF97316);
      case 'water':
        return const Color(0xFF06B6D4);
      case 'calories':
      default:
        return const Color(0xFF5B4BDB);
    }
  }

  Color _resolveTrack(String name) {
    switch (name.toLowerCase()) {
      case 'protein':
        return const Color(0xFFFFE4C7);
      case 'water':
        return const Color(0xFFCFF3F8);
      case 'calories':
      default:
        return const Color(0xFFEDE9FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = block.items.whereType<CoachProgressBarItem>().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.title.isNotEmpty) ...[
          Text(
            block.title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A4670),
            ),
          ),
          const SizedBox(height: 8),
        ],
        for (final item in items) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E1B3A),
                      ),
                    ),
                    Text(
                      '${item.value.toInt()} / ${item.target.toInt()} ${item.unit}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7A7699),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: item.target > 0 ? (item.value / item.target).clamp(0.0, 1.0) : 0.0,
                    minHeight: 6,
                    backgroundColor: _resolveTrack(item.color),
                    valueColor: AlwaysStoppedAnimation<Color>(_resolveColor(item.color)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
