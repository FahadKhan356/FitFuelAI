import 'dart:async';
import 'dart:math' as math;

import 'package:fitfuel_ai/core/config/routes.dart';
import 'package:fitfuel_ai/core/services/home_data_cache.dart';
import 'package:fitfuel_ai/shared/widgets/fitfuel_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  Timer? _initializationTimer;

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
    _initializationTimer = Timer(
      const Duration(seconds: 3),
      _resolveInitialRoute,
    );
  }

  Future<void> _resolveInitialRoute() async {
    if (!mounted || _navigated) {
      return;
    }
    _navigated = true;
    unawaited(HapticFeedback.mediumImpact());

    // Check if this is the first time user is opening the app
    final prefs = await SharedPreferences.getInstance();
    final hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;

    // Check if user is already logged in
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      var shouldGoHome = hasCompletedOnboarding;
      if (!shouldGoHome) {
        // If not completed locally, check DB to see if they already have a profile
        try {
          final response = await Supabase.instance.client
              .from('user_profiles')
              .select('user_id')
              .eq('user_id', currentUser.id)
              .limit(1);
          if (response is List && response.isNotEmpty) {
            await prefs.setBool('onboarding_completed', true);
            shouldGoHome = true;
          }
        } on Exception catch (_) {}
      }

      if (shouldGoHome) {
        try {
          await HomeDataCache.loadPersistent(currentUser.id);
        } on Exception catch (_) {}
      }

      if (!mounted) {
        return;
      }
      // User is already logged in:
      // - Onboarding complete → straight to Home dashboard
      // - Onboarding pending (e.g. new signup) → OnboardingFlow first
      context.go(shouldGoHome ? AppRoutes.home : AppRoutes.onboarding);
    } else if (hasCompletedOnboarding) {
      if (!mounted) {
        return;
      }
      // Returning user who completed onboarding → go to login
      context.go(AppRoutes.login);
    } else {
      if (!mounted) {
        return;
      }
      // Brand new user: show onboarding first (can save locally), then prompt login
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _initializationTimer?.cancel();
    _rotationController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) => FitFuelLoadingProgress(
                  size: 145,
                  progress: _progressController.value,
                  title: 'FITFUEL AI',
                  logoAsset: 'assets/images/app_logo.png',
                  showPercentage: true,
                  showLinearBar: true,
                  statusMessages: const [
                    'INITIALIZING NEURAL ENGINE...',
                    'SYNCHRONIZING PROFILE & METRICS...',
                    'CALIBRATING VISUAL NUTRITION...',
                    'PREPARING AI DASHBOARD...',
                  ],
                ),
              ),
            ),
            const Positioned(
              bottom: 24,
              child: Text(
                'VER 2.4.0 • DISTRIBUTED INTELLIGENCE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}


class DottedCirclePainter extends CustomPainter {

  DottedCirclePainter({
    required this.color,
    required this.dashCount,
    required this.strokeWidth,
  });
  final Color color;
  final int dashCount;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = (2 * math.pi) / dashCount;

    for (var i = 0; i < dashCount; i++) {
      if (i.isEven) {
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
  bool shouldRepaint(covariant DottedCirclePainter oldDelegate) => oldDelegate.color != color ||
        oldDelegate.dashCount != dashCount ||
        oldDelegate.strokeWidth != strokeWidth;
}
