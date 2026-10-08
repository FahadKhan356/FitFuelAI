import 'dart:ui';
import 'package:flutter/material.dart';

import '../providers/daily_summary_provider.dart';

/// Top snapshot strip containing 3 glass cards with 46 px animated progress rings.
class SnapshotStrip extends StatefulWidget {
  const SnapshotStrip({
    super.key,
    this.onTapRing,
    this.onRingTap,
    this.summary,
  });

  final ValueChanged<String>? onTapRing;
  final ValueChanged<String>? onRingTap;
  final DailySummary? summary;

  ValueChanged<String>? get callback => onRingTap ?? onTapRing;

  @override
  State<SnapshotStrip> createState() => _SnapshotStripState();
}

class _SnapshotStripState extends State<SnapshotStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _curveAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _curveAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([dailySummaryProvider, _curveAnim]),
      builder: (context, _) {
        final summary = widget.summary ?? dailySummaryProvider.summary;
        final double animValue = _curveAnim.value;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // 1. Calories Ring Glass Card
              Expanded(
                child: _buildGlassCard(
                  context: context,
                  ratio: summary.calorieRatio * animValue,
                  percentText: '${(summary.caloriePercent * animValue).round()}%',
                  valueLabel: summary.caloriesLabel,
                  progressColor: const Color(0xFF5B4BDB),
                  trackColor: const Color(0xFFE3DEFF),
                  semanticLabel: 'Calories ${summary.caloriesConsumed} of ${summary.caloriesGoal}',
                  onTap: () => widget.callback?.call("How is my calorie balance today?"),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Water Ring Glass Card
              Expanded(
                child: _buildGlassCard(
                  context: context,
                  ratio: summary.waterRatio * animValue,
                  percentText: '${(summary.waterPercent * animValue).round()}%',
                  valueLabel: summary.waterL,
                  progressColor: const Color(0xFF06B6D4),
                  trackColor: const Color(0xFFCFF3F8),
                  semanticLabel: 'Water ${summary.waterL} of ${(summary.waterGoalMl / 1000).toStringAsFixed(1)} L',
                  onTap: () => widget.callback?.call("How is my hydration today?"),
                ),
              ),
              const SizedBox(width: 10),

              // 3. Protein Ring Glass Card
              Expanded(
                child: _buildGlassCard(
                  context: context,
                  ratio: summary.proteinRatio * animValue,
                  percentText: '${(summary.proteinPercent * animValue).round()}%',
                  valueLabel: summary.proteinLabel,
                  progressColor: const Color(0xFFF97316),
                  trackColor: const Color(0xFFFFE4C7),
                  semanticLabel: 'Protein ${summary.proteinG.toInt()} g of ${summary.proteinGoalG.toInt()} g',
                  onTap: () => widget.callback?.call("How is my protein intake today?"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlassCard({
    required BuildContext context,
    required double ratio,
    required String percentText,
    required String valueLabel,
    required Color progressColor,
    required Color trackColor,
    required String semanticLabel,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.80),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B4BDB).withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 46 px circular progress ring
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: ratio.clamp(0.0, 1.0),
                          strokeWidth: 4.5,
                          strokeCap: StrokeCap.round,
                          backgroundColor: trackColor,
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        ),
                        Text(
                          percentText,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E1B3A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    valueLabel,
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
        ),
      ),
    );
  }
}
