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

class WeightTrackerScreen extends StatelessWidget {
  const WeightTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: _purple,
        elevation: 6,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: '72.4',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                                height: 1.0,
                              ),
                            ),
                            TextSpan(
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
                  Row(
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
                  const SizedBox(height: 16),
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
                            const _SegmentPill(label: 'WEEK', selected: true),
                            const SizedBox(width: 8),
                            const _SegmentPill(label: 'MONTH'),
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
                        SizedBox(
                          height: 240,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8, top: 6),
                            child: LineChart(_buildLineData()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _CardShell(
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
                            const _ProgressBadge(text: '51% Complete'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: 0.51,
                            backgroundColor: const Color(0xFFE7E3EF),
                            valueColor: const AlwaysStoppedAnimation<Color>(_purple),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _MiniStat(
                              label: 'START',
                              value: '77kg',
                              valueSize: 16,
                            ),
                            _MiniStat(
                              label: 'CURRENT',
                              value: '72.4kg',
                              valueSize: 18,
                              accent: _purple,
                            ),
                            _MiniStat(
                              label: 'GOAL',
                              value: '68kg',
                              valueSize: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  const _MilestoneCard(
                    icon: Icons.emoji_events_outlined,
                    iconBg: Color(0xFFE9F3FF),
                    iconColor: Color(0xFF4A6FFF),
                    title: 'First 5kg Lost',
                    subtitle: "You've hit your first major weight",
                    dateLabel: 'OCT 12, 2023',
                    highlighted: true,
                  ),
                  const SizedBox(height: 12),
                  const _MilestoneCard(
                    icon: Icons.adjust_outlined,
                    iconBg: Color(0xFFF1F0F7),
                    iconColor: Color(0xFF8A8A96),
                    title: 'Halfway Point',
                    subtitle: '4.6kg down, 4.4kg to go for your',
                    dateLabel: 'IN PROGRESS',
                  ),
                  const SizedBox(height: 12),
                  const _MilestoneCard(
                    icon: Icons.auto_awesome_rounded,
                    iconBg: Color(0xFFF1ECFF),
                    iconColor: Color(0xFF5B4EE8),
                    title: '7 Day Log Streak',
                    subtitle: 'Consistency is key! You logged',
                    dateLabel: 'TODAY',
                  ),
                  const SizedBox(height: 12),
                  _BmiCard(
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

LineChartData _buildLineData() {
  final spots = <FlSpot>[
    const FlSpot(0, 74.25),
    const FlSpot(1, 73.95),
    const FlSpot(2, 73.85),
    const FlSpot(3, 73.6),
    const FlSpot(4, 72.95),
    const FlSpot(5, 72.55),
    const FlSpot(6, 72.35),
  ];

  return LineChartData(
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
        spots: spots,
        isCurved: true,
        color: _purple,
        barWidth: 3,
        curveSmoothness: 0.22,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xAA7C63FF), Color(0x22FFFFFF)],
          ),
        ),
      ),
    ],
  );
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
  });

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
  const _CardShell({
    required this.child,
    this.padding = EdgeInsets.zero,
  });

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
  const _SegmentPill({
    required this.label,
    this.selected = false,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.valueSize,
    this.accent,
  });

  final String label;
  final String value;
  final double valueSize;
  final Color? accent;

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

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    this.highlighted = false,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String dateLabel;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Container(
        decoration: BoxDecoration(
          color: highlighted ? const Color(0xFFF3F9FF) : _surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
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
    );
  }
}

class _BmiCard extends StatelessWidget {
  const _BmiCard({
    required this.currentBmi,
    required this.idealRange,
  });

  final String currentBmi;
  final String idealRange;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      currentBmi,
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
    );
  }
}
