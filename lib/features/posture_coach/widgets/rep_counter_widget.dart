import 'package:flutter/material.dart';

class RepCounterWidget extends StatelessWidget {
  final int repCount;
  final int setCount;
  final int targetSets;

  const RepCounterWidget({
    super.key,
    required this.repCount,
    required this.setCount,
    required this.targetSets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$repCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'REPS',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            width: 44,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 8),
          Text(
            'SET $setCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            'of $targetSets',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
