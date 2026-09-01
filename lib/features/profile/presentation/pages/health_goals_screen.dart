import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/domain/entities/goal_entity.dart';
import '../../../../core/domain/entities/user_profile_entity.dart';
import '../../../../core/domain/repositories/user_repository.dart';

const _bg = Color(0xFFF7F6FB);
const _surface = Colors.white;
const _purple = Color(AppColors.authPurple);
const _textPrimary = Color(0xFF1F1F2E);
const _textSecondary = Color(0xFF706D7B);
const _border = Color(0xFFE7E3EF);

/// Full-screen summary of the user's health & nutrition goals, loaded live
/// from the `goals` and `user_profiles` tables.
class HealthGoalsScreen extends StatefulWidget {
  const HealthGoalsScreen({super.key});

  @override
  State<HealthGoalsScreen> createState() => _HealthGoalsScreenState();
}

class _HealthGoalsScreenState extends State<HealthGoalsScreen> {
  GoalEntity? _goals;
  UserProfileEntity? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final repo = sl<UserRepository>();
      final goals = await repo.getUserGoals(user.id);
      final profile = await repo.getUserProfile(user.id);
      if (!mounted) return;
      setState(() {
        _goals = goals;
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      debugPrint('HealthGoals load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String _titleCase(String? s) {
    if (s == null || s.isEmpty) return '-';
    return s.split('_').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }

  String _fmtNum(double? v) => v == null
      ? '-'
      : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _textPrimary, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Health Goals',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: _textPrimary)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _purple))
          : _goals == null && _profile == null
              ? const Center(
                  child: Text('No goal data found.',
                      style: TextStyle(color: _textSecondary)),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final g = _goals;
    final p = _profile;
    final goalType = g?.goalType ?? p?.goalType;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _goalBanner(goalType, g),
          const SizedBox(height: 16),
          const _SectionLabel('DAILY TARGETS'),
          const SizedBox(height: 10),
          _twoGoals(g, p),
          const SizedBox(height: 20),
          const _SectionLabel('BODY & LIFESTYLE'),
          const SizedBox(height: 10),
          _card([
            _rowItem(Icons.height_rounded, 'Height',
                p?.heightCm != null ? '${_fmtNum(p!.heightCm)} cm' : '-'),
            _rowItem(Icons.scale_outlined, 'Current weight',
                p?.currentWeightKg != null
                    ? '${_fmtNum(p!.currentWeightKg)} kg'
                    : p?.weightKg != null
                        ? '${_fmtNum(p!.weightKg)} kg'
                        : '-'),
            _rowItem(Icons.speed_rounded, 'Activity level',
                _titleCase(p?.activityLevel)),
            _rowItem(Icons.fitness_center_rounded, 'Goal type',
                _titleCase(goalType)),
            _rowItem(Icons.flash_on_rounded, 'Weekly pace',
                g?.weeklyPaceKg != null ? '${_fmtNum(g!.weeklyPaceKg)} kg/wk' : '-'),
          ]),
        ],
      ),
    );
  }
Widget _goalBanner(String? goalType, GoalEntity? g) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(AppColors.authPurple), Color(AppColors.authPurpleLight)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PRIMARY GOAL',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            _titleCase(goalType),
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            g?.targetDate != null
                ? 'Goal ${_fmtDate(g!.targetDate!)}'
                : 'Daily targets set for your nutrition',
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _twoGoals(GoalEntity? g, UserProfileEntity? p) {
    final cal = g?.targetCalories ?? 0;
    final protein = g?.targetProtein ?? 0.0;
    final carbs = g?.targetCarbs ?? 0.0;
    final fat = g?.targetFat ?? 0.0;
    return Row(
      children: [
        Expanded(
          child: _goalStatCard(
            Icons.local_fire_department_rounded,
            'Calories',
            '${cal.toString()} kcal',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _goalStatCard(
            Icons.restaurant_rounded,
            'Macros',
            'P ${_fmtNum(protein)} · C ${_fmtNum(carbs)} · F ${_fmtNum(fat)}',
          ),
        ),
      ],
    );
  }

  Widget _goalStatCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _purple, size: 20),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary)),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 12, color: _textSecondary)),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _border),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _rowItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: _purple, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: _textSecondary,
      ),
    );
  }
}