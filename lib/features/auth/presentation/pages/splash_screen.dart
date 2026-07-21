import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/routes.dart';
import '../../../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    // Navigate to onboarding (login will come after personalization)
    context.go(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: Stack(
        children: [
          // ── Dashed concentric rings (background decoration) ──
          Positioned.fill(
            child: CustomPaint(
              painter: _ConcentricRingsPainter(),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // ── Neumorphic card ──
                  _NeumorphicCard(screenW: screenW),

                  const Spacer(flex: 2),

                  // ── Tagline ──
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.55,
                        color: const Color(AppColors.textPrimary),
                        letterSpacing: 0.1,
                      ),
                      children: [
                        const TextSpan(text: 'The future of '),
                        TextSpan(
                          text: 'calorie tracking',
                          style: TextStyle(
                            color: const Color(AppColors.primaryLight),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: ' is\nthrough your lens.'),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ── Get Started button ──
                  _GetStartedButton(
                    onTap: () => context.go(AppRoutes.onboarding),
                  ),

                  const SizedBox(height: 24),

                  // ── Footer label ──
                  Text(
                    'POWERED BY ADVANCED VISION AI',
                    style: TextStyle(
                      fontSize: 9.5,
                      letterSpacing: 1.6,
                      color: const Color(AppColors.textSecondary),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Neumorphic card with logo, title, subtitle ──
class _NeumorphicCard extends StatelessWidget {
  final double screenW;
  const _NeumorphicCard({required this.screenW});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(AppColors.background),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFBCB8DC),
            blurRadius: 28,
            spreadRadius: 2,
            offset: Offset(10, 10),
          ),
          BoxShadow(
            color: Color(0xFFFFFFFF),
            blurRadius: 28,
            spreadRadius: 2,
            offset: Offset(-10, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lightning bolt icon
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(AppColors.authPurpleLight),
                  Color(AppColors.authPurpleDark),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(AppColors.authPurple).withValues(alpha: 0.45),
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

          const SizedBox(height: 20),

          // Title: FitFuel AI
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: const Color(AppColors.textPrimary),
              ),
              children: const [
                TextSpan(text: 'FitFuel '),
                TextSpan(
                  text: 'AI',
                  style: TextStyle(color: Color(AppColors.authPurple)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Sub-label
          Text(
            'VISIONARY NUTRITION',
            style: TextStyle(
              fontSize: 10.5,
              letterSpacing: 2.8,
              color: const Color(AppColors.textSecondary),
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 18),

          // Divider line
          Container(
            width: 36,
            height: 2.5,
            decoration: BoxDecoration(
              color: const Color(AppColors.authPurpleLight).withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Get Started button ──
class _GetStartedButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GetStartedButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(AppColors.authPurpleLight),
            Color(AppColors.authPurpleDark),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(AppColors.authPurple).withValues(alpha: 0.40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Get Started',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── CustomPainter – dashed concentric rings ──
class _ConcentricRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.38);

    final radii = [
      size.width * 0.45,
      size.width * 0.60,
      size.width * 0.78,
      size.width * 0.98,
    ];

    final paint = Paint()
      ..color = const Color(0xFFCAC6F0).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < radii.length; i++) {
      _drawDashedCircle(
        canvas: canvas,
        center: center,
        radius: radii[i],
        paint: paint,
        dashLength: i.isEven ? 4.0 : 6.0,
        gapLength: i.isEven ? 6.0 : 8.0,
      );
    }
  }

  void _drawDashedCircle({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required Paint paint,
    required double dashLength,
    required double gapLength,
  }) {
    final circumference = 2 * pi * radius;
    final dashCount = (circumference / (dashLength + gapLength)).floor();
    final anglePerStep = (2 * pi) / dashCount;
    final dashAngle = anglePerStep * (dashLength / (dashLength + gapLength));

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * anglePerStep - pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}