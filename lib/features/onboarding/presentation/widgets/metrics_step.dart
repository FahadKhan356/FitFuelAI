import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'onboarding_step_scaffold.dart';

/// Step 2 — Biological Metrics (age, gender, height, weight).
class MetricsStep extends StatefulWidget {
  final VoidCallback onBack;
  final ValueChanged<Map<String, dynamic>> onContinue;

  const MetricsStep({
    super.key,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<MetricsStep> createState() => _MetricsStepState();
}

class _MetricsStepState extends State<MetricsStep> {
  int _age = 25;
  String _gender = 'female';
  double _heightCm = 170;
  double _weightKg = 70;

  void _continue() {
    widget.onContinue({
      'age': _age,
      'gender': _gender,
      'height_cm': _heightCm,
      'weight_kg': _weightKg,
    });
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Tell us about you',
      subtitle: 'We use these metrics to calculate your BMR & TDEE.',
      showBack: true,
      buttonLabel: 'Continue',
      onBack: widget.onBack,
      onPrimary: _continue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('Age'),
          _StepperField(
            value: _age,
            unit: 'yrs',
            onDecrement: () => setState(() => _age = (_age - 1).clamp(14, 100)),
            onIncrement: () => setState(() => _age = (_age + 1).clamp(14, 100)),
          ),
          const SizedBox(height: 20),

          const _FieldLabel('Gender'),
          Row(
            children: [
              Expanded(
                child: _GenderToggle(
                  label: 'Female',
                  icon: Icons.female_rounded,
                  isSelected: _gender == 'female',
                  onTap: () => setState(() => _gender = 'female'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GenderToggle(
                  label: 'Male',
                  icon: Icons.male_rounded,
                  isSelected: _gender == 'male',
                  onTap: () => setState(() => _gender = 'male'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const _FieldLabel('Height'),
          _SliderField(
            value: _heightCm,
            min: 130,
            max: 220,
            unit: 'cm',
            onChanged: (v) => setState(() => _heightCm = v),
          ),
          const SizedBox(height: 20),

          const _FieldLabel('Current Weight'),
          _SliderField(
            value: _weightKg,
            min: 35,
            max: 180,
            unit: 'kg',
            onChanged: (v) => setState(() => _weightKg = v),
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
          _StepButton(icon: Icons.remove_rounded, onTap: onDecrement),
          Text(
            '$value $unit',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF14142B),
            ),
          ),
          _StepButton(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(AppColors.authPurple).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(AppColors.authPurple), size: 22),
      ),
    );
  }
}

class _GenderToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderToggle({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(AppColors.authPurple), Color(AppColors.authPurpleLight)],
                )
              : null,
          color: isSelected
              ? const Color(AppColors.authPurple)
              : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(AppColors.authPurple)
                : Colors.white.withValues(alpha: 0.8),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF8A8A9A),
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
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

class _SliderField extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;

  const _SliderField({
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${value.toStringAsFixed(0)} $unit',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF14142B),
                ),
              ),
              Text(
                '${min.toStringAsFixed(0)}-$max',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8A8A9A)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(AppColors.authPurple),
              inactiveTrackColor:
                  const Color(AppColors.authPurple).withValues(alpha: 0.15),
              thumbColor: const Color(AppColors.authPurple),
              overlayColor:
                  const Color(AppColors.authPurple).withValues(alpha: 0.12),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}