import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'onboarding_step_scaffold.dart';

/// Step 3 — Target & Timeline (target weight, weekly pace, target date).
class TargetTimelineStep extends StatefulWidget {
  final VoidCallback onBack;
  final ValueChanged<Map<String, dynamic>> onContinue;

  const TargetTimelineStep({
    super.key,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<TargetTimelineStep> createState() => _TargetTimelineStepState();
}

class _TargetTimelineStepState extends State<TargetTimelineStep> {
  double _targetWeightKg = 65;
  double? _weeklyPaceKg;
  DateTime? _targetDate;

  static const _paces = [0.25, 0.5, 0.75, 1.0];

  void _continue() {
    if (_weeklyPaceKg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a weekly pace.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    widget.onContinue({
      'target_weight_kg': _targetWeightKg,
      'weekly_pace_kg': _weeklyPaceKg,
      if (_targetDate != null) 'target_date': _targetDate,
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(AppColors.authPurple),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Set your target',
      subtitle: 'Define where you want to be and how fast to get there.',
      showBack: true,
      buttonLabel: 'Continue',
      onBack: widget.onBack,
      onPrimary: _continue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('Target Weight'),
          _SliderField(
            value: _targetWeightKg,
            min: 35,
            max: 180,
            unit: 'kg',
            onChanged: (v) => setState(() => _targetWeightKg = v),
          ),
          const SizedBox(height: 20),

          const _FieldLabel('Weekly Pace'),
          Row(
            children: [
              for (final pace in _paces) ...[
                Expanded(
                  child: _PaceChip(
                    label: pace == 0.25
                        ? 'Gentle'
                        : pace == 0.5
                            ? 'Moderate'
                            : pace == 0.75
                                ? 'Steady'
                                : 'Fast',
                    value: '${pace.toStringAsFixed(2)} kg/wk',
                    isSelected: _weeklyPaceKg == pace,
                    onTap: () => setState(() => _weeklyPaceKg = pace),
                  ),
                ),
                if (pace != _paces.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 20),

          const _FieldLabel('Target Date (optional)'),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(AppColors.authPurple),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _targetDate == null
                          ? 'Pick a date (optional)'
                          : '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _targetDate == null
                            ? const Color(0xFF8A8A9A)
                            : const Color(0xFF14142B),
                      ),
                    ),
                  ),
                  if (_targetDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _targetDate = null),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF8A8A9A),
                        size: 18,
                      ),
                    ),
                ],
              ),
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

class _PaceChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaceChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
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
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF14142B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : const Color(0xFF8A8A9A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}