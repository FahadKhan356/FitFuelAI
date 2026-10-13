import 'package:fitfuel_ai/core/constants/app_colors.dart';
import 'package:fitfuel_ai/core/di/service_locator.dart';
import 'package:fitfuel_ai/core/domain/usecases/all_usecases.dart';
import 'package:fitfuel_ai/core/utils/bmi_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _kPurple = Color(AppColors.authPurple);

enum _UnitSystem { metric, imperial }

class BmiScreen extends StatefulWidget {
  const BmiScreen({super.key});

  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  _UnitSystem _unitSystem = _UnitSystem.metric;
  bool _isMale = true;
  int _age = 25;

  // Stored in canonical metric values internally
  double _weightKg = 72;
  double _heightCm = 175;

  bool _isSaving = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _isDark ? const Color(0xFF0B0E14) : const Color(0xFFF8F9FE);
  Color get _surface => _isDark ? const Color(0xFF141824) : Colors.white;
  Color get _surfaceAlt =>
      _isDark ? const Color(0xFF1C2235) : const Color(0xFFF1F5F9);
  Color get _borderColor =>
      _isDark ? const Color(0xFF23283E) : const Color(0xFFE2E8F0);
  Color get _textPrimary =>
      _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  Color get _textSecondary =>
      _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    _loadProfileValues();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileValues() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        return;
      }
      final profile = await sl<LoadUserProfileUseCase>().call(userId);
      if (profile == null || !mounted) {
        return;
      }

      setState(() {
        final effectiveWeight = profile.currentWeightKg ?? profile.weightKg;
        if (effectiveWeight != null && effectiveWeight > 0) {
          _weightKg = effectiveWeight;
        }
        if (profile.heightCm != null && profile.heightCm! > 0) {
          _heightCm = profile.heightCm!;
        }
        if (profile.gender != null) {
          _isMale = profile.gender!.toLowerCase() != 'female';
        }
        if (profile.age != null && profile.age! > 0) {
          _age = profile.age!;
        }
      });
    } on Object catch (_) {
      // Fallback to defaults
    }
  }

  Future<void> _saveWeightToProfile() async {
    await HapticFeedback.mediumImpact();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save your weight.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final bmiResult = BmiCalculator.calculate(
        weightKg: _weightKg,
        heightCm: _heightCm,
        age: _age,
        isMale: _isMale,
      );

      // 1. Log weight entry
      await sl<TrackWeightUseCase>().call(
        userId,
        DateTime.now(),
        _weightKg,
        _heightCm,
        bmiResult.estimatedBodyFatPercentage,
        'Logged via BMI Calculator',
      );

      // 2. Update user profile current weight
      await sl<UpdateUserProfileUseCase>().call(userId, {
        'current_weight_kg': _weightKg,
        'height_cm': _heightCm,
        'age': _age,
        'gender': _isMale ? 'male' : 'female',
      });

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Weight $_displayWeightText successfully logged to your profile!',
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save weight: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String get _displayWeightText => _unitSystem == _UnitSystem.metric
      ? '${_weightKg.toStringAsFixed(1)} kg'
      : '${BmiCalculator.kgToLbs(_weightKg).toStringAsFixed(1)} lbs';

  Color _categoryColor(BmiCategory category) => switch (category) {
        BmiCategory.severeUnderweight ||
        BmiCategory.moderateUnderweight ||
        BmiCategory.mildUnderweight =>
          const Color(0xFF3B82F6),
        BmiCategory.normal => const Color(0xFF10B981),
        BmiCategory.overweight => const Color(0xFFF59E0B),
        BmiCategory.obeseClassI ||
        BmiCategory.obeseClassII ||
        BmiCategory.obeseClassIII =>
          const Color(0xFFEF4444),
      };

  @override
  Widget build(BuildContext context) {
    final result = BmiCalculator.calculate(
      weightKg: _weightKg,
      heightCm: _heightCm,
      age: _age,
      isMale: _isMale,
    );

    final catColor = _categoryColor(result.category);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroBmiCard(result, catColor),
                    const SizedBox(height: 14),
                    _buildGaugeSpectrumCard(result, catColor),
                    const SizedBox(height: 14),
                    _buildBodyCompositionRow(result),
                    const SizedBox(height: 16),
                    _buildInputControls(),
                    const SizedBox(height: 16),
                    _buildCategoriesBreakdown(result.category),
                    const SizedBox(height: 16),
                    _buildActionAdviceCard(result, catColor),
                    const SizedBox(height: 22),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 17,
                    color: _textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'BMI Calculator',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
            ),
            _buildUnitSegmentedToggle(),
          ],
        ),
      );

  Widget _buildUnitSegmentedToggle() => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: _surfaceAlt,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _unitPill('Metric', _unitSystem == _UnitSystem.metric, () {
              HapticFeedback.selectionClick();
              setState(() => _unitSystem = _UnitSystem.metric);
            }),
            _unitPill('Imperial', _unitSystem == _UnitSystem.imperial, () {
              HapticFeedback.selectionClick();
              setState(() => _unitSystem = _UnitSystem.imperial);
            }),
          ],
        ),
      );

  Widget _unitPill(String text, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? _kPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : _textSecondary,
            ),
          ),
        ),
      );

  Widget _buildHeroBmiCard(BmiResult result, Color catColor) {
    final healthyRange = _unitSystem == _UnitSystem.metric
        ? '${result.healthyWeightMinKg.toStringAsFixed(0)} – ${result.healthyWeightMaxKg.toStringAsFixed(0)} kg'
        : '${BmiCalculator.kgToLbs(result.healthyWeightMinKg).toStringAsFixed(0)} – ${BmiCalculator.kgToLbs(result.healthyWeightMaxKg).toStringAsFixed(0)} lbs';

    final deltaText = result.deltaToHealthyKg == 0
        ? 'Healthy weight maintained'
        : result.deltaToHealthyKg < 0
            ? 'Gain ${_unitSystem == _UnitSystem.metric ? result.deltaToHealthyKg.abs().toStringAsFixed(1) : BmiCalculator.kgToLbs(result.deltaToHealthyKg.abs()).toStringAsFixed(1)} ${_unitSystem == _UnitSystem.metric ? "kg" : "lbs"} to reach healthy band'
            : 'Lose ${_unitSystem == _UnitSystem.metric ? result.deltaToHealthyKg.toStringAsFixed(1) : BmiCalculator.kgToLbs(result.deltaToHealthyKg).toStringAsFixed(1)} ${_unitSystem == _UnitSystem.metric ? "kg" : "lbs"} to reach healthy band';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: catColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: catColor.withValues(alpha: _isDark ? 0.15 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR BODY MASS INDEX',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: _textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          result.bmi.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: catColor,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'BMI',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: catColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  result.category.diagnostic.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: catColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  result.deltaToHealthyKg == 0
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  size: 18,
                  color: catColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deltaText,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Normal WHO Band: $healthyRange',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeSpectrumCard(BmiResult result, Color catColor) {
    // Clamping BMI between 14.0 (min) and 38.0 (max) for gauge indicator
    final clampedBmi = result.bmi.clamp(14.0, 38.0);
    final indicatorRatio = ((clampedBmi - 14.0) / (38.0 - 14.0)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'BMI Spectrum Scale',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'WHO Clinical Standard',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final pinPosition = (indicatorRatio * width)
                  .clamp(8.0, width - 8.0);

              return Column(
                children: [
                  // Animated pin needle
                  SizedBox(
                    height: 20,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: pinPosition - 10,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 20,
                                height: 14,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: catColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  result.bmi.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 12,
                                color: catColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Segmented bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 10,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 19, // ~14 to 18.5
                            child: Container(color: const Color(0xFF3B82F6)),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            flex: 27, // 18.5 to 25.0
                            child: Container(color: const Color(0xFF10B981)),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            flex: 21, // 25.0 to 30.0
                            child: Container(color: const Color(0xFFF59E0B)),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            flex: 33, // 30.0 to 38.0
                            child: Container(color: const Color(0xFFEF4444)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Zone Labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _scaleLabel('< 18.5', 'Underweight'),
                      _scaleLabel('18.5 – 24.9', 'Normal'),
                      _scaleLabel('25 – 29.9', 'Overweight'),
                      _scaleLabel('≥ 30', 'Obese'),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _scaleLabel(String range, String label) => Column(
        children: [
          Text(
            range,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
        ],
      );

  Widget _buildBodyCompositionRow(BmiResult result) => Row(
        children: [
          Expanded(
            child: _statPill(
              title: 'Est. Body Fat',
              value: result.estimatedBodyFatPercentage != null
                  ? '${result.estimatedBodyFatPercentage!.toStringAsFixed(1)}%'
                  : '—',
              subtitle: _isMale ? 'Male avg' : 'Female avg',
              icon: Icons.pie_chart_rounded,
              color: const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statPill(
              title: 'Daily BMR',
              value: result.bmrKcal != null
                  ? '${result.bmrKcal!.round()} kcal'
                  : '—',
              subtitle: 'Base energy',
              icon: Icons.local_fire_department_rounded,
              color: const Color(0xFFFFA24A),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statPill(
              title: 'BMI Prime',
              value: result.bmiPrime.toStringAsFixed(2),
              subtitle: '1.0 = normal bound',
              icon: Icons.speed_rounded,
              color: const Color(0xFF5BDBF5),
            ),
          ),
        ],
      );

  Widget _statPill({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: _textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: _textSecondary,
              ),
            ),
          ],
        ),
      );

  Widget _buildInputControls() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gender and Age row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      _genderButton(
                        'Male',
                        Icons.male_rounded,
                        _isMale,
                        () => setState(() => _isMale = true),
                      ),
                      const SizedBox(width: 8),
                      _genderButton(
                        'Female',
                        Icons.female_rounded,
                        !_isMale,
                        () => setState(() => _isMale = false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _stepperButton(Icons.remove, () {
                          if (_age > 10) {
                            setState(() => _age--);
                          }
                        }),
                        Text(
                          '$_age yrs',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                          ),
                        ),
                        _stepperButton(Icons.add, () {
                          if (_age < 100) {
                            setState(() => _age++);
                          }
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Weight control
            _weightSliderCard(),
            const SizedBox(height: 14),
            // Height control
            _heightSliderCard(),
          ],
        ),
      );

  Widget _genderButton(
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) =>
      Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? _kPurple.withValues(alpha: 0.14)
                    : _surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? _kPurple : _borderColor,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? _kPurple : _textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? _kPurple : _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _weightSliderCard() {
    final displayVal = _unitSystem == _UnitSystem.metric
        ? _weightKg
        : BmiCalculator.kgToLbs(_weightKg);
    final unit = _unitSystem == _UnitSystem.metric ? 'kg' : 'lbs';
    final minVal = _unitSystem == _UnitSystem.metric ? 30.0 : 66.0;
    final maxVal = _unitSystem == _UnitSystem.metric ? 180.0 : 396.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weight',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _textSecondary,
                ),
              ),
              Row(
                children: [
                  _stepperButton(Icons.remove, () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (_unitSystem == _UnitSystem.metric) {
                        _weightKg = (_weightKg - 0.5).clamp(30.0, 180.0);
                      } else {
                        final lbs = BmiCalculator.kgToLbs(_weightKg) - 1.0;
                        _weightKg =
                            BmiCalculator.lbsToKg(lbs).clamp(30.0, 180.0);
                      }
                    });
                  }),
                  const SizedBox(width: 8),
                  Text(
                    '${displayVal.toStringAsFixed(1)} $unit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _stepperButton(Icons.add, () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (_unitSystem == _UnitSystem.metric) {
                        _weightKg = (_weightKg + 0.5).clamp(30.0, 180.0);
                      } else {
                        final lbs = BmiCalculator.kgToLbs(_weightKg) + 1.0;
                        _weightKg =
                            BmiCalculator.lbsToKg(lbs).clamp(30.0, 180.0);
                      }
                    });
                  }),
                ],
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _kPurple,
              inactiveTrackColor: _borderColor,
              thumbColor: _kPurple,
              trackHeight: 4,
            ),
            child: Slider(
              value: displayVal.clamp(minVal, maxVal),
              min: minVal,
              max: maxVal,
              onChanged: (val) {
                setState(() {
                  _weightKg = _unitSystem == _UnitSystem.metric
                      ? val
                      : BmiCalculator.lbsToKg(val);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _heightSliderCard() {
    final unit = _unitSystem == _UnitSystem.metric ? 'cm' : 'ft / in';
    final feet = (_heightCm / 30.48).floor();
    final inches = ((_heightCm % 30.48) / 2.54).round();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Height',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _textSecondary,
                ),
              ),
              Row(
                children: [
                  _stepperButton(Icons.remove, () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _heightCm = (_heightCm - 1.0).clamp(100.0, 230.0);
                    });
                  }),
                  const SizedBox(width: 8),
                  Text(
                    _unitSystem == _UnitSystem.metric
                        ? '${_heightCm.round()} cm'
                        : '$feet\' $inches" ($unit)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _stepperButton(Icons.add, () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _heightCm = (_heightCm + 1.0).clamp(100.0, 230.0);
                    });
                  }),
                ],
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _kPurple,
              inactiveTrackColor: _borderColor,
              thumbColor: _kPurple,
              trackHeight: 4,
            ),
            child: Slider(
              value: _heightCm.clamp(100.0, 230.0),
              min: 100,
              max: 230,
              onChanged: (val) {
                setState(() => _heightCm = val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderColor),
            ),
            child: Icon(icon, size: 14, color: _textPrimary),
          ),
        ),
      );

  Widget _buildCategoriesBreakdown(BmiCategory activeCategory) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'WHO BMI Categories',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _categoryRow(
              'Underweight',
              '< 18.5',
              const Color(0xFF3B82F6),
              activeCategory == BmiCategory.severeUnderweight ||
                  activeCategory == BmiCategory.moderateUnderweight ||
                  activeCategory == BmiCategory.mildUnderweight,
            ),
            _categoryRow(
              'Normal weight',
              '18.5 – 24.9',
              const Color(0xFF10B981),
              activeCategory == BmiCategory.normal,
            ),
            _categoryRow(
              'Overweight',
              '25.0 – 29.9',
              const Color(0xFFF59E0B),
              activeCategory == BmiCategory.overweight,
            ),
            _categoryRow(
              'Obese',
              '≥ 30.0',
              const Color(0xFFEF4444),
              activeCategory == BmiCategory.obeseClassI ||
                  activeCategory == BmiCategory.obeseClassII ||
                  activeCategory == BmiCategory.obeseClassIII,
            ),
          ],
        ),
      );

  Widget _categoryRow(
    String label,
    String range,
    Color color,
    bool isActive,
  ) =>
      Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.35) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? color : _textPrimary,
                ),
              ),
            ),
            Text(
              range,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? color : _textSecondary,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle_rounded, size: 14, color: color),
            ],
          ],
        ),
      );

  Widget _buildActionAdviceCard(BmiResult result, Color catColor) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.psychology_outlined,
                  size: 18,
                  color: _kPurple,
                ),
                const SizedBox(width: 8),
                Text(
                  'Coach Insights & Guidance',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              result.category.advice,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _buildSaveButton() => SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: _isSaving ? null : _saveWeightToProfile,
          style: FilledButton.styleFrom(
            backgroundColor: _kPurple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_add_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Save & Log Weight to FitFuel AI',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      );
}
