import 'package:fitfuel_ai/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
const _bg = Color(0xFFF7F6FB);
const _surface = Colors.white;
const _purple = Color(AppColors.authPurple);
const _purpleSoft = Color(0xFFF0EDFF);
const _purpleTint = Color(0xFFF6F3FF);
const _textPrimary = Color(0xFF1E1D2A);
const _textSecondary = Color(0xFF706D7B);
const _border = Color(0xFFE8E4EF);
const _cyan = Color(0xFF2ED9F3);
const _mint = Color(0xFF20C78B);

double _clamp01(double v) => v.clamp(0.0, 1.0);

class WeightTrackerScreen extends StatefulWidget {
  const WeightTrackerScreen({super.key});

  @override
  State<WeightTrackerScreen> createState() => _WeightTrackerScreenState();
}

class _WeightTrackerScreenState extends State<WeightTrackerScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainCtrl;
  late final AnimationController _pulseCtrl;
  bool isWeekly = true;

  @override
  void initState() {
    super.initState();
    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..forward();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: _WeightFab(mainCtrl: _mainCtrl),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                children: [
                  _IconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Weight Tracking',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFECE9F4)),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  // ── A. Top Weight Display ──
                  _WeightHeader(mainCtrl: _mainCtrl),
                  const SizedBox(height: 16),
                  // ── B. Weight Trend Chart ──
                  _CardShell(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Weight Trend',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                  ),
                            ),
                            const Spacer(),
                            _SegmentPill(
                              label: 'WEEK',
                              selected: isWeekly,
                              mainCtrl: _mainCtrl,
                              onTap: () => setState(() => isWeekly = true),
                            ),
                            const SizedBox(width: 8),
                            _SegmentPill(
                              label: 'MONTH',
                              selected: !isWeekly,
                              mainCtrl: _mainCtrl,
                              onTap: () => setState(() => isWeekly = false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Last 7 days',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: _textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _WeightChart(mainCtrl: _mainCtrl),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── C. Goal Progress ──
                  _GoalProgressCard(mainCtrl: _mainCtrl),
                  const SizedBox(height: 16),
                  // ── D. Milestones ──
                  Row(
                    children: [
                      Text(
                        'Milestones',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        'View All',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _purple,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _MilestoneCard(
                    mainCtrl: _mainCtrl,
                    index: 0,
                    icon: Icons.emoji_events_outlined,
                    iconBg: const Color(0xFFE9F3FF),
                    iconColor: const Color(0xFF4A6FFF),
                    title: 'First 5kg Lost',
                    subtitle: "You've hit your first major weight",
                    dateLabel: 'OCT 12, 2023',
                    highlighted: true,
                  ),
                  const SizedBox(height: 12),
                  _MilestoneCard(
                    mainCtrl: _mainCtrl,
                    index: 1,
                    icon: Icons.adjust_outlined,
                    iconBg: const Color(0xFFF1F0F7),
                    iconColor: const Color(0xFF8A8A96),
                    title: 'Halfway Point',
                    subtitle: '4.6kg down, 4.4kg to go for your',
                    dateLabel: 'IN PROGRESS',
                  ),
                  const SizedBox(height: 12),
                  _MilestoneCard(
                    mainCtrl: _mainCtrl,
                    index: 2,
                    icon: Icons.auto_awesome_rounded,
                    iconBg: const Color(0xFFF1ECFF),
                    iconColor: const Color(0xFF5B4EE8),
                    title: '7 Day Log Streak',
                    subtitle: 'Consistency is key! You logged',
                    dateLabel: 'TODAY',
                  ),
                  const SizedBox(height: 12),
                  // ── E. BMI Card ──
                  _BmiCard(
                    mainCtrl: _mainCtrl,
                    currentBmi: '23.4',
                    idealRange: '18.5 - 24.9',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  A. Weight Header – Numeric roll-up + badge slide
// ─────────────────────────────────────────────
class _WeightHeader extends StatelessWidget {
  final Animation<double> mainCtrl;

  const _WeightHeader({required this.mainCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: mainCtrl,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: mainCtrl,
          curve: const Interval(0.00, 0.20, curve: Curves.easeOutCubic),
        ).value);
        final currentWeight = 72.4 * t;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: currentWeight.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                          height: 1.0,
                        ),
                      ),
                      const TextSpan(
                        text: ' kg',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Badge slide & fade
            AnimatedBuilder(
              animation: mainCtrl,
              builder: (context, child) {
                final badgeT = _clamp01(CurvedAnimation(
                  parent: mainCtrl,
                  curve: const Interval(0.06, 0.24, curve: Curves.easeOutCubic),
                ).value);
                return Transform.translate(
                  offset: Offset(-15 * (1 - badgeT), 0),
                  child: Opacity(
                    opacity: badgeT,
                    child: Row(
                      children: const [
                        Icon(Icons.trending_down_rounded, size: 16, color: _mint),
                        SizedBox(width: 4),
                        Text(
                          '-0.4kg since yesterday',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _mint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  B. Weight Trend Chart – Path tracing + area fade
// ─────────────────────────────────────────────
class _WeightChart extends StatelessWidget {
  final Animation<double> mainCtrl;

  const _WeightChart({required this.mainCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: mainCtrl,
      builder: (context, child) {
        final revealT = _clamp01(CurvedAnimation(
          parent: mainCtrl,
          curve: const Interval(0.10, 0.50, curve: Curves.easeInOutCubic),
        ).value);
        final areaT = _clamp01(CurvedAnimation(
          parent: mainCtrl,
          curve: const Interval(0.40, 0.60),
        ).value);

        final animatedMaxX = 0.0 + (revealT * 6.0);

        return SizedBox(
          height: 240,
          child: Padding(
            padding: const EdgeInsets.only(right: 8, top: 6),
            child: LineChart(
              LineChartData(
                minY: 71.4,
                maxY: 75.2,
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value < 0 || value > 6) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[value.toInt()],
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: 0.95,
                      getTitlesWidget: (value, meta) {
                        final allowed = {71.4, 72.35, 73.3, 74.25, 75.2};
                        final rounded = double.parse(value.toStringAsFixed(2));
                        if (!allowed.contains(rounded)) return const SizedBox.shrink();
                        return Text(
                          value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), ''),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 74.25),
                      FlSpot(1, 73.95),
                      FlSpot(2, 73.85),
                      FlSpot(3, 73.6),
                      FlSpot(4, 72.95),
                      FlSpot(5, 72.55),
                      FlSpot(6, 72.35),
                    ],
                    isCurved: true,
                    color: _purple,
                    barWidth: 3,
                    curveSmoothness: 0.22,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: _purple,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: areaT > 0,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xAA7C63FF).withOpacity(areaT),
                          const Color(0x22FFFFFF).withOpacity(areaT * 0.2),
                        ],
                      ),
                    ),
                  ),
                ],
                minX: 0,
                maxX: animatedMaxX.clamp(0.5, 6.0),
              ),
              duration: const Duration(milliseconds: 1),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  C. Goal Progress Card
// ─────────────────────────────────────────────
class _GoalProgressCard extends StatelessWidget {
  final Animation<double> mainCtrl;

  const _GoalProgressCard({required this.mainCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: mainCtrl,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: mainCtrl,
          curve: const Interval(0.30, 0.50, curve: Curves.easeOutCubic),
        ).value);
        return Transform.translate(
          offset: Offset(0, 24 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: _CardShell(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Goal Progress',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                ),
                const Spacer(),
                _ProgressBadge(mainCtrl: mainCtrl, text: '51% Complete'),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar fill
            AnimatedBuilder(
              animation: mainCtrl,
              builder: (context, child) {
                final barT = _clamp01(CurvedAnimation(
                  parent: mainCtrl,
                  curve: const Interval(0.30, 0.56, curve: Curves.easeInOutQuart),
                ).value);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: 0.51 * barT,
                    backgroundColor: const Color(0xFFE7E3EF),
                    valueColor: const AlwaysStoppedAnimation<Color>(_purple),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Target numbers count-up
            AnimatedBuilder(
              animation: mainCtrl,
              builder: (context, child) {
                final countT = _clamp01(CurvedAnimation(
                  parent: mainCtrl,
                  curve: const Interval(0.34, 0.60, curve: Curves.easeOutCubic),
                ).value);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MiniStat(
                      label: 'START',
                      value: '${(77 * countT).round()}kg',
                      valueSize: 16,
                    ),
                    _MiniStat(
                      label: 'CURRENT',
                      value: '${(72.4 * countT).toStringAsFixed(1)}kg',
                      valueSize: 18,
                      accent: _purple,
                    ),
                    _MiniStat(
                      label: 'GOAL',
                      value: '${(68 * countT).round()}kg',
                      valueSize: 16,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  D. Milestone Card – Staggered entry + icon pulse
// ─────────────────────────────────────────────
class _MilestoneCard extends StatelessWidget {
  final Animation<double> mainCtrl;
  final int index;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String dateLabel;
  final bool highlighted;

  const _MilestoneCard({
    required this.mainCtrl,
    required this.index,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final stagger = 0.44 + (index * 0.08);

    return AnimatedBuilder(
      animation: mainCtrl,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: mainCtrl,
          curve: Interval(stagger, stagger + 0.20, curve: Curves.easeOutCubic),
        ).value);
        return Transform.translate(
          offset: Offset(0, 25 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: _CardShell(
        child: Container(
          decoration: BoxDecoration(
            color: highlighted ? const Color(0xFFF3F9FF) : _surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: AnimatedBuilder(
              animation: mainCtrl,
              builder: (context, child) {
                final iconT = _clamp01(CurvedAnimation(
                  parent: mainCtrl,
                  curve: Interval(stagger + 0.04, stagger + 0.16, curve: Curves.elasticOut),
                ).value);
                final iconScale = 0.0 + (iconT * 1.15).clamp(0.0, 1.15);
                return Transform.scale(
                  scale: iconScale > 1.0 ? iconScale - (iconScale - 1.0) * 0.8 : iconScale,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                );
              },
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            subtitle: Text(
              '$subtitle\n$dateLabel',
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: _textSecondary,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFC6C2CF)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  E. BMI Card – Scale-up + number roll
// ─────────────────────────────────────────────
class _BmiCard extends StatelessWidget {
  final Animation<double> mainCtrl;
  final String currentBmi;
  final String idealRange;

  const _BmiCard({
    required this.mainCtrl,
    required this.currentBmi,
    required this.idealRange,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: mainCtrl,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: mainCtrl,
          curve: const Interval(0.60, 0.78, curve: Curves.easeOutCubic),
        ).value);
        final bmiVal = 23.4 * t;
        return Transform.scale(
          scale: 0.96 + (t * 0.04),
          child: Opacity(
            opacity: t,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD2EEF9)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _purpleSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.monitor_weight_outlined, color: _purple, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CURRENT BMI',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF27B4D9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              bmiVal.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 3),
                              child: Text(
                                'Normal',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'IDEAL RANGE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        idealRange,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  F. FAB – Spring expansion
// ─────────────────────────────────────────────
class _WeightFab extends StatelessWidget {
  final Animation<double> mainCtrl;

  const _WeightFab({required this.mainCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: mainCtrl,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: mainCtrl,
          curve: const Interval(0.70, 0.90, curve: Curves.elasticOut),
        ).value);
        final scale = 0.0 + (t * 1.0);
        return Transform.scale(
          scale: scale,
          child: FloatingActionButton(
            onPressed: () {},
            backgroundColor: _purple,
            elevation: 6,
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  Shared Widgets
// ─────────────────────────────────────────────
class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});
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
          width: 34,
          height: 34,
          child: Icon(icon, size: 20, color: _textPrimary),
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, this.padding = EdgeInsets.zero});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SegmentPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Animation<double> mainCtrl;
  final VoidCallback onTap;

  const _SegmentPill({
    required this.label,
    required this.selected,
    required this.mainCtrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _surface : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: selected ? _textPrimary : _textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  final Animation<double> mainCtrl;
  final String text;

  const _ProgressBadge({required this.mainCtrl, required this.text});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: mainCtrl,
      builder: (context, child) {
        final t = _clamp01(CurvedAnimation(
          parent: mainCtrl,
          curve: const Interval(0.34, 0.48, curve: Curves.elasticOut),
        ).value);
        final scale = 0.85 + (t * 0.15);
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _purpleSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: _purple,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final double valueSize;
  final Color? accent;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.valueSize,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: FontWeight.w800,
            color: accent ?? _textPrimary,
          ),
        ),
      ],
    );
  }
}