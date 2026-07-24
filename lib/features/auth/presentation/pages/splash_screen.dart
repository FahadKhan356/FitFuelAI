import 'dart:math' as math;

import 'package:fitfuel_ai/core/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;
  late final AnimationController _progressController;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _initInitializationProcess();
  }

  Future<void> _initInitializationProcess() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted || _navigated) return;
    _navigated = true;
    HapticFeedback.mediumImpact();
    
    // Check if user is already logged in
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      // User is logged in, go to home
      context.go(AppRoutes.home);
    } else {
      // User is not logged in, go to onboarding
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height * 0.18,
              child: AnimatedBuilder(
                animation: Listenable.merge([_rotationController, _pulseController]),
                builder: (context, child) {
                  final pulse = (math.sin(_pulseController.value * math.pi * 2) + 1) / 2;
                  final opacity = 0.4 + (pulse * 0.45);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: -_rotationController.value * 2 * math.pi * (15 / 18),
                        child: CustomPaint(
                          size: const Size(320, 320),
                          painter: DottedCirclePainter(
                            color: const Color(0xFF818CF8).withValues(alpha: opacity * 0.30),
                            dashCount: 40,
                            strokeWidth: 1.2,
                          ),
                        ),
                      ),
                      Transform.rotate(
                        angle: _rotationController.value * 2 * math.pi,
                        child: CustomPaint(
                          size: const Size(260, 260),
                          painter: DottedCirclePainter(
                            color: const Color(0xFF6366F1).withValues(alpha: opacity * 0.40),
                            dashCount: 24,
                            strokeWidth: 1.5,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const _CentralOrb(),
                  const SizedBox(height: 28),
                  const Text(
                    'FITFUEL AI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'ADVANCED VISUAL NUTRITION',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 132),
                  const Text(
                    'INITIALIZING NEURAL ENGINE...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF818CF8),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 40),
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return _ProgressPill(progress: _progressController.value);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'VER 2.4.0 • DISTRIBUTED INTELLIGENCE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CentralOrb extends StatelessWidget {
  const _CentralOrb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 122,
      height: 122,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.64),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.38),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: Colors.white,
            size: 38,
          ),
        ),
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 150 * progress,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class DottedCirclePainter extends CustomPainter {
  final Color color;
  final int dashCount;
  final double strokeWidth;

  DottedCirclePainter({
    required this.color,
    required this.dashCount,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = (2 * math.pi) / dashCount;

    for (int i = 0; i < dashCount; i++) {
      if (i % 2 == 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          i * sweepAngle,
          sweepAngle * 0.6,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant DottedCirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dashCount != dashCount ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
