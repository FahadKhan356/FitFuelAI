import 'package:fitfuel_ai/core/config/routes.dart';
import 'package:fitfuel_ai/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

const _bg = Color(0xFFF5F5FA);
const _surface = Colors.white;
const _purple = Color(AppColors.authPurple);
const _purpleLight = Color(AppColors.authPurpleBg);
const _purpleSoft = Color(0xFFEAE6FF);
const _textPrimary = Color(0xFF1F1F2E);
const _textSecondary = Color(0xFF6F6F7C);
const _border = Color(0xFFE6E4EE);

double _clamp01(double v) => v.clamp(0.0, 1.0);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _rotateCtrl;
  late final AnimationController _flameCtrl;
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    )..forward();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat(reverse: true);
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _flameCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _floatCtrl.dispose();
    _rotateCtrl.dispose();
    _flameCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 14),
                child: Row(
                  children: [
                    Text(
                      'Profile',
                      style: textTheme.headlineSmall?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const Spacer(),
                    _TopIconButton(
                      icon: Icons.workspace_premium_outlined,
                      onTap: () => context.push(AppRoutes.subscription),
                    ),
                    const SizedBox(width: 6),
                    _TopIconButton(
                      icon: Icons.settings_outlined,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: const Color(0xFFEDEAF3)),
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    // ── A. Avatar with Halo Pulse & Floating Physics ──
                    _AvatarWithBadge(
                      floatCtrl: _floatCtrl,
                      rotateCtrl: _rotateCtrl,
                      mainCtrl: _mainCtrl,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Alex Johnson',
                      style: TextStyle(
                        fontSize: 30,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Level 14 Fitness Enthusiast',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    _PremiumPill(mainCtrl: _mainCtrl, shimmerCtrl: _shimmerCtrl),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              // ── B. Metric Cards ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        mainCtrl: _mainCtrl,
                        flameCtrl: _flameCtrl,
                        icon: Icons.local_fire_department_outlined,
                        iconBackground: const Color(0xFFFFF0DE),
                        iconColor: const Color(0xFFF4A340),
                        label: 'STREAK',
                        targetValue: '12',
                        suffix: ' Days',
                        subtitle: 'Keep it up, Alex!',
                        index: 0,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _MetricCard(
                        mainCtrl: _mainCtrl,
                        flameCtrl: _flameCtrl,
                        icon: Icons.trending_down_rounded,
                        iconBackground: const Color(0xFFE1F8E9),
                        iconColor: const Color(0xFF44B97A),
                        label: 'WEIGHT\nLOST',
                        targetValue: '4.2',
                        suffix: ' kg',
                        subtitle: 'Since Jan 2024',
                        index: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      size: 21,
                      color: _textPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Achievements',
                      style: textTheme.headlineSmall?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.achievements),
                      child: Text(
                        'View All',
                        style: textTheme.titleSmall?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _purple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ── C. Achievement Badges ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _AchievementItem(
                        mainCtrl: _mainCtrl,
                        index: 0,
                        icon: Icons.bolt_rounded,
                        label: 'Early Riser',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AchievementItem(
                        mainCtrl: _mainCtrl,
                        index: 1,
                        icon: Icons.water_drop_outlined,
                        label: 'H2O Master',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AchievementItem(
                        mainCtrl: _mainCtrl,
                        index: 2,
                        icon: Icons.center_focus_strong,
                        label: 'Macro King',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              // ── D. Today's Goals Card ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _GoalsCard(
                  textTheme: textTheme,
                  mainCtrl: _mainCtrl,
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'ACCOUNT SETTINGS',
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: const Color(0xFF77757E),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // ── E. Settings Menu ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _SettingTile(
                      mainCtrl: _mainCtrl,
                      index: 0,
                      icon: Icons.shield_outlined,
                      title: 'Personal Information',
                    ),
                    const SizedBox(height: 10),
                    _SettingTile(
                      mainCtrl: _mainCtrl,
                      index: 1,
                      icon: Icons.credit_card_outlined,
                      title: 'Premium Subscription',
                      trailingText: 'Active',
                    ),
                    const SizedBox(height: 10),
                    _SettingTile(
                      mainCtrl: _mainCtrl,
                      index: 2,
                      icon: Icons.notifications_none_outlined,
                      title: 'Notifications',
                      trailingText: 'Daily Reminders',
                    ),
                    const SizedBox(height: 10),
                    _SettingTile(
                      mainCtrl: _mainCtrl,
                      index: 3,
                      icon: Icons.adjust_outlined,
                      title: 'Health Goals',
                      trailingText: 'Weight Loss',
                      onTap: () => context.push(AppRoutes.weightTracker),
                    ),
                    const SizedBox(height: 10),
                    _SettingTile(
                      mainCtrl: _mainCtrl,
                      index: 4,
                      icon: Icons.monitor_weight_rounded,
                      title: 'BMI Calculator',
                      trailingText: 'Quick check',
                      onTap: () => context.push(AppRoutes.bmi),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SettingTile(
                  mainCtrl: _mainCtrl,
                  index: 4,
                  icon: Icons.logout_rounded,
                  title: 'Logout Account',
                  isLogout: true,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'NutriLens AI v2.4.0 • Crafted for Health',
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8B8797),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Top Icon Button
// ─────────────────────────────────────────────
class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 24, color: const Color(0xFF4C4A59)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  A. Avatar With Badge – Floating + Rotating Ring + Spring Badge
// ─────────────────────────────────────────────
class _AvatarWithBadge extends StatelessWidget {
  final Animation<double> floatCtrl;
  final Animation<double> rotateCtrl;
  final Animation<double> mainCtrl;

  const _AvatarWithBadge({
    required this.floatCtrl,
    required this.rotateCtrl,
    required this.mainCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: floatCtrl,
      builder: (context, child) {
        final floatY = math.sin(floatCtrl.value * math.pi * 2) * 3.0;
        return Transform.translate(
          offset: Offset(0, floatY),
          child: child,
        );
      },
      child: SizedBox(
        width: 116,
        height: 116,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Rotating border ring
            AnimatedBuilder(
              animation: rotateCtrl,
              builder: (context, child) {
                final angle = rotateCtrl.value * 2 * math.pi;
                return Transform.rotate(
                  angle: angle,
                  child: Container(
                    width: 124,
                    height: 124,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD8D3F7),
                        width: 2.0,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: CustomPaint(
                      painter: _DottedBorderPainter(),
                    ),
                  ),
                );
              },
            ),
            // Avatar image
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: SizedBox(
                    width: 108,
                    height: 108,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/onBoarding_Hero_Image.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                        Container(color: const Color(0x2AFFFFFF)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Level badge with spring entrance
            Positioned(
              right: 4,
              bottom: 6,
              child: AnimatedBuilder(
                animation: mainCtrl,
                builder: (context, child) {
                  final t = _clamp01(CurvedAnimation(
                    parent: mainCtrl,
                    curve: const Interval(0.04, 0.18, curve: Curves.elasticOut),
                  ).value);
                  final scale = 0.0 + (t * 1.15).clamp(0.0, 1.15);
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B4EE8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B4EE8).withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Dotted Border Painter for Avatar Ring
// ─────────────────────────────────────────────
class _DottedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5B4EE8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    final path = Path()..addOval(rect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        final segment = metric.extractPath(distance, end);
        canvas.drawPath(segment, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
//  Premium Pill – Shimmer sweep
// ─────────────────────────────────────────────
class _PremiumPill extends StatelessWidget {
  final Animation<double> mainCtrl;
  final Animation<double> shimmerCtrl;

  const _PremiumPill({required this.mainCtrl, required this.shimmerCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: mainCtrl,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: mainCtrl,
          curve: const Interval(0.06, 0.22, curve: Curves.easeOutBack),
        ).value);
        return Transform.scale(
          scale: 0.9 + (t * 0.1),
          child: Opacity(
            opacity: t,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                  decoration: BoxDecoration(
                    color: _purpleLight,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFD8D3F7)),
                  ),
                  child: const Text(
                    'Premium Member',
                    style: TextStyle(
                      color: _purple,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Shimmer sweep
                AnimatedBuilder(
                  animation: shimmerCtrl,
                  builder: (context, child) {
                    final shimmerX = -0.8 + (shimmerCtrl.value * 1.8);
                    return Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Transform.translate(
                            offset: Offset(shimmerX * 140, 0),
                            child: Transform.rotate(
                              angle: -0.2,
                              child: Container(
                                width: 80,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withOpacity(0.45),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  B. Metric Card – Number Roll + Streak Flame
// ─────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final Animation<double> mainCtrl;
  final Animation<double> flameCtrl;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String label;
  final String targetValue;
  final String suffix;
  final String subtitle;
  final int index;

  const _MetricCard({
    required this.mainCtrl,
    required this.flameCtrl,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.label,
    required this.targetValue,
    required this.suffix,
    required this.subtitle,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final stagger = 0.02 + (index * 0.06);

    return AnimatedBuilder(
      animation: mainCtrl,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: mainCtrl,
          curve: Interval(stagger, stagger + 0.18, curve: Curves.elasticOut),
        ).value);
        final scale = 0.94 + (t * 0.07);
        return Transform.scale(
          scale: scale,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - t)),
            child: Opacity(opacity: t, child: child),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E6EE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon with flame flicker on streak
            AnimatedBuilder(
              animation: flameCtrl,
              builder: (context, child) {
                final glow = index == 0
                    ? 0.7 + (flameCtrl.value * 0.3)
                    : 1.0;
                return Opacity(
                  opacity: glow,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Color(0xFF7C7580),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            // Number roll-up
            AnimatedBuilder(
              animation: mainCtrl,
              builder: (context, child) {
                final countT = _clamp01(CurvedAnimation(
                  parent: mainCtrl,
                  curve: Interval(stagger + 0.04, stagger + 0.24, curve: Curves.easeOutCubic),
                ).value);

                String display;
                if (targetValue.contains('.')) {
                  final val = double.tryParse(targetValue) ?? 0.0;
                  display = '${(val * countT).toStringAsFixed(1)}$suffix';
                } else {
                  final val = int.tryParse(targetValue) ?? 0;
                  display = '${(val * countT).round()}$suffix';
                }

                return Text(
                  display,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1F2E),
                    height: 1.0,
                  ),
                );
              },
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF777580),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  C. Achievement Badge – Radial pop-in + glow
// ─────────────────────────────────────────────
class _AchievementItem extends StatelessWidget {
  final Animation<double> mainCtrl;
  final int index;
  final IconData icon;
  final String label;

  const _AchievementItem({
    required this.mainCtrl,
    required this.index,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final stagger = 0.20 + (index * 0.09);

    return AnimatedBuilder(
      animation: mainCtrl,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: mainCtrl,
          curve: Interval(stagger, stagger + 0.20, curve: Curves.elasticOut),
        ).value);
        final scale = t.clamp(0.0, 1.2);
        return Transform.scale(
          scale: scale > 1.0 ? scale - (scale - 1.0) * 0.8 : scale,
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: _purpleSoft,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC9C1F2), width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B4EE8).withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: const Color(0xFF5B4EE8),
              size: 29,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2A2934),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  D. Today's Goals Card – Animated Progress + Percentage Fade
// ─────────────────────────────────────────────
class _GoalsCard extends StatelessWidget {
  final TextTheme textTheme;
  final Animation<double> mainCtrl;

  const _GoalsCard({
    required this.textTheme,
    required this.mainCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: mainCtrl,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: mainCtrl,
          curve: const Interval(0.34, 0.54, curve: Curves.easeOutCubic),
        ).value);
        return Transform.translate(
          offset: Offset(0, 24 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F4FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECE8FF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Goals",
              style: textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF242333),
              ),
            ),
            const SizedBox(height: 4),
            // Percentage text cross-fade
            AnimatedBuilder(
              animation: mainCtrl,
              builder: (context, child) {
                final fadeT = _clamp01(CurvedAnimation(
                  parent: mainCtrl,
                  curve: const Interval(0.54, 0.70),
                ).value);
                return Opacity(
                  opacity: fadeT,
                  child: Text(
                    "You're 75% through your daily targets!",
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 13.5,
                      color: const Color(0xFF7C798A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _GoalRow(
              mainCtrl: mainCtrl,
              index: 0,
              icon: Icons.bolt_rounded,
              iconColor: const Color(0xFF5B4EE8),
              label: 'Calories',
              progress: 0.75,
              value: '1650 / 2200',
            ),
            const SizedBox(height: 12),
            _GoalRow(
              mainCtrl: mainCtrl,
              index: 1,
              icon: Icons.water_drop_outlined,
              iconColor: const Color(0xFF52C7D8),
              label: 'Water Intake',
              progress: 0.70,
              value: '2100 / 3000',
              onTap: () => context.push(AppRoutes.waterTracker),
            ),
            const SizedBox(height: 12),
            _GoalRow(
              mainCtrl: mainCtrl,
              index: 2,
              icon: Icons.adjust_outlined,
              iconColor: const Color(0xFF8B4DE8),
              label: 'Protein',
              progress: 0.76,
              value: '92 / 120',
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final Animation<double> mainCtrl;
  final int index;
  final IconData icon;
  final Color iconColor;
  final String label;
  final double progress;
  final String value;
  final VoidCallback? onTap;

  const _GoalRow({
    required this.mainCtrl,
    required this.index,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.progress,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stagger = 0.36 + (index * 0.06);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedBuilder(
        animation: mainCtrl,
        builder: (context, child) {
          final t = _clamp01(CurvedAnimation(
            parent: mainCtrl,
            curve: Interval(stagger, stagger + 0.16, curve: Curves.easeOutCubic),
          ).value);
          final animatedProgress = progress * _clamp01(CurvedAnimation(
            parent: mainCtrl,
            curve: Interval(stagger, stagger + 0.26, curve: Curves.fastOutSlowIn),
          ).value);

          return Column(
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C2940),
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: t,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6F6C7D),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: animatedProgress,
                  backgroundColor: const Color(0xFFE7E1FF),
                  valueColor: const AlwaysStoppedAnimation<Color>(_purple),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  E. Setting Tile – Cascading slide + touch scale
// ─────────────────────────────────────────────
class _SettingTile extends StatelessWidget {
  final Animation<double> mainCtrl;
  final int index;
  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback? onTap;
  final bool isLogout;

  const _SettingTile({
    required this.mainCtrl,
    required this.index,
    required this.icon,
    required this.title,
    this.trailingText,
    this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final stagger = 0.50 + (index * 0.05);

    return AnimatedBuilder(
      animation: mainCtrl,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: mainCtrl,
          curve: Interval(stagger, stagger + 0.16, curve: Curves.easeOutCubic),
        ).value);
        return Transform.translate(
          offset: Offset(0, 20 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: isLogout
          ? OutlinedButton(
              onPressed: onTap ?? () {},
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: Color(0xFFF0C6C6)),
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Logout Account',
                style: TextStyle(
                  color: Color(0xFFCB6670),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : Material(
              color: _surface,
              elevation: 1.5,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  onTap: onTap,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F4FB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: const Color(0xFF6C6674)),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF22212E),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (trailingText != null)
                        Text(
                          trailingText!,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7B7786),
                          ),
                        ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, color: Color(0xFFC5C2CC)),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}