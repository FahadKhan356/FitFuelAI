import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Animated glassmorphic gradient background with floating glass blobs.
class OnboardingBackground extends StatelessWidget {
  const OnboardingBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8E5FB), Color(0xFFF5F5FA), Color(0xFFE0ECFF)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _GlassBlob(
              size: 220,
              color: const Color(AppColors.authPurple).withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -70,
            child: _GlassBlob(
              size: 260,
              color: const Color(AppColors.secondary).withValues(alpha: 0.15),
            ),
          ),
          Positioned(
            top: 280,
            left: -40,
            child: _GlassBlob(
              size: 140,
              color: const Color(AppColors.success).withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlassBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 60,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}