import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Supported visual states of the AI Intelligence Orb.
enum OrbState { idle, thinking, speaking }

/// Organic, breathing 3-layer AI Intelligence Orb background widget.
///
/// Driven by a single [AnimationController] with CustomPainter wrapped in a
/// [RepaintBoundary]. Does not call setState on the parent screen.
class AiOrbBackground extends StatefulWidget {
  const AiOrbBackground({
    super.key,
    this.state = OrbState.idle,
    this.centerYRatio = 0.45,
  });

  final OrbState state;
  final double centerYRatio;

  @override
  State<AiOrbBackground> createState() => _AiOrbBackgroundState();
}

class _AiOrbBackgroundState extends State<AiOrbBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    // 280 seconds duration ensures a huge least common multiple for all layer cycles
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 280),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (disableAnimations) {
      return RepaintBoundary(
        child: CustomPaint(
          painter: _AiOrbPainter(
            progress: 0.0,
            state: widget.state,
            centerYRatio: widget.centerYRatio,
          ),
          size: Size.infinite,
        ),
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => CustomPaint(
          painter: _AiOrbPainter(
            progress: _ctrl.value,
            state: widget.state,
            centerYRatio: widget.centerYRatio,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _AiOrbPainter extends CustomPainter {
  _AiOrbPainter({
    required this.progress,
    required this.state,
    required this.centerYRatio,
  });

  final double progress;
  final OrbState state;
  final double centerYRatio;

  // Statically assigned unique speeds and phases for 8 points per layer
  // so shapes morph organically and never visibly repeat.
  static const List<double> _speeds1 = [1.0, 1.25, 0.85, 1.4, 0.95, 1.15, 0.75, 1.3];
  static const List<double> _phases1 = [0.0, 1.2, 2.4, 3.8, 5.1, 0.9, 2.7, 4.3];

  static const List<double> _speeds2 = [0.9, 1.1, 1.35, 0.8, 1.2, 0.95, 1.15, 0.7];
  static const List<double> _phases2 = [1.5, 3.1, 0.4, 4.7, 2.2, 5.8, 1.0, 3.9];

  static const List<double> _speeds3 = [1.15, 0.75, 1.05, 1.3, 0.85, 1.25, 0.9, 1.4];
  static const List<double> _phases3 = [3.4, 0.8, 5.2, 2.1, 4.0, 1.7, 3.5, 0.2];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final Offset center = Offset(size.width * 0.5, size.height * centerYRatio);

    // Speed multiplier based on state
    final double speedMult = state == OrbState.thinking ? 2.0 : 1.0;
    final double elapsedSec = progress * 280.0 * speedMult;

    // ─────────────────────────────────────────────
    // 1. Center Soft White Glow (46 px radial)
    // ─────────────────────────────────────────────
    final Paint centerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: state == OrbState.thinking ? 0.95 : 0.80),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 46.0));
    canvas.drawCircle(center, 46.0, centerGlow);

    // ─────────────────────────────────────────────
    // 2. Breathing Scales over 8s sine cycle
    // (Layer 2 delayed by 0.6s, Layer 3 by 1.2s for fluid organic motion)
    // ─────────────────────────────────────────────
    final double breathCycle = (2 * math.pi) / 8.0;
    final double breathAmp = state == OrbState.speaking ? 0.14 : 0.10;

    final double scale1 = 1.0 + breathAmp * math.sin(elapsedSec * breathCycle);
    final double scale2 = 1.0 + breathAmp * math.sin((elapsedSec - 0.6) * breathCycle);
    final double scale3 = 1.0 + breathAmp * math.sin((elapsedSec - 1.2) * breathCycle);

    // Rotation angles
    final double rot1 = (2 * math.pi) * (elapsedSec / 40.0);
    final double rot2 = -(2 * math.pi) * (elapsedSec / 55.0);
    final double rot3 = (2 * math.pi) * (elapsedSec / 70.0);

    // Morph cycle progress
    final double t1 = (2 * math.pi) * (elapsedSec / 14.0);
    final double t2 = (2 * math.pi) * (elapsedSec / 16.0);
    final double t3 = (2 * math.pi) * (elapsedSec / 20.0);

    // ─────────────────────────────────────────────
    // 3. Layer 1 (Inner, Filled ~170 px)
    // ─────────────────────────────────────────────
    final Path path1 = _createSmoothBlob(
      center: center,
      baseRadius: 85.0 * scale1,
      t: t1,
      rotation: rot1,
      speeds: _speeds1,
      phases: _phases1,
      amp: 0.14,
    );

    final Paint fillPaint1 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35), // Top-left highlight
        radius: 1.0,
        colors: [
          Color.fromRGBO(237, 233, 255, state == OrbState.thinking ? 0.98 : 0.90),
          Color.fromRGBO(167, 155, 250, state == OrbState.thinking ? 0.68 : 0.55),
          Color.fromRGBO(124, 108, 240, state == OrbState.thinking ? 0.35 : 0.25),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 95.0 * scale1));

    canvas.drawPath(path1, fillPaint1);

    // ─────────────────────────────────────────────
    // 4. Layer 2 (Outline ~200 px, stroke 1.2 px)
    // ─────────────────────────────────────────────
    final Path path2 = _createSmoothBlob(
      center: center,
      baseRadius: 100.0 * scale2,
      t: t2,
      rotation: rot2,
      speeds: _speeds2,
      phases: _phases2,
      amp: 0.16,
    );

    final Paint strokePaint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color.fromRGBO(124, 108, 240, 0.50);

    canvas.drawPath(path2, strokePaint2);

    // ─────────────────────────────────────────────
    // 5. Layer 3 (Outer Outline ~232 px, stroke 1.0 px)
    // ─────────────────────────────────────────────
    final Path path3 = _createSmoothBlob(
      center: center,
      baseRadius: 116.0 * scale3,
      t: t3,
      rotation: rot3,
      speeds: _speeds3,
      phases: _phases3,
      amp: 0.18,
    );

    final Paint strokePaint3 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color.fromRGBO(124, 108, 240, 0.22);

    canvas.drawPath(path3, strokePaint3);
  }

  /// Constructs a closed smooth organic blob curve from 8 radially perturbed points
  /// using Catmull-Rom to cubic Bézier spline interpolation.
  Path _createSmoothBlob({
    required Offset center,
    required double baseRadius,
    required double t,
    required double rotation,
    required List<double> speeds,
    required List<double> phases,
    required double amp,
  }) {
    const int count = 8;
    final List<Offset> points = [];

    for (int i = 0; i < count; i++) {
      final double angle = rotation + (i * 2 * math.pi / count);
      final double r = baseRadius * (1.0 + amp * math.sin(t * speeds[i] + phases[i]));
      points.add(Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      ));
    }

    final Path path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < count; i++) {
      final p0 = points[(i - 1 + count) % count];
      final p1 = points[i];
      final p2 = points[(i + 1) % count];
      final p3 = points[(i + 2) % count];

      // Catmull-Rom to Cubic Bézier control points
      final cp1x = p1.dx + (p2.dx - p0.dx) / 6.0;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6.0;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6.0;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6.0;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _AiOrbPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.state != state ||
      oldDelegate.centerYRatio != centerYRatio;
}
