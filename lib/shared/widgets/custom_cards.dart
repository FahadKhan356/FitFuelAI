import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ProgressCircle extends StatelessWidget {
  final double value;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final String? label;

  const ProgressCircle({
    Key? key,
    required this.value,
    this.size = 100,
    this.color,
    this.backgroundColor,
    this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                color ?? Color(AppColors.primary),
              ),
              backgroundColor: backgroundColor ?? Color(AppColors.card),
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
}

class MacroCard extends StatelessWidget {
  final String label;
  final String value;
  final String goal;
  final Color color;
  final double progress;

  const MacroCard({
    Key? key,
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
    required this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(AppColors.card),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(AppColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 4),
          Text('/ $goal', style: Theme.of(context).textTheme.labelSmall),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Color(AppColors.borderLight),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? change;
  final bool positive;
  final Color? backgroundColor;

  const StatCard({
    Key? key,
    required this.label,
    required this.value,
    this.change,
    this.positive = true,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Color(AppColors.card),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(AppColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          if (change != null) ...[
            SizedBox(height: 8),
            Text(
              change!,
              style: TextStyle(
                color: positive ? Color(AppColors.success) : Color(AppColors.error),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
