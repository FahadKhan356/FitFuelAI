import 'package:flutter/material.dart';

class StatsSummaryWidget extends StatelessWidget {
  final String timerDisplay;
  final int repCount;
  final int completedSets;
  final VoidCallback onDone;

  const StatsSummaryWidget({
    super.key,
    required this.timerDisplay,
    required this.repCount,
    required this.completedSets,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181826) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : const Color(0xFFE8E6F5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B4EE8), Color(0xFF7B6FF0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B4EE8).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Session Complete!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF14142B),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Great workout form and discipline kept today.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : const Color(0xFF8A8A9A),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF222236)
                  : const Color(0xFFF5F5FA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE8E6F5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(
                  emoji: '⏱',
                  value: timerDisplay,
                  label: 'Duration',
                  isDark: isDark,
                ),
                Container(
                  width: 1,
                  height: 38,
                  color: isDark ? Colors.white12 : const Color(0xFFE2E0F0),
                ),
                _StatItem(
                  emoji: '🔁',
                  value: '$repCount',
                  label: 'Reps Done',
                  isDark: isDark,
                ),
                Container(
                  width: 1,
                  height: 38,
                  color: isDark ? Colors.white12 : const Color(0xFFE2E0F0),
                ),
                _StatItem(
                  emoji: '💪',
                  value: '$completedSets',
                  label: 'Sets Done',
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B4EE8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final bool isDark;

  const _StatItem({
    required this.emoji,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF14142B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : const Color(0xFF8A8A9A),
          ),
        ),
      ],
    );
  }
}
