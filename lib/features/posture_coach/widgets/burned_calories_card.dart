import 'package:flutter/material.dart';
import '../services/calories_calculator.dart';

class BurnedCaloriesCard extends StatefulWidget {
  const BurnedCaloriesCard({super.key});

  @override
  State<BurnedCaloriesCard> createState() => _BurnedCaloriesCardState();
}

class _BurnedCaloriesCardState extends State<BurnedCaloriesCard> {
  double _totalBurned = 0;
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final total = await CaloriesCalculator.fetchTodayBurned();
    final sessions = await CaloriesCalculator.fetchTodaySessions();
    if (mounted) {
      setState(() {
        _totalBurned = total;
        _sessions = sessions;
        _loading = false;
      });
    }
  }

  // Emoji per exercise
  String _emoji(String name) {
    const map = {
      'Squat': '🏋️',
      'Push-up': '💪',
      'Lunge': '🦵',
      'Plank': '⚡',
      'Bicep Curl': '🏋️',
      'Shoulder Press': '🙆',
      'Deadlift': '🔥',
      'Pull-up': '🦾',
      'Lateral Raise': '🏅',
      'Sit-up': '🎯',
    };
    return map[name] ?? '💪';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF5B4EE8),
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E6F5)),
      ),
      child: Column(
        children: [
          // Header row (always visible)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Flame icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDE6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFE53935),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BURNED TODAY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8A8A9A),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${_totalBurned.round()}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF14142B),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const TextSpan(
                                text: ' kcal',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF8A8A9A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expand/collapse
                  if (_sessions.isNotEmpty)
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF8A8A9A),
                    ),
                ],
              ),
            ),
          ),

          // Expanded: per-exercise breakdown
          if (_expanded && _sessions.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFE8E6F5)),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              itemCount: _sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final s = _sessions[i];
                final name = s['exercise_name'] as String;
                final kcal = (s['calories_burned'] as num).round();
                final sets = (s['sets_completed'] as num?)?.toInt() ?? 0;
                final reps = (s['reps_completed'] as num?)?.toInt() ?? 0;
                final dur = (s['duration_seconds'] as num?)?.toInt() ?? 0;

                return Row(
                  children: [
                    Text(_emoji(name), style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF14142B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            name == 'Plank'
                                ? '${dur}s hold'
                                : '$sets sets × $reps reps',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF8A8A9A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDE6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$kcal kcal',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE53935),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],

          // Empty state
          if (_sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'No workouts today — start one in AI Posture Coach 💪',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8A8A9A),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
