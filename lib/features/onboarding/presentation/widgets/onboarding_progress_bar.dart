import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Animated step progress bar shown at the top of the onboarding flow.
class OnboardingProgressBar extends StatelessWidget {
  final int stepIndex;
  final int totalSteps;

  const OnboardingProgressBar({
    super.key,
    required this.stepIndex,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: Colors.white.withValues(alpha: 0.6),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        width: (MediaQuery.of(context).size.width - 48) *
            ((stepIndex + 1) / totalSteps),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: const LinearGradient(
            colors: [Color(AppColors.authPurple), Color(AppColors.secondary)],
          ),
        ),
      ),
    );
  }
}