import 'package:flutter/material.dart';
import 'onboarding_step_scaffold.dart';

/// Step 1 — Primary Goal Selection.
class GoalStep extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onContinue;

  const GoalStep({super.key, required this.onContinue});

  @override
  State<GoalStep> createState() => _GoalStepState();
}

class _GoalStepState extends State<GoalStep> {
  String? _selectedGoal;

  static const _goals = [
    _GoalOption(
      id: 'weight_loss',
      title: 'Weight Loss',
      subtitle: 'Burn fat & shed kilos',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFFF8A50),
    ),
    _GoalOption(
      id: 'weight_gain',
      title: 'Weight Gain',
      subtitle: 'Add lean mass',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF34C759),
    ),
    _GoalOption(
      id: 'maintain',
      title: 'Maintain Weight',
      subtitle: 'Stay balanced & healthy',
      icon: Icons.balance_rounded,
      color: Color(0xFF0EA5E9),
    ),
    _GoalOption(
      id: 'cutting',
      title: 'Muscle Building / Cutting',
      subtitle: 'Define & tone muscles',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFF5B4EE8),
    ),
  ];

  void _continue() {
    if (_selectedGoal == null) {
      _showValidation();
      return;
    }
    widget.onContinue({'goal_type': _selectedGoal});
  }

  void _showValidation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select a primary goal.'),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'What’s your primary goal?',
      subtitle: 'This helps us personalize your calorie & macro targets.',
      showBack: false,
      buttonLabel: 'Continue',
      onBack: () {},
      onPrimary: _continue,
      child: Column(
        children: [
          for (final goal in _goals) ...[
            _GoalCard(
              option: goal,
              isSelected: _selectedGoal == goal.id,
              onTap: () => setState(() => _selectedGoal = goal.id),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _GoalOption {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _GoalOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _GoalCard extends StatelessWidget {
  final _GoalOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    option.color.withValues(alpha: 0.20),
                    option.color.withValues(alpha: 0.05),
                  ],
                )
              : null,
          color: Colors.white.withValues(alpha: isSelected ? 0.5 : 0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? option.color.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.6),
            width: isSelected ? 2 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: option.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(option.icon, color: option.color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF14142B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option.subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF8A8A9A),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? option.color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? option.color : const Color(0xFFC9C7DF),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}