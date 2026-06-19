import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/routes.dart';

// ── Design Tokens ──
const Color kBg            = Color(0xFFF5F5FA);
const Color kWhite         = Color(0xFFFFFFFF);
const Color kPurple        = Color(0xFF5B4EE8);
const Color kPurpleLight   = Color(0xFFEDEBFB);
const Color kHeadline      = Color(0xFF14142B);
const Color kBody          = Color(0xFF8A8A9A);
const Color kBorderInact   = Color(0xFFE4E4EE);
const Color kDotInact      = Color(0xFFD8D6EE);
const Color kIconBgInact   = Color(0xFFEEEEF4);

// ── Activity Level model ──
class _ActivityLevel {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;

  const _ActivityLevel({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

const List<_ActivityLevel> _levels = [
  _ActivityLevel(
    id: 'sedentary',
    icon: Icons.air_rounded,
    title: 'Sedentary',
    subtitle: 'Office job, little to no exercise',
  ),
  _ActivityLevel(
    id: 'lightly',
    icon: Icons.show_chart_rounded,
    title: 'Lightly Active',
    subtitle: '1-3 days of light exercise/week',
  ),
  _ActivityLevel(
    id: 'moderately',
    icon: Icons.local_fire_department_rounded,
    title: 'Moderately Active',
    subtitle: '3-5 days of moderate exercise',
  ),
  _ActivityLevel(
    id: 'very',
    icon: Icons.directions_run_rounded,
    title: 'Very Active',
    subtitle: '6-7 days of intense exercise',
  ),
];

// ── Personalize Screen ──
class PersonalizeScreen extends StatefulWidget {
  const PersonalizeScreen({Key? key}) : super(key: key);

  @override
  State<PersonalizeScreen> createState() => _PersonalizeScreenState();
}

class _PersonalizeScreenState extends State<PersonalizeScreen> {
  double _height = 175;
  String _selectedActivity = 'moderately';

  int get _suggestedKcal {
    switch (_selectedActivity) {
      case 'sedentary':   return 1800;
      case 'lightly':     return 1950;
      case 'moderately':  return 2150;
      case 'very':        return 2450;
      default:            return 2150;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    _AppBarRow(),
                    const SizedBox(height: 16),
                    const _StepIndicator(currentStep: 3, totalSteps: 3),
                    const SizedBox(height: 24),
                    const Text(
                      'Tell us about you',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: kHeadline,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      "We'll use this to calculate your daily metabolic rate.",
                      style: TextStyle(
                        fontSize: 14,
                        color: kBody,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(child: _MetricCard(
                          icon: Icons.scale_outlined,
                          label: 'WEIGHT',
                          value: '72',
                          unit: 'kg',
                        )),
                        const SizedBox(width: 14),
                        Expanded(child: _MetricCard(
                          icon: Icons.track_changes_rounded,
                          label: 'TARGET',
                          value: '68',
                          unit: 'kg',
                        )),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _HeightCard(
                      heightCm: _height,
                      onChanged: (v) => setState(() => _height = v),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: const [
                        Icon(Icons.bolt_rounded, color: kPurple, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Activity Level',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: kHeadline,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ..._levels.map(
                      (level) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ActivityCard(
                          level: level,
                          isSelected: _selectedActivity == level.id,
                          onTap: () =>
                              setState(() => _selectedActivity = level.id),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _IntakeBanner(kcal: _suggestedKcal),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
            _ConfirmButton(onTap: () => context.go(AppRoutes.home)),
          ],
        ),
      ),
    );
  }
}

// ── App Bar Row ──
class _AppBarRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.canPop() ? context.pop() : null,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 15,
              color: kHeadline,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Personalize',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kHeadline,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}

// ── Step Indicator ──
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: List.generate(totalSteps, (i) {
            final bool active = i < currentStep;
            return Container(
              margin: const EdgeInsets.only(right: 5),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: active ? kPurple : kDotInact,
                borderRadius: BorderRadius.circular(100),
              ),
            );
          }),
        ),
        const SizedBox(width: 10),
        Text(
          'STEP $currentStep OF $totalSteps',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: kBody,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ── Metric Card ──
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderInact, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kPurpleLight,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 22, color: kPurple),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              letterSpacing: 1.4,
              color: kBody,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: kHeadline,
                    letterSpacing: -1,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: kHeadline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Height Slider Card ──
class _HeightCard extends StatelessWidget {
  final double heightCm;
  final ValueChanged<double> onChanged;

  const _HeightCard({required this.heightCm, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderInact, width: 1.1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.straighten_rounded, size: 18, color: kPurple),
                  SizedBox(width: 7),
                  Text(
                    'Height',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kHeadline,
                    ),
                  ),
                ],
              ),
              Text(
                '${heightCm.round()} cm',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: const SliderThemeData(
              trackHeight: 4,
              thumbColor: kWhite,
              activeTrackColor: kPurple,
              inactiveTrackColor: kDotInact,
              overlayColor: Color(0x265B4EE8),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: heightCm,
              min: 140,
              max: 220,
              onChanged: onChanged,
              activeColor: kPurple,
              inactiveColor: kDotInact,
              thumbColor: kWhite,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity Card ──
class _ActivityCard extends StatelessWidget {
  final _ActivityLevel level;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? kPurple : kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kPurple : kBorderInact,
            width: isSelected ? 0 : 1.1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kPurple.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.22)
                    : kIconBgInact,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                level.icon,
                size: 22,
                color: isSelected ? kWhite : kBody,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : kHeadline,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    level.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.65)
                          : kBody,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? kWhite : Colors.transparent,
                border: Border.all(
                  color: isSelected ? kWhite : kBorderInact,
                  width: isSelected ? 0 : 1.8,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.circle, size: 14, color: kPurple)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Daily Suggested Intake Banner ──
class _IntakeBanner extends StatelessWidget {
  final int kcal;

  const _IntakeBanner({required this.kcal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: kPurple,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPurple.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'DAILY SUGGESTED INTAKE',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.8,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$kcal',
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),
                const TextSpan(
                  text: ' kcal',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text(
              'Moderate Deficit • Weight Loss Goal',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Confirm Button ──
class _ConfirmButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ConfirmButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBg,
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: kPurple,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kPurple.withValues(alpha: 0.38),
              blurRadius: 22,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withValues(alpha: 0.12),
            onTap: onTap,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Confirm & Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}