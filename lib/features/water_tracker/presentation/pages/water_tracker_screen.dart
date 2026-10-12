import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/domain/entities/water_entry_entity.dart';
import '../../../../core/services/home_data_cache.dart';
import '../../../../core/services/water_goal_resolver.dart';
import '../bloc/water_tracker_bloc.dart';

// ─────────────────────────────────────────────
//  Design Tokens & Accent Colors
// ─────────────────────────────────────────────
const Color _kWaterBlue = Color(0xFF0EA5E9);
const Color _kWaterCyan = Color(0xFF06B6D4);
const Color _kWaterDark = Color(0xFF0284C7);
const Color _kWaterLight = Color(0xFFE0F2FE);

class WaterTrackerScreen extends StatefulWidget {
  const WaterTrackerScreen({super.key});

  @override
  State<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<WaterTrackerScreen>
    with SingleTickerProviderStateMixin {
  late final WaterTrackerBloc _bloc;
  late final AnimationController _waveCtrl;

  int waterGoal = WaterGoalResolver.defaultWaterMl;
  int _cachedIntake = 0;
  bool _isSubtract = false;
  bool _goalReady = false;
  int _tipIndex = 0;

  static const List<String> _hydrationTips = [
    'Drinking water before meals aids digestion and optimizes metabolism.',
    'Staying properly hydrated boosts focus, mood, and daily physical stamina.',
    'Replenish an additional 400–600ml of fluids after intense workout sessions.',
    'Cellular hydration helps keep your skin clear and joints well lubricated.',
    'Room temperature water is absorbed faster during active recovery periods.',
  ];

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _isDark ? const Color(0xFF0B0E14) : const Color(0xFFF8F9FE);
  Color get _surface => _isDark ? const Color(0xFF141824) : Colors.white;
  Color get _surfaceAlt => _isDark ? const Color(0xFF1B2237) : const Color(0xFFF1F5F9);
  Color get _textPrimary => _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  Color get _textSecondary => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get _borderColor => _isDark ? const Color(0xFF282D4A) : const Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _bloc = sl<WaterTrackerBloc>();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final cached = HomeDataCache.getCached(userId);
      if (cached != null) {
        _cachedIntake = cached.consumedWaterMl;
        if (cached.targetWaterMl > 0) {
          waterGoal = cached.targetWaterMl;
        }
        _goalReady = true;
      }
      _loadWaterGoal(userId);
      _bloc.add(LoadWaterData(userId, DateTime.now(), initialTotalMl: _cachedIntake));
    }
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWaterGoal(String userId) async {
    final goal = await WaterGoalResolver.resolve(userId);
    if (!mounted) {
      return;
    }
    setState(() {
      waterGoal = goal;
      _goalReady = true;
    });
  }

  void _logWater(int amount) {
    HapticFeedback.lightImpact();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final signed = _isSubtract ? -amount : amount;
      _bloc.add(AddWaterLog(userId, signed, DateTime.now()));
    }
  }

  void _deleteEntry(String entryId) {
    HapticFeedback.mediumImpact();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      _bloc.add(DeleteWaterEntry(entryId, userId, DateTime.now()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Water log removed ✓'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showWaterEntryDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WaterEntryBottomSheet(
        initialSubtract: _isSubtract,
        onWaterAdded: (amount, {required isSubtract}) {
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId != null) {
            final signed = isSubtract ? -amount : amount;
            _bloc.add(AddWaterLog(userId, signed, DateTime.now()));
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showGoalInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _borderColor),
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _kWaterBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.water_drop_rounded, color: _kWaterBlue, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Hydration Target',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your daily target is $waterGoal ml.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Calculated based on your body weight, climate, and daily activity. '
              'Health guidelines recommend 30–35 ml of water per kg of body mass.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: _textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Got It',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _kWaterBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
        value: _bloc,
        child: BlocListener<WaterTrackerBloc, WaterTrackerState>(
          listener: (context, state) {
            if (state is WaterTrackerError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.message}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: Scaffold(
            backgroundColor: _bg,
            body: SafeArea(
              child: Column(
                children: [
                  // ── Header Bar ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Row(
                      children: [
                        _IconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Water Intake',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Daily Hydration Tracker',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        _IconButton(
                          icon: Icons.info_outline_rounded,
                          onTap: _showGoalInfoDialog,
                        ),
                      ],
                    ),
                  ),

                  // ── Scrollable Body ──
                  Expanded(
                    child: BlocBuilder<WaterTrackerBloc, WaterTrackerState>(
                      builder: (context, state) {
                        var waterIntake = _cachedIntake;
                        var entries = <WaterEntryEntity>[];

                        if (state is WaterDataLoaded) {
                          waterIntake = state.totalMl;
                          _cachedIntake = state.totalMl;
                          entries = state.entries;
                        }

                        final progress = _goalReady && waterGoal > 0
                            ? (waterIntake / waterGoal).clamp(0.0, 1.0)
                            : 0.0;
                        final percent = _goalReady && waterGoal > 0
                            ? ((waterIntake / waterGoal) * 100).clamp(0.0, 999.0)
                            : 0.0;
                        final remaining = (waterGoal - waterIntake).clamp(0, 99999);

                        return ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                          children: [
                            // ── A. Interactive Liquid Reservoir Card ──
                            _WaveReservoirCard(
                              waveCtrl: _waveCtrl,
                              progress: progress,
                              percent: percent,
                              waterIntake: waterIntake,
                              waterGoal: waterGoal,
                              remaining: remaining,
                              goalReady: _goalReady,
                              isDark: _isDark,
                              surface: _surface,
                              borderColor: _borderColor,
                              textPrimary: _textPrimary,
                              textSecondary: _textSecondary,
                              onQuickSip: () => _logWater(250),
                            ),
                            const SizedBox(height: 18),

                            // ── B. Mode Toggle (Add vs Subtract) ──
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _surfaceAlt,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _borderColor),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _ModeButton(
                                      icon: Icons.add_rounded,
                                      label: 'Add Intake',
                                      selected: !_isSubtract,
                                      activeColor: _kWaterBlue,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _isSubtract = false);
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: _ModeButton(
                                      icon: Icons.remove_rounded,
                                      label: 'Remove Intake',
                                      selected: _isSubtract,
                                      activeColor: const Color(0xFFEF4444),
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _isSubtract = true);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── C. Quick Presets Header ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _isSubtract
                                          ? Icons.remove_circle_outline_rounded
                                          : Icons.bolt_rounded,
                                      size: 16,
                                      color: _isSubtract
                                          ? const Color(0xFFEF4444)
                                          : _kWaterBlue,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isSubtract ? 'DEDUCT LOG' : 'QUICK LOG',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.7,
                                        color: _textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: _showWaterEntryDialog,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          _isSubtract ? 'Custom Remove' : 'Custom Amount',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: _kWaterBlue,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 11,
                                          color: _kWaterBlue,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // ── D. 4 Quick Vessel Cards ──
                            Row(
                              children: [
                                Expanded(
                                  child: _InteractiveQuickLogCard(
                                    amount: 250,
                                    label: 'Glass',
                                    icon: Icons.local_drink_rounded,
                                    isSubtract: _isSubtract,
                                    isDark: _isDark,
                                    surface: _surface,
                                    borderColor: _borderColor,
                                    textPrimary: _textPrimary,
                                    textSecondary: _textSecondary,
                                    onTap: () => _logWater(250),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _InteractiveQuickLogCard(
                                    amount: 500,
                                    label: 'Bottle',
                                    icon: Icons.water_rounded,
                                    isSubtract: _isSubtract,
                                    isDark: _isDark,
                                    surface: _surface,
                                    borderColor: _borderColor,
                                    textPrimary: _textPrimary,
                                    textSecondary: _textSecondary,
                                    onTap: () => _logWater(500),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _InteractiveQuickLogCard(
                                    amount: 750,
                                    label: 'Flask',
                                    icon: Icons.sports_bar_rounded,
                                    isSubtract: _isSubtract,
                                    isDark: _isDark,
                                    surface: _surface,
                                    borderColor: _borderColor,
                                    textPrimary: _textPrimary,
                                    textSecondary: _textSecondary,
                                    onTap: () => _logWater(750),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _InteractiveQuickLogCard(
                                    amount: 1000,
                                    label: 'Jug',
                                    icon: Icons.opacity_rounded,
                                    isSubtract: _isSubtract,
                                    isDark: _isDark,
                                    surface: _surface,
                                    borderColor: _borderColor,
                                    textPrimary: _textPrimary,
                                    textSecondary: _textSecondary,
                                    onTap: () => _logWater(1000),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // ── E. Today's History Log ──
                            Row(
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  size: 16,
                                  color: _textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "TODAY'S LOGS",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.7,
                                    color: _textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                if (entries.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _surfaceAlt,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _borderColor),
                                    ),
                                    child: Text(
                                      '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _textSecondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (state is WaterTrackerLoading && entries.isEmpty)
                              _buildSkeleton(surface: _surface, borderColor: _borderColor)
                            else if (entries.isEmpty)
                              _buildEmptyState(
                                surface: _surface,
                                borderColor: _borderColor,
                                textPrimary: _textPrimary,
                                textSecondary: _textSecondary,
                              )
                            else
                              _HistoryCard(
                                entries: entries,
                                isDark: _isDark,
                                surface: _surface,
                                borderColor: _borderColor,
                                textPrimary: _textPrimary,
                                textSecondary: _textSecondary,
                                onDelete: _deleteEntry,
                              ),
                            const SizedBox(height: 16),

                            // ── F. Interactive Hydration Pro-Tip ──
                            _TipCard(
                              tip: _hydrationTips[_tipIndex % _hydrationTips.length],
                              isDark: _isDark,
                              surface: _surface,
                              borderColor: _borderColor,
                              textPrimary: _textPrimary,
                              textSecondary: _textSecondary,
                              onCycleTip: () {
                                HapticFeedback.selectionClick();
                                setState(() => _tipIndex++);
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildEmptyState({
    required Color surface,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _kWaterBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.water_drop_outlined,
                color: _kWaterBlue,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No water logged yet today',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap any quick vessel above to log your first drink!',
              style: TextStyle(
                fontSize: 12.5,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildSkeleton({
    required Color surface,
    required Color borderColor,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: List.generate(
            2,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _kWaterBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: _surfaceAlt,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Container(
                    width: 50,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _surfaceAlt,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────
//  Top Squircle Icon Button
// ─────────────────────────────────────────────
class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141824) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF282D4A) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 19,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Interactive Liquid Wave Hydration Reservoir
// ─────────────────────────────────────────────
class _WaveReservoirCard extends StatelessWidget {
  const _WaveReservoirCard({
    required this.waveCtrl,
    required this.progress,
    required this.percent,
    required this.waterIntake,
    required this.waterGoal,
    required this.remaining,
    required this.goalReady,
    required this.isDark,
    required this.surface,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onQuickSip,
  });

  final Animation<double> waveCtrl;
  final double progress;
  final double percent;
  final int waterIntake;
  final int waterGoal;
  final int remaining;
  final bool goalReady;
  final bool isDark;
  final Color surface;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onQuickSip;

  @override
  Widget build(BuildContext context) {
    final isGoalMet = progress >= 1.0;

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: _kWaterBlue.withValues(alpha: isDark ? 0.16 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // Liquid Wave Animated Layer
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: progress),
                builder: (context, animatedVal, _) => AnimatedBuilder(
                  animation: waveCtrl,
                  builder: (context, _) => CustomPaint(
                    painter: _LiquidWavePainter(
                      progress: animatedVal,
                      wavePhase: waveCtrl.value,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
            ),

            // Top Status Bar Inside Reservoir
            Positioned(
              top: 14,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.40),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isGoalMet ? Icons.check_circle_rounded : Icons.water_drop_rounded,
                          size: 14,
                          color: isGoalMet ? const Color(0xFF10B981) : _kWaterBlue,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isGoalMet ? 'Goal Achieved!' : '$remaining ml to goal',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isGoalMet ? const Color(0xFF10B981) : textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.40),
                      ),
                    ),
                    child: Text(
                      'Target: $waterGoal ml',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Central Frosted Metric Glass Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF0F172A) : Colors.white)
                      .withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.20 : 0.70),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: 0, end: percent),
                      builder: (context, val, _) => Text(
                        goalReady ? '${val.toStringAsFixed(0)}%' : '—',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          color: textPrimary,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$waterIntake / $waterGoal ml',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: _kWaterBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Quick Sip Water Splash Hint
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onQuickSip,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.40),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_circle_outline_rounded, size: 14, color: _kWaterBlue),
                          const SizedBox(width: 5),
                          Text(
                            '+250ml Quick Sip',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
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
//  Dual Sine Wave Liquid Custom Painter
// ─────────────────────────────────────────────
class _LiquidWavePainter extends CustomPainter {
  const _LiquidWavePainter({
    required this.progress,
    required this.wavePhase,
    required this.isDark,
  });

  final double progress;
  final double wavePhase;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) {
      return;
    }

    // Effective liquid surface Y level
    final waterHeight = size.height * progress.clamp(0.04, 1.0);
    final baseLevel = size.height - waterHeight;
    final amplitude = 5.0 * (1.0 - (progress - 0.5).abs());

    // 1. Secondary Back Wave (Soft Aqua)
    final backPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.28 : 0.35)
      ..style = PaintingStyle.fill;

    final backPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, baseLevel);

    for (double x = 0; x <= size.width; x += 1.5) {
      final radians = (x / size.width * 2 * math.pi) + (wavePhase * 2 * math.pi);
      final y = baseLevel + math.sin(radians) * amplitude;
      backPath.lineTo(x, y);
    }
    backPath
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(backPath, backPaint);

    // 2. Primary Front Wave (Rich Liquid Gradient)
    final frontRect = Rect.fromLTWH(0, baseLevel - amplitude, size.width, waterHeight + amplitude);
    final frontPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF38BDF8),
          _kWaterBlue,
          _kWaterDark,
        ],
      ).createShader(frontRect)
      ..style = PaintingStyle.fill;

    final frontPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, baseLevel);

    for (double x = 0; x <= size.width; x += 1.5) {
      final radians = (x / size.width * 2 * math.pi) + (wavePhase * 2 * math.pi + math.pi / 2);
      final y = baseLevel + math.sin(radians) * amplitude;
      frontPath.lineTo(x, y);
    }
    frontPath
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(frontPath, frontPaint);

    // 3. Gentle Rising Floating Bubbles
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final bubblePositions = [
      Offset(size.width * 0.25, baseLevel + (waterHeight * ((wavePhase + 0.2) % 1.0))),
      Offset(size.width * 0.55, baseLevel + (waterHeight * ((wavePhase + 0.6) % 1.0))),
      Offset(size.width * 0.80, baseLevel + (waterHeight * ((wavePhase + 0.85) % 1.0))),
    ];

    for (var i = 0; i < bubblePositions.length; i++) {
      final pos = bubblePositions[i];
      if (pos.dy < size.height && pos.dy > baseLevel) {
        canvas.drawCircle(pos, 2.5 + (i % 2) * 1.5, bubblePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidWavePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.wavePhase != wavePhase ||
      oldDelegate.isDark != isDark;
}

// ─────────────────────────────────────────────
//  Add / Subtract Segment Mode Button
// ─────────────────────────────────────────────
class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────
//  Tactile Quick Log Card with Scale Bounce
// ─────────────────────────────────────────────
class _InteractiveQuickLogCard extends StatefulWidget {
  const _InteractiveQuickLogCard({
    required this.amount,
    required this.label,
    required this.icon,
    required this.isSubtract,
    required this.isDark,
    required this.surface,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  final int amount;
  final String label;
  final IconData icon;
  final bool isSubtract;
  final bool isDark;
  final Color surface;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  @override
  State<_InteractiveQuickLogCard> createState() => _InteractiveQuickLogCardState();
}

class _InteractiveQuickLogCardState extends State<_InteractiveQuickLogCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isSubtract ? const Color(0xFFEF4444) : _kWaterBlue;
    final activeBg = widget.isSubtract
        ? (widget.isDark
            ? const Color(0xFF7F1D1D).withValues(alpha: 0.28)
            : const Color(0xFFFEF2F2))
        : (widget.isDark
            ? const Color(0xFF0369A1).withValues(alpha: 0.24)
            : _kWaterLight);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: widget.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isDark ? 0.22 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: activeBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  widget.isSubtract ? Icons.remove_circle_outline_rounded : widget.icon,
                  color: activeColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.amount}ml',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: widget.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.label.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: widget.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  History Container Card
// ─────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.entries,
    required this.isDark,
    required this.surface,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onDelete,
  });

  final List<WaterEntryEntity> entries;
  final bool isDark;
  final Color surface;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final void Function(String id) onDelete;

  String _vesselTitle(int amount) {
    final abs = amount.abs();
    if (abs >= 1000) {
      return 'Large Jug';
    }
    if (abs >= 750) {
      return 'Water Flask';
    }
    if (abs >= 500) {
      return 'Standard Bottle';
    }
    return 'Water Glass';
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            for (var index = 0; index < entries.length; index++) ...[
              _HistoryTile(
                entry: entries[index],
                title: _vesselTitle(entries[index].amountMl),
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onDelete: () => onDelete(entries[index].id),
              ),
              if (index != entries.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: borderColor.withValues(alpha: 0.6),
                ),
            ],
          ],
        ),
      );
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.title,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.onDelete,
  });

  final WaterEntryEntity entry;
  final String title;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isNegative = entry.amountMl < 0;
    final timeStr = DateFormat.jm().format(entry.createdAt ?? entry.date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isNegative
                  ? const Color(0xFFEF4444).withValues(alpha: 0.14)
                  : _kWaterBlue.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isNegative ? Icons.remove_rounded : Icons.water_drop_rounded,
              color: isNegative ? const Color(0xFFEF4444) : _kWaterBlue,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isNegative ? '${entry.amountMl}ml' : '+${entry.amountMl}ml',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: isNegative ? const Color(0xFFEF4444) : _kWaterBlue,
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Smart Hydration Pro-Tip Card (Interactive Tap)
// ─────────────────────────────────────────────
class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.tip,
    required this.isDark,
    required this.surface,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onCycleTip,
  });

  final String tip;
  final bool isDark;
  final Color surface;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onCycleTip;

  @override
  Widget build(BuildContext context) => Material(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onCycleTip,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _kWaterCyan.withValues(alpha: isDark ? 0.35 : 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _kWaterCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.lightbulb_outline_rounded, color: _kWaterCyan, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Hydration Insight',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: _kWaterCyan,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Tap for more',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.refresh_rounded,
                                size: 12,
                                color: textSecondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        tip,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────
//  Custom Water Entry Bottom Sheet
// ─────────────────────────────────────────────
class WaterEntryBottomSheet extends StatefulWidget {
  const WaterEntryBottomSheet({
    required this.onWaterAdded,
    super.key,
    this.initialSubtract = false,
  });

  final void Function(int amount, {required bool isSubtract}) onWaterAdded;
  final bool initialSubtract;

  @override
  State<WaterEntryBottomSheet> createState() => _WaterEntryBottomSheetState();
}

class _WaterEntryBottomSheetState extends State<WaterEntryBottomSheet> {
  late TextEditingController _mlController;
  int _customAmount = 250;
  late bool _isSubtract;

  @override
  void initState() {
    super.initState();
    _isSubtract = widget.initialSubtract;
    _mlController = TextEditingController(text: '250');
  }

  @override
  void dispose() {
    _mlController.dispose();
    super.dispose();
  }

  void _handleAdd() {
    final amount = int.tryParse(_mlController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid water volume'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    HapticFeedback.lightImpact();
    widget.onWaterAdded(amount, isSubtract: _isSubtract);
  }

  void _adjustAmount(int delta) {
    HapticFeedback.selectionClick();
    final current = int.tryParse(_mlController.text) ?? _customAmount;
    final next = (current + delta).clamp(50, 5000);
    setState(() {
      _customAmount = next;
      _mlController.text = '$next';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF141824) : Colors.white;
    final surfaceAlt = isDark ? const Color(0xFF1B2237) : const Color(0xFFF1F5F9);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF282D4A) : const Color(0xFFE2E8F0);
    final activeColor = _isSubtract ? const Color(0xFFEF4444) : _kWaterBlue;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sheet Title & Close
            Row(
              children: [
                Text(
                  _isSubtract ? 'Deduct Water' : 'Custom Water Entry',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: surfaceAlt,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, color: textSecondary, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mode Selector inside sheet
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeButton(
                      icon: Icons.add_rounded,
                      label: 'Add Intake',
                      selected: !_isSubtract,
                      activeColor: _kWaterBlue,
                      onTap: () => setState(() => _isSubtract = false),
                    ),
                  ),
                  Expanded(
                    child: _ModeButton(
                      icon: Icons.remove_rounded,
                      label: 'Remove Intake',
                      selected: _isSubtract,
                      activeColor: const Color(0xFFEF4444),
                      onTap: () => setState(() => _isSubtract = true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stepper Increment Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StepperButton(
                  label: '−100',
                  onTap: () => _adjustAmount(-100),
                  surfaceAlt: surfaceAlt,
                  borderColor: borderColor,
                  textColor: textPrimary,
                ),
                const SizedBox(width: 8),
                _StepperButton(
                  label: '−50',
                  onTap: () => _adjustAmount(-50),
                  surfaceAlt: surfaceAlt,
                  borderColor: borderColor,
                  textColor: textPrimary,
                ),
                const SizedBox(width: 14),
                Text(
                  '${_customAmount}ml',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: activeColor,
                  ),
                ),
                const SizedBox(width: 14),
                _StepperButton(
                  label: '+50',
                  onTap: () => _adjustAmount(50),
                  surfaceAlt: surfaceAlt,
                  borderColor: borderColor,
                  textColor: textPrimary,
                ),
                const SizedBox(width: 8),
                _StepperButton(
                  label: '+100',
                  onTap: () => _adjustAmount(100),
                  surfaceAlt: surfaceAlt,
                  borderColor: borderColor,
                  textColor: textPrimary,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Quick Amount Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [100, 250, 500, 750, 1000, 1500].map((amt) {
                  final isSelected = _customAmount == amt;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _customAmount = amt;
                          _mlController.text = '$amt';
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor : surfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? activeColor : borderColor,
                          ),
                        ),
                        child: Text(
                          '${amt}ml',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Input TextField
            TextField(
              controller: _mlController,
              keyboardType: TextInputType.number,
              onChanged: (val) {
                final amount = int.tryParse(val);
                if (amount != null) {
                  setState(() => _customAmount = amount);
                }
              },
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Exact Volume (ml)',
                labelStyle: TextStyle(color: textSecondary, fontSize: 13),
                filled: true,
                fillColor: surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: activeColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixText: 'ml',
                suffixStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleAdd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _isSubtract ? 'Deduct Water' : 'Log Water',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.label,
    required this.onTap,
    required this.surfaceAlt,
    required this.borderColor,
    required this.textColor,
  });

  final String label;
  final VoidCallback onTap;
  final Color surfaceAlt;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ),
      );
}
