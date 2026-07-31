import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'onboarding_step_scaffold.dart';

/// Step 4 — Activity Level & Diet Preference.
class ActivityDietStep extends StatefulWidget {
  final bool isSubmitting;
  final VoidCallback onBack;
  final ValueChanged<Map<String, dynamic>> onSubmit;

  const ActivityDietStep({
    super.key,
    required this.isSubmitting,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  State<ActivityDietStep> createState() => _ActivityDietStepState();
}

class _ActivityDietStepState extends State<ActivityDietStep> {
  String? _activityLevel;
  String? _dietPreference;
  int _workoutFrequency = 3;

  static const _activities = [
    _ActivityOption(
      id: 'sedentary',
      title: 'Sedentary',
      subtitle: 'Little / no exercise',
      icon: Icons.weekend_rounded,
    ),
    _ActivityOption(
      id: 'lightly_active',
      title: 'Lightly Active',
      subtitle: '1-3 days / week',
      icon: Icons.directions_walk_rounded,
    ),
    _ActivityOption(
      id: 'moderately_active',
      title: 'Moderately Active',
      subtitle: '3-5 days / week',
      icon: Icons.directions_run_rounded,
    ),
    _ActivityOption(
      id: 'very_active',
      title: 'Very Active',
      subtitle: '6-7 days / week',
      icon: Icons.fitness_center_rounded,
    ),
  ];

  static const _diets = [
    _DietOption(id: 'balanced', title: 'Balanced', icon: Icons.restaurant_rounded),
    _DietOption(id: 'high_protein', title: 'High Protein', icon: Icons.egg_alt_rounded),
    _DietOption(id: 'keto', title: 'Keto', icon: Icons.av_timer_rounded),
    _DietOption(id: 'vegan', title: 'Vegan', icon: Icons.eco_rounded),
  ];

  void _submit() {
    if (_activityLevel == null || _dietPreference == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select activity level and diet preference.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    widget.onSubmit({
      'activity_level': _activityLevel,
      'diet_preference': _dietPreference,
      'workout_frequency': _workoutFrequency,
    });
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Activity & Diet',
      subtitle: 'Fuel your body the right way. We’ll tailor your daily targets.',
      showBack: true,
      buttonLabel: 'Calculate & Get Started',
      isSubmitting: widget.isSubmitting,
      onBack: widget.onBack,
      onPrimary: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('Activity Level'),
          Column(
            children: [
              for (final activity in _activities) ...[
                _ActivityCard(
                  option: activity,
                  isSelected: _activityLevel == activity.id,
                  onTap: () => setState(() => _activityLevel = activity.id),
                ),
                if (activity != _activities.last) const SizedBox(height: 10),
              ],
            ],
          ),
          const SizedBox(height: 24),

          const _FieldLabel('Diet Preference'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final diet in _diets)
                _DietChip(
                  option: diet,
                  isSelected: _dietPreference == diet.id,
                  onTap: () => setState(() => _dietPreference = diet.id),
                ),
            ],
          ),
          const SizedBox(height: 24),

          const _FieldLabel('Workout Frequency'),
          _StepperField(
            value: _workoutFrequency,
            unit: 'days/wk',
            onDecrement: () => setState(
              () => _workoutFrequency = (_workoutFrequency - 1).clamp(0, 7),
            ),
            onIncrement: () => setState(
              () => _workoutFrequency = (_workoutFrequency + 1).clamp(0, 7),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF14142B),
        ),
      ),
    );
  }
}

class _ActivityOption {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const _ActivityOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _ActivityCard extends StatelessWidget {
  final _ActivityOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(AppColors.authPurple),
                    Color(AppColors.authPurpleLight),
                  ],
                )
              : null,
          color: isSelected
              ? const Color(AppColors.authPurple)
              : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(AppColors.authPurple)
                : Colors.white.withValues(alpha: 0.8),
          ),
        ),
        child: Row(
          children: [
            Icon(
              option.icon,
              color: isSelected ? Colors.white : const Color(AppColors.authPurple),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : const Color(0xFF14142B),
                      ),
                    ),
                  ),
                  Text(
                    option.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.85)
                          : const Color(0xFF8A8A9A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected ? Colors.white : const Color(0xFFC9C7DF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _DietOption {
  final String id;
  final String title;
  final IconData icon;

  const _DietOption({
    required this.id,
    required this.title,
    required this.icon,
  });
}

class _DietChip extends StatelessWidget {
  final _DietOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _DietChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(AppColors.authPurple),
                    Color(AppColors.authPurpleLight),
                  ],
                )
              : null,
          color: isSelected
              ? const Color(AppColors.authPurple)
              : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? const Color(AppColors.authPurple)
                : Colors.white.withValues(alpha: 0.8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              option.icon,
              color: isSelected ? Colors.white : const Color(AppColors.authPurple),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              option.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF14142B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperField extends StatelessWidget {
  final int value;
  final String unit;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _StepperField({
    required this.value,
    required this.unit,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: onDecrement,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(AppColors.authPurple).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.remove_rounded,
                color: Color(AppColors.authPurple),
                size: 22,
              ),
            ),
          ),
          Text(
            '$value $unit',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF14142B),
            ),
          ),
          InkWell(
            onTap: onIncrement,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(AppColors.authPurple).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(AppColors.authPurple),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}