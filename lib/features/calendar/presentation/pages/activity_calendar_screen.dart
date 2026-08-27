import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/domain/entities/calendar_tracking.dart';
import '../../../../core/domain/usecases/all_usecases.dart';
import '../../../../core/di/service_locator.dart';

const _bg = Color(0xFFF7F6FB);
const _surface = Colors.white;
const _purple = Color(AppColors.authPurple);
const _purpleSoft = Color(0xFFF0ECFF);
const _textPrimary = Color(0xFF1F1F2E);
const _textSecondary = Color(0xFF72707F);
const _border = Color(0xFFE7E3EF);
const _waterBlue = Color(0xFF2DCFF1);
const _calorieOrange = Color(0xFFF5A623);

class ActivityCalendarScreen extends StatefulWidget {
  const ActivityCalendarScreen({super.key});

  @override
  State<ActivityCalendarScreen> createState() => _ActivityCalendarScreenState();
}

class _ActivityCalendarScreenState extends State<ActivityCalendarScreen> {
  late DateTime _month; // First day of the currently shown month
  CalendarTracking? _tracking;
  bool _loading = true;
  String? _error;
  DateTime? _selectedDay;
  final DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
    _load();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _error = 'Not signed in';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final start = DateTime(_month.year, _month.month, 1);
    final end = DateTime(_month.year, _month.month + 1, 0);

    try {
      final data = await sl<FetchCalendarTrackingUseCase>().call(
        userId: user.id,
        start: start,
        end: end,
      );
      if (!mounted) return;
      setState(() {
        _tracking = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _prevMonth() {
    if (_loading) return;
    setState(() => _month = DateTime(_month.year, _month.month - 1));
    _load();
  }

  void _nextMonth() {
    if (_loading) return;
    setState(() => _month = DateTime(_month.year, _month.month + 1));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _purple))
                  : _error != null
                      ? _buildError()
                      : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: _textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Activity Calendar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _purpleSoft,
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_fire_department_rounded,
                    size: 15, color: _purple),
                SizedBox(width: 4),
                Text(
                  'Streak Tracker',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: _purple),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 42, color: _textSecondary),
          const SizedBox(height: 12),
          Text(
            'Could not load your activity.\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _textSecondary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(backgroundColor: _purple),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          _buildMonthCard(),
          const SizedBox(height: 16),
          _buildLegend(),
          const SizedBox(height: 16),
          _buildSelectedDayDetail(),
        ],
      ),
    );
  }
Widget _buildMonthCard() {
    const weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final firstDayWeekday = _month.weekday - 1; // 0 = Monday
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;

    final cells = <Widget>[];
    for (int i = 0; i < firstDayWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_month.year, _month.month, day);
      cells.add(_buildDayCell(date));
    }
    final remaining = (7 - (cells.length % 7)) % 7;
    for (int i = 0; i < remaining; i++) {
      cells.add(const SizedBox.shrink());
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _monthNav(Icons.chevron_left_rounded, _prevMonth),
              Expanded(
                child: Text(
                  '${_monthName(_month.month)} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
              ),
              _monthNav(Icons.chevron_right_rounded, _nextMonth),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: weekDays
                .map((d) => Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _textSecondary,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: cells,
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final tracking = _tracking;
    final isToday = _isSameDay(date, _today);
    final isSelected = _selectedDay != null && _isSameDay(date, _selectedDay!);

    final hasWaterGoal = (tracking?.targetWaterMl ?? 0) > 0;
    final hasCalGoal = (tracking?.targetCalories ?? 0) > 0;
    final waterLogged = (tracking?.waterOn(date) ?? 0) > 0;
    final caloriesLogged = (tracking?.caloriesOn(date) ?? 0) > 0;
    final waterHit = tracking?.waterHitOn(date) ?? false;
    final caloriesHit = tracking?.caloriesHitOn(date) ?? false;

    final bg = isToday
        ? _purple
        : isSelected
            ? _purpleSoft
            : _surface;
    final numberColor = isToday ? Colors.white : _textPrimary;

    return GestureDetector(
      onTap: () => setState(() => _selectedDay = date),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: numberColor,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _goalDayIcon(
                  hasGoal: hasWaterGoal,
                  hit: waterHit,
                  logged: waterLogged,
                ),
                const SizedBox(width: 3),
                _goalDayIcon(
                  hasGoal: hasCalGoal,
                  hit: caloriesHit,
                  logged: caloriesLogged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Per-goal mini mark in a calendar cell:
  /// - green check → goal reached that day
  /// - red cross → activity logged that day but below goal
  /// - gray dot   → nothing logged (or no goal set)
  Widget _goalDayIcon({
    required bool hasGoal,
    required bool hit,
    required bool logged,
  }) {
    if (hasGoal && hit) {
      return const Icon(Icons.check_circle_rounded,
          size: 11, color: Color(0xFF34C759));
    }
    if (hasGoal && logged) {
      return const Icon(Icons.cancel_rounded,
          size: 11, color: Color(0xFFE53935));
    }
    return const _MiniDot(color: Color(0xFFD0CDDD), size: 4);
  }
Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legendItem(
            const Icon(Icons.check_circle_rounded,
                size: 14, color: Color(0xFF34C759)),
            'Goal met',
          ),
          _legendItem(
            const Icon(Icons.cancel_rounded, size: 14, color: Color(0xFFE53935)),
            'Below goal',
          ),
          _legendItem(
            const Icon(Icons.today_rounded, size: 14, color: _purple),
            'Today',
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Widget dot, String label) {
    return Row(
      children: [
        dot,
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDayDetail() {
    final date = _selectedDay;
    if (date == null) {
      return const SizedBox.shrink();
    }
    final tracking = _tracking;

    final water = tracking?.waterOn(date) ?? 0;
    final calories = tracking?.caloriesOn(date) ?? 0;
    final waterTarget = tracking?.targetWaterMl ?? 0;
    final calTarget = tracking?.targetCalories ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B4EE8), Color(0xFF8f7dff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateFormat('EEEE, d MMMM').format(date)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _detailTile(
                  icon: Icons.water_drop_rounded,
                  value: '$water / ${waterTarget > 0 ? waterTarget : 0} ml',
                  label: 'Water',
                  done: waterTarget > 0 && water >= waterTarget,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _detailTile(
                  icon: Icons.local_fire_department_rounded,
                  value: '$calories / ${calTarget > 0 ? calTarget : 0} kcal',
                  label: 'Calories',
                  done: calTarget > 0 && calories >= calTarget,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailTile({
    required IconData icon,
    required String value,
    required String label,
    required bool done,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (done)
                const Icon(Icons.check_circle_rounded,
                    size: 18, color: Color(0xFF34C759))
              else
                Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthNav(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _purpleSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: _purple),
      ),
    );
  }

  static String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month - 1];
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MiniDot extends StatelessWidget {
  final Color color;
  final double size;
  const _MiniDot({required this.color, this.size = 5});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}