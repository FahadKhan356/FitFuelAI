import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FitFuel AAA-Grade Kinetic Physics & Impeller-Optimized Premium Home Screen
// Strict Zero-Lag Architecture (Locked 60 / 120 FPS Impeller Texture Isolation)
// ─────────────────────────────────────────────────────────────────────────────

class PremiumHomeScreen extends StatefulWidget {
  const PremiumHomeScreen({
    super.key,
    this.onOpenFoodSearch,
    this.onOpenPostureCoach,
    this.onOpenProfile,
    this.onOpenAICoach,
  });

  final VoidCallback? onOpenFoodSearch;
  final VoidCallback? onOpenPostureCoach;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenAICoach;

  @override
  State<PremiumHomeScreen> createState() => _PremiumHomeScreenState();
}

class _PremiumHomeScreenState extends State<PremiumHomeScreen>
    with SingleTickerProviderStateMixin {
  // ── Fluid Kinetic Physics Controller ────────────────────────────────────────
  late final AnimationController _entranceController;

  // Kinetic Curve: Custom Cubic Bezier simulating elastic weightless glide
  static const Curve _kineticCurve = Cubic(0.05, 0.7, 0.1, 1);

  // ── Coordinated Sub-Interval Animations ──────────────────────────────────────
  late final Animation<double> _bgScale;
  late final Animation<double> _bgOpacity;

  late final Animation<Offset> _headerSlide;
  late final Animation<double> _headerOpacity;

  late final Animation<double> _heroScale;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _heroOpacity;

  late final Animation<Offset> _macrosSlide;
  late final Animation<double> _macrosOpacity;

  late final Animation<Offset> _action1Slide;
  late final Animation<double> _action1Opacity;

  late final Animation<Offset> _action2Slide;
  late final Animation<double> _action2Opacity;

  late final Animation<Offset> _action3Slide;
  late final Animation<double> _action3Opacity;

  late final Animation<Offset> _action4Slide;
  late final Animation<double> _action4Opacity;

  late final Animation<Offset> _footerSlide;
  late final Animation<double> _footerOpacity;

  // Mock dashboard state (reactive in production app)
  final int _remainingKcal = 1845;
  final int _totalGoalKcal = 2650;
  final int _consumedKcal = 805;
  final int _burnedKcal = 340;

  final double _proteinCurrent = 135;
  final double _proteinTarget = 180;
  final double _carbsCurrent = 195;
  final double _carbsTarget = 260;
  final double _fatCurrent = 48;
  final double _fatTarget = 70;

  @override
  void initState() {
    super.initState();

    // Calibrated precisely to 450 milliseconds for luxurious fluidity
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    // 1. Background Canvas Depth (0.0 -> 0.55 interval)
    _bgScale = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, 0.55, curve: _kineticCurve),
      ),
    );
    _bgOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, 0.45, curve: Curves.easeOut),
      ),
    );

    // 2. Header Slide & Fade (0.05 -> 0.60 interval)
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.05, 0.60, curve: _kineticCurve),
      ),
    );
    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.05, 0.50, curve: Curves.easeOut),
      ),
    );

    // 3. Hero Dashboard Card Scale-Bounce & Vertical Shift (0.12 -> 0.75 interval)
    _heroScale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.12, 0.75, curve: _kineticCurve),
      ),
    );
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.12, 0.75, curve: _kineticCurve),
      ),
    );
    _heroOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.12, 0.60, curve: Curves.easeOut),
      ),
    );

    // 4. Macro Nutrition Matrix Stagger (0.22 -> 0.82 interval)
    _macrosSlide = Tween<Offset>(
      begin: const Offset(0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.22, 0.82, curve: _kineticCurve),
      ),
    );
    _macrosOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.22, 0.70, curve: Curves.easeOut),
      ),
    );

    // 5. Cascading Action Tiles (50ms incremental offset per tier card)
    // 50ms / 450ms ~= 0.11 delay increment
    // Tier 1 (starts 0.28, duration 0.40)
    _action1Slide = Tween<Offset>(
      begin: const Offset(0.25, 0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.28, 0.72, curve: _kineticCurve),
      ),
    );
    _action1Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.28, 0.65, curve: Curves.easeOut),
      ),
    );

    // Tier 2 (+50ms: starts 0.39, duration 0.40)
    _action2Slide = Tween<Offset>(
      begin: const Offset(0.25, 0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.39, 0.83, curve: _kineticCurve),
      ),
    );
    _action2Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.39, 0.75, curve: Curves.easeOut),
      ),
    );

    // Tier 3 (+100ms: starts 0.50, duration 0.40)
    _action3Slide = Tween<Offset>(
      begin: const Offset(0.25, 0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.50, 0.92, curve: _kineticCurve),
      ),
    );
    _action3Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.50, 0.84, curve: Curves.easeOut),
      ),
    );

    // Tier 4 (+150ms: starts 0.61, duration 0.39)
    _action4Slide = Tween<Offset>(
      begin: const Offset(0.25, 0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.61, 1, curve: _kineticCurve),
      ),
    );
    _action4Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.61, 0.92, curve: Curves.easeOut),
      ),
    );

    // 6. Footer / Posture Coach Spotlight (0.35 -> 1.00 interval)
    _footerSlide = Tween<Offset>(
      begin: const Offset(0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 1, curve: _kineticCurve),
      ),
    );
    _footerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
      ),
    );

    // Trigger GPU-driven entrance orchestrator
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── Impeller Engine Optimization: Isolated Texture Layer ───────────────
    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        body: Stack(
          children: [
            // Ambient Neon Glow Radiance with background depth scale
            AnimatedBuilder(
              animation: _entranceController,
              builder: (context, child) => Transform.scale(
                scale: _bgScale.value,
                child: Opacity(
                  opacity: _bgOpacity.value,
                  child: child,
                ),
              ),
              child: const _AmbientBackgroundGlow(),
            ),

            // SafeArea Scrollable Body
            SafeArea(
              child: AnimatedBuilder(
                animation: _entranceController,
                builder: (context, _) => SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Header (Slide + Opacity Transform Matrix)
                      Transform.translate(
                        offset: Offset(0, _headerSlide.value.dy * 50),
                        child: Opacity(
                          opacity: _headerOpacity.value,
                          child: _buildHeader(),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // 2. Hero Dashboard Card (Scale-Bounce + Slide + Opacity)
                      Transform.translate(
                        offset: Offset(0, _heroSlide.value.dy * 80),
                        child: Transform.scale(
                          scale: _heroScale.value,
                          alignment: Alignment.center,
                          child: Opacity(
                            opacity: _heroOpacity.value,
                            child: _buildHeroDashboardCard(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 3. Macro Nutrition Matrix
                      Transform.translate(
                        offset: Offset(0, _macrosSlide.value.dy * 40),
                        child: Opacity(
                          opacity: _macrosOpacity.value,
                          child: _buildMacroMatrix(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 4. Quick Action Header
                      Transform.translate(
                        offset: Offset(0, _action1Slide.value.dy * 30),
                        child: Opacity(
                          opacity: _action1Opacity.value,
                          child: const _SectionTitle(
                            title: 'INTELLIGENT SUITE',
                            subtitle: '4-Tier Food Search & AI Form Detection',
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 5. Tiered Action Grid with 50ms Cascading Staggered Water Effect
                      _buildCascadingActionGrid(),

                      const SizedBox(height: 20),

                      // 6. Posture Coach Spotlight Card
                      Transform.translate(
                        offset: Offset(0, _footerSlide.value.dy * 30),
                        child: Opacity(
                          opacity: _footerOpacity.value,
                          child: _buildPostureSpotlightCard(),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header Component ───────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Profile Circle with Neon Ring
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onOpenProfile?.call();
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1.6,
                  ),
                ),
                child: const Center(
                  child: Text(
                    '⚡',
                    style: TextStyle(fontSize: 22),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'FITFUEL AI',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: const Color(0xFF818CF8).withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF10B981),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Good afternoon, Athlete',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Quick AI Coach Chat Action
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onOpenAICoach?.call();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF818CF8),
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'AI Coach',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Hero Dashboard Card Component ──────────────────────────────────────────
  Widget _buildHeroDashboardCard() {
    final progress = (_consumedKcal / _totalGoalKcal).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF241442), // Deep Royal Purple
            Color(0xFF16162D), // Dark Indigo Slate
            Color(0xFF111122), // Deep Obsidian
          ],
        ),
        border: Border.all(
          color: const Color(0xFF818CF8).withValues(alpha: 0.28),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag & Sync Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 13,
                            color: Color(0xFF818CF8),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'LIVE METABOLIC ENGINE',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Color(0xFF818CF8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Goal: $_totalGoalKcal kcal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Center Radial Dial & Number
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Large Bold Calories Remaining
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$_remainingKcal',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.5,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                              TextSpan(
                                text: ' kcal',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF818CF8).withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Remaining to fuel lean growth',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),

                    // Kinetic Circular Dial
                    SizedBox(
                      width: 82,
                      height: 82,
                      child: CustomPaint(
                        painter: _CalorieDialPainter(
                          progress: progress,
                          activeColor: const Color(0xFF6366F1),
                          trackColor: Colors.white.withValues(alpha: 0.08),
                        ),
                        child: Center(
                          child: Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),
                const Divider(height: 1, color: Color(0x25FFFFFF)),
                const SizedBox(height: 16),

                // Intake vs Burned Bottom Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _HeroSubStat(
                        icon: Icons.restaurant_rounded,
                        iconColor: const Color(0xFF10B981),
                        label: 'Consumed',
                        value: '$_consumedKcal kcal',
                      ),
                    ),
                    Container(width: 1, height: 26, color: Colors.white12),
                    Expanded(
                      child: _HeroSubStat(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: const Color(0xFFEF4444),
                        label: 'Burned Today',
                        value: '$_burnedKcal kcal',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Macro Nutrition Matrix ─────────────────────────────────────────────────
  Widget _buildMacroMatrix() {
    return Row(
      children: [
        Expanded(
          child: _MacroPillCard(
            title: 'Protein',
            current: _proteinCurrent,
            target: _proteinTarget,
            unit: 'g',
            color: const Color(0xFF6366F1), // Neon Indigo
            glowColor: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MacroPillCard(
            title: 'Carbs',
            current: _carbsCurrent,
            target: _carbsTarget,
            unit: 'g',
            color: const Color(0xFFF59E0B), // Vibrant Amber
            glowColor: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MacroPillCard(
            title: 'Fats',
            current: _fatCurrent,
            target: _fatTarget,
            unit: 'g',
            color: const Color(0xFF06B6D4), // Cyan
            glowColor: const Color(0xFF06B6D4),
          ),
        ),
      ],
    );
  }

  // ── Cascading Staggered Action Grid (50ms Increment Waterfall) ────────────
  Widget _buildCascadingActionGrid() {
    return Column(
      children: [
        Row(
          children: [
            // Tier 1: USDA FoodData
            Expanded(
              child: Transform.translate(
                offset: Offset(_action1Slide.value.dx * 60, _action1Slide.value.dy * 30),
                child: Opacity(
                  opacity: _action1Opacity.value,
                  child: _TierActionCard(
                    tierBadge: 'TIER 1',
                    title: 'USDA FoodData',
                    description: 'Generic & unbranded fast nutrition database',
                    icon: Icons.travel_explore_rounded,
                    accentColor: const Color(0xFF38BDF8),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onOpenFoodSearch?.call();
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Tier 2: Open Food Facts (+50ms Stagger Delay)
            Expanded(
              child: Transform.translate(
                offset: Offset(_action2Slide.value.dx * 60, _action2Slide.value.dy * 30),
                child: Opacity(
                  opacity: _action2Opacity.value,
                  child: _TierActionCard(
                    tierBadge: 'TIER 2',
                    title: 'Open Food Facts',
                    description: 'Instant local cache & barcode verified',
                    icon: Icons.qr_code_scanner_rounded,
                    accentColor: const Color(0xFF10B981),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onOpenFoodSearch?.call();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Tier 3: FatSecret (+100ms Stagger Delay)
            Expanded(
              child: Transform.translate(
                offset: Offset(_action3Slide.value.dx * 60, _action3Slide.value.dy * 30),
                child: Opacity(
                  opacity: _action3Opacity.value,
                  child: _TierActionCard(
                    tierBadge: 'TIER 3',
                    title: 'FatSecret Global',
                    description: '1.9M restaurant & commercial brands',
                    icon: Icons.fastfood_rounded,
                    accentColor: const Color(0xFFF59E0B),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onOpenFoodSearch?.call();
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Tier 4: Gemini Vision AI (+150ms Stagger Delay)
            Expanded(
              child: Transform.translate(
                offset: Offset(_action4Slide.value.dx * 60, _action4Slide.value.dy * 30),
                child: Opacity(
                  opacity: _action4Opacity.value,
                  child: _TierActionCard(
                    tierBadge: 'TIER 4',
                    title: 'Gemini Vision AI',
                    description: 'Multimodal meal photo macro estimator',
                    icon: Icons.auto_awesome_rounded,
                    accentColor: const Color(0xFFA855F7),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onOpenFoodSearch?.call();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Posture Coach Spotlight Card ───────────────────────────────────────────
  Widget _buildPostureSpotlightCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        widget.onOpenPostureCoach?.call();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.accessibility_new_rounded,
                color: Color(0xFF818CF8),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'AI POSTURE COACH',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LIVE SKELETON',
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFEF4444),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Real-time joint biomechanics & injury prevention camera',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.55),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Sub-Components & Isolated Canvas Painters
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSubStat extends StatelessWidget {
  const _HeroSubStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MacroPillCard extends StatelessWidget {
  const _MacroPillCard({
    required this.title,
    required this.current,
    required this.target,
    required this.unit,
    required this.color,
    required this.glowColor,
  });

  final String title;
  final double current;
  final double target;
  final String unit;
  final Color color;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    final pct = (current / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF161626),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: color,
                ),
              ),
              Text(
                '${(pct * 100).round()}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${current.round()}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: ' / ${target.round()}$unit',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Progress line
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  height: 5,
                  width: double.infinity,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.7),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TierActionCard extends StatelessWidget {
  const _TierActionCard({
    required this.tierBadge,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final String tierBadge;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 125,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2F),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tierBadge,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Icon(icon, color: accentColor, size: 18),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.45),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
            color: Color(0xFF818CF8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

// ── Custom Impeller Calorie Radial Dial Painter ──────────────────────────────
class _CalorieDialPainter extends CustomPainter {
  _CalorieDialPainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
  });

  final double progress;
  final Color activeColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Active arc
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.5
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(_CalorieDialPainter old) =>
      old.progress != progress || old.activeColor != activeColor;
}

// ── Ambient Background Glow Layer ────────────────────────────────────────────
class _AmbientBackgroundGlow extends StatelessWidget {
  const _AmbientBackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Top Left Indigo Glow
            Positioned(
              top: -80,
              left: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                ),
              ),
            ),
            // Middle Right Purple Glow
            Positioned(
              top: 220,
              right: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
