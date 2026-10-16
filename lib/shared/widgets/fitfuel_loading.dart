import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// FITFUEL AI — AAA-Grade Custom Kinetic Loading & Progress Suite
/// Features:
/// • Breathing Neon Core with App Logo / Electric Energy Symbol
/// • Dual Orbital Dynamic Progress Rings (Sweep Gradient + Glowing Comet Flare)
/// • Reversible Counter-Clockwise Particle Track
/// • Laser Shimmer Progress Pill with Live Percentage
/// • Multi-phase Subtitle Message Crossfader
/// ─────────────────────────────────────────────────────────────────────────

class FitFuelLoadingProgress extends StatefulWidget {
  const FitFuelLoadingProgress({
    super.key,
    this.progress,
    this.size = 140.0,
    this.title = 'FITFUEL AI',
    this.subtitle,
    this.statusMessages,
    this.showPercentage = true,
    this.showLinearBar = true,
    this.isDark = false,
    this.logoAsset,
    this.logoWidget,
  });

  /// Explicit progress from 0.0 to 1.0. If null, runs smooth indeterminate physics.
  final double? progress;

  /// Overall outer diameter of the circular progress ring.
  final double size;

  /// Primary branded heading.
  final String title;

  /// Static subtitle (used if [statusMessages] is null).
  final String? subtitle;

  /// Optional list of dynamic rotating status messages.
  final List<String>? statusMessages;

  /// Whether to display the live percentage number under the logo.
  final bool showPercentage;

  /// Whether to render the sleek glowing linear progress pill below.
  final bool showLinearBar;

  /// Dark mode glassmorphic styling switch.
  final bool isDark;

  /// Optional custom logo image asset (e.g., 'assets/images/app_logo.png').
  final String? logoAsset;

  /// Optional custom logo widget.
  final Widget? logoWidget;

  @override
  State<FitFuelLoadingProgress> createState() => _FitFuelLoadingProgressState();
}

class _FitFuelLoadingProgressState extends State<FitFuelLoadingProgress>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;
  late final AnimationController _messageFadeController;

  int _currentMessageIndex = 0;

  List<String> get _messages =>
      widget.statusMessages ??
      [
        'INITIALIZING NEURAL ENGINE...',
        'CALIBRATING NUTRITION MODELS...',
        'SYNCHRONIZING FITNESS METRICS...',
        'READY TO FUEL YOUR DAY...',
      ];

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _messageFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1,
    );

    if (widget.statusMessages != null || widget.subtitle == null) {
      _startMessageCycle();
    }
  }

  void _startMessageCycle() {
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) {
        return;
      }
      _messageFadeController.reverse().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _messages.length;
        });
        _messageFadeController.forward().then((_) => _startMessageCycle());
      });
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _messageFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveProgress = widget.progress?.clamp(0.0, 1.0);
    final percentageInt = effectiveProgress != null
        ? (effectiveProgress * 100).toInt()
        : null;

    final primaryTextColor = widget.isDark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF0F172A);
    final accentTextColor = widget.isDark
        ? const Color(0xFF818CF8)
        : const Color(0xFF6366F1);
    final secondaryTextColor = widget.isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Orbital Ring & Logo Core ──
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer rotating gradient track & comet head
              AnimatedBuilder(
                animation: Listenable.merge([_spinController, _pulseController]),
                builder: (context, child) => CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _FitFuelOrbitalPainter(
                    progress: effectiveProgress,
                    spinValue: _spinController.value,
                    pulseValue: _pulseController.value,
                    isDark: widget.isDark,
                  ),
                ),
              ),

              // Inner pulsing aura
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 0.94 + (_pulseController.value * 0.08);
                  final glowOpacity = 0.35 + (_pulseController.value * 0.35);

                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: widget.size * 0.58,
                      height: widget.size * 0.58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: glowOpacity),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: const Color(0xFFEC4899).withValues(alpha: glowOpacity * 0.4),
                            blurRadius: 36,
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Central App Logo Core
              _CentralLogoBadge(
                size: widget.size * 0.55,
                isDark: widget.isDark,
                logoAsset: widget.logoAsset,
                logoWidget: widget.logoWidget,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Brand Title ──
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: primaryTextColor,
            letterSpacing: 2.2,
            fontFamily: 'SF Pro Display',
          ),
        ),

        const SizedBox(height: 6),

        // ── Live Percentage Badge (if available) ──
        if (widget.showPercentage) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.14),
                  const Color(0xFFA855F7).withValues(alpha: 0.14),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  percentageInt != null
                      ? '$percentageInt%'
                      : 'AI LOADING',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: accentTextColor,
                    fontFeatures: const [ui.FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── Sleek Shimmering Linear Progress Pill ──
        if (widget.showLinearBar) ...[
          SizedBox(
            width: widget.size * 1.35,
            child: _ShimmerLinearProgressPill(
              progress: effectiveProgress,
              shimmerValue: _shimmerController.value,
              isDark: widget.isDark,
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── Kinetic Dynamic Status Subtitle ──
        FadeTransition(
          opacity: _messageFadeController,
          child: Text(
            widget.subtitle ?? _messages[_currentMessageIndex],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: secondaryTextColor,
              letterSpacing: 1.8,
              fontFamily: 'SF Pro Text',
            ),
          ),
        ),
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────
/// CENTRAL FITFUEL LOGO BADGE
/// Combines a rounded squircle with specular glass highlights and the
/// high-voltage electric energy bolt.
/// ─────────────────────────────────────────────────────────────────────────
class _CentralLogoBadge extends StatelessWidget {
  const _CentralLogoBadge({
    required this.size,
    required this.isDark,
    this.logoAsset,
    this.logoWidget,
  });

  final double size;
  final bool isDark;
  final String? logoAsset;
  final Widget? logoWidget;

  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6366F1), // Indigo 500
            Color(0xFF8B5CF6), // Purple 500
            Color(0xFF4F46E5), // Indigo 600
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 1.6,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.32),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Diagonal glass specular reflection
            Positioned(
              top: -size * 0.2,
              left: -size * 0.2,
              right: size * 0.3,
              bottom: size * 0.4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.4),
                      Colors.white.withValues(alpha: 0),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(size),
                ),
              ),
            ),

            // Logo Content: Custom Widget, Logo Asset, or Electric Bolt
            if (logoWidget != null)
              logoWidget!
            else if (logoAsset != null)
              Padding(
                padding: EdgeInsets.all(size * 0.14),
                child: Image.asset(
                  logoAsset!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => _buildDefaultBolt(),
                ),
              )
            else
              _buildDefaultBolt(),
          ],
        ),
      ),
    );

  Widget _buildDefaultBolt() => ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.white, Color(0xFFFDE047)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bounds),
      child: Icon(
        Icons.bolt_rounded,
        color: Colors.white,
        size: size * 0.62,
      ),
    );
}

/// ─────────────────────────────────────────────────────────────────────────
/// CUSTOM ORBITAL PAINTER
/// Paints sweeping conic gradient arc + glowing comet head node.
/// ─────────────────────────────────────────────────────────────────────────
class _FitFuelOrbitalPainter extends CustomPainter {
  _FitFuelOrbitalPainter({
    required this.progress,
    required this.spinValue,
    required this.pulseValue,
    required this.isDark,
  });

  final double? progress;
  final double spinValue;
  final double pulseValue;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;

    // 1. Subtle Outer Track Ring
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFE2E8F0);
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Reverse-Spinning Micro-dash Track
    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF818CF8).withValues(alpha: 0.22);

    final innerRadius = radius - 8.0;
    const dashCount = 36;
    final reverseAngle = -spinValue * 2 * math.pi;

    for (var i = 0; i < dashCount; i++) {
      if (i.isEven) {
        final startAngle = reverseAngle + (i * (2 * math.pi / dashCount));
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: innerRadius),
          startAngle,
          (2 * math.pi / dashCount) * 0.6,
          false,
          dashPaint,
        );
      }
    }

    // 3. Active Sweeping Progress Arc
    final sweepAngle = progress != null
        ? progress! * 2 * math.pi
        : math.pi * 1.35; // Indeterminate arc length

    final startAngle = progress != null
        ? -math.pi / 2
        : (spinValue * 2 * math.pi) - math.pi / 2;

    final arcRect = Rect.fromCircle(center: center, radius: radius);

    // Conic sweep gradient
    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      colors: const [
        Color(0xFF6366F1), // Indigo
        Color(0xFFA855F7), // Purple
        Color(0xFFEC4899), // Pink
        Color(0xFF06B6D4), // Cyan
        Color(0xFF6366F1),
      ],
      transform: GradientRotation(startAngle),
    );

    // Glow Bloom Pass
    final glowPaint = Paint()
      ..shader = gradient.createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(arcRect, startAngle, sweepAngle, false, glowPaint);

    // Sharp Foreground Arc
    final arcPaint = Paint()
      ..shader = gradient.createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;
    canvas.drawArc(arcRect, startAngle, sweepAngle, false, arcPaint);

    // 4. Comet Head Node (Flare circle at leading tip)
    final headAngle = startAngle + sweepAngle;
    final headX = center.dx + radius * math.cos(headAngle);
    final headY = center.dy + radius * math.sin(headAngle);
    final headCenter = Offset(headX, headY);

    // Flare shadow & solid bright node
    canvas
      ..drawCircle(
        headCenter,
        5.5 + (pulseValue * 2.0),
        Paint()
          ..color = const Color(0xFF06B6D4).withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      )
      ..drawCircle(
        headCenter,
        3.2,
        Paint()..color = Colors.white,
      );
  }

  @override
  bool shouldRepaint(covariant _FitFuelOrbitalPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.spinValue != spinValue ||
      oldDelegate.pulseValue != pulseValue;
}

/// ─────────────────────────────────────────────────────────────────────────
/// SHIMMER LINEAR PROGRESS PILL
/// ─────────────────────────────────────────────────────────────────────────
class _ShimmerLinearProgressPill extends StatelessWidget {
  const _ShimmerLinearProgressPill({
    required this.progress,
    required this.shimmerValue,
    required this.isDark,
  });

  final double? progress;
  final double shimmerValue;
  final bool isDark;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final barWidth = progress != null
            ? (totalWidth * progress!).clamp(6.0, totalWidth)
            : totalWidth;

        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: barWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFFA855F7),
                        Color(0xFF06B6D4),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),

              // Sliding laser beam effect
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: FractionallySizedBox(
                    widthFactor: 0.35,
                    alignment: Alignment(
                      (shimmerValue * 2.6) - 1.3,
                      0,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: 0.65),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
}

/// ─────────────────────────────────────────────────────────────────────────
/// FITFUEL COMPACT LOADER
/// A drop-in replacement for standard CircularProgressIndicator anywhere in
/// cards, buttons, or dialogs.
/// ─────────────────────────────────────────────────────────────────────────
class FitFuelCompactLoader extends StatefulWidget {
  const FitFuelCompactLoader({
    super.key,
    this.size = 32.0,
    this.color = const Color(0xFF6366F1),
  });

  final double size;
  final Color color;

  @override
  State<FitFuelCompactLoader> createState() => _FitFuelCompactLoaderState();
}

class _FitFuelCompactLoaderState extends State<FitFuelCompactLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating outer gradient ring
          RotationTransition(
            turns: _controller,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _CompactRingPainter(color: widget.color),
            ),
          ),
          // Center micro bolt
          Icon(
            Icons.bolt_rounded,
            color: widget.color,
            size: widget.size * 0.52,
          ),
        ],
      ),
    );
}

class _CompactRingPainter extends CustomPainter {
  const _CompactRingPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.4),
          color,
        ],
      ).createShader(rect);

    canvas.drawArc(rect, 0, math.pi * 1.5, false, paint);
  }

  @override
  bool shouldRepaint(covariant _CompactRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// ─────────────────────────────────────────────────────────────────────────
/// FITFUEL FULLSCREEN LOADING OVERLAY DIALOG
/// Helper utility to display a modal loading overlay during async processes.
/// ─────────────────────────────────────────────────────────────────────────
class FitFuelLoadingOverlay {
  static void show(
    BuildContext context, {
    String title = 'FITFUEL AI',
    String? message,
    List<String>? statusMessages,
    double? progress,
    String? logoAsset,
    Widget? logoWidget,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) => PopScope(
        canPop: false,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 36,
                    offset: const Offset(0, 14),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 1.5,
                ),
              ),
              child: FitFuelLoadingProgress(
                size: 130,
                title: title,
                subtitle: message,
                statusMessages: statusMessages,
                progress: progress,
                logoAsset: logoAsset,
                logoWidget: logoWidget,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
