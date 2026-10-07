import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ProgressCircle extends StatelessWidget {

  const ProgressCircle({
    required this.value, Key? key,
    this.size = 100,
    this.color,
    this.backgroundColor,
    this.label,
  }) : super(key: key);
  final double value;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final String? label;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation(
                color ?? const Color(AppColors.primary),
              ),
              backgroundColor: backgroundColor ?? const Color(AppColors.card),
            ),
          ),
          if (label != null)
            Center(
              child: Text(
                label!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
        ],
      ),
    );
}

class MacroCard extends StatelessWidget {

  const MacroCard({
    required this.label, required this.value, required this.goal, required this.color, required this.progress, Key? key,
  }) : super(key: key);
  final String label;
  final String value;
  final String goal;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppColors.card),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(AppColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('/ $goal', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(AppColors.borderLight),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
}

class StatCard extends StatelessWidget {

  const StatCard({
    required this.label, required this.value, Key? key,
    this.change,
    this.positive = true,
    this.backgroundColor,
  }) : super(key: key);
  final String label;
  final String value;
  final String? change;
  final bool positive;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(AppColors.card),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(AppColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          if (change != null) ...[
            const SizedBox(height: 8),
            Text(
              change!,
              style: TextStyle(
                color: positive ? const Color(AppColors.success) : const Color(AppColors.error),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
}
