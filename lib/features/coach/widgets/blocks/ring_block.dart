import 'package:flutter/material.dart';
import '../../models/coach_response.dart';

/// Single circular progress ring block matching the snapshot strip aesthetics.
class RingBlock extends StatelessWidget {
  const RingBlock({super.key, required this.block});

  final CoachBlock block;

  @override
  Widget build(BuildContext context) {
    final double target = block.target > 0 ? block.target : 2000;
    final double value = block.value;
    final double ratio = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    final int percent = (ratio * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FF).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                  backgroundColor: const Color(0xFFE3DEFF),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5B4BDB)),
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1B3A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.title.isNotEmpty ? block.title : 'Target progress',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1B3A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${value.toInt()} of ${target.toInt()} ${block.unit}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7A7699),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
