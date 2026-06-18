import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/routes.dart';

// ── Design Tokens ──
const Color kBg = Color(0xFFF5F5FA);
const Color kWhite = Color(0xFFFFFFFF);
const Color kPurple = Color(0xFF5B4EE8);
const Color kPurpleLight = Color(0xFFEDEBFB);
const Color kPurpleTip = Color(0xFFE8E5FB);
const Color kHeadline = Color(0xFF14142B);
const Color kBody = Color(0xFF8A8A9A);
const Color kCardBg = Color(0xFFF7F7FA);
const Color kBorderInactive = Color(0xFFE4E4EE);
const Color kIconBgInactive = Color(0xFFEEEEF4);
const Color kDotInactive = Color(0xFFD8D6EE);
const Color kCheckBg = Color(0xFF5B4EE8);

// ── Goal model ──
class _Goal {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;

  const _Goal({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

const List<_Goal> _goals = [
  _Goal(
    id: 'weight_loss',
    icon: Icons.local_fire_department_rounded,
    title: 'Weight Loss',
    subtitle: 'Burn fat efficiently with a personalized calorie deficit and plan',
  ),
  _Goal(
    id: 'muscle_gain',
    icon: Icons.fitness_center_rounded,
    title: 'Muscle Gain',
    subtitle: 'Build strength and size by optimizing your protein intake',
  ),
  _Goal(
    id: 'maintenance',
    icon: Icons.favorite_border_rounded,
    title: 'Maintenance',
    subtitle: 'Keep your current physique while improving overall health',
  ),
  _Goal(
    id: 'healthy_gain',
    icon: Icons.show_chart_rounded,
    title: 'Healthy Weight Gain',
    subtitle: 'Increase body mass in a balanced way with nutrient-dense foods',
  ),
];

// ── Goal Selection Screen (Stateful) ──
class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({Key? key}) : super(key: key);

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  String _selectedId = 'weight_loss';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Scrollable content ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),

                    // ── App bar row ──
                    _AppBarRow(),

                    const SizedBox(height: 20),

                    // ── Step progress indicator ──
                    const _StepIndicator(currentStep: 2, totalSteps: 3),

                    const SizedBox(height: 26),

                    // ── Main heading ──
                    const Text(
                      "What's your primary\ngoal?",
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: kHeadline,
                        height: 1.22,
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Sub-headline ──
                    const Text(
                      "We'll customize your daily targets and AI coaching based on what you want to achieve.",
                      style: TextStyle(
                        fontSize: 14.5,
                        color: kBody,
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.1,
                      ),
                    ),

                    const SizedBox(height: 26),

                    // ── Goal cards ──
                    ..._goals.map(
                      (goal) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _GoalCard(
                          goal: goal,
                          isSelected: _selectedId == goal.id,
                          onTap: () => setState(() => _selectedId = goal.id),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Pro Tip banner ──
                    const _ProTipBanner(),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // ── Sticky bottom area ──
            _BottomActionArea(
              onContinue: () => context.go(AppRoutes.home),
            ),
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
            width: 38,
            height: 38,
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
              size: 16,
              color: kHeadline,
            ),
          ),
        ),
        const SizedBox(width: 14),
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

// ── Step Progress Indicator ──
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Pills
        Row(
          children: List.generate(totalSteps, (i) {
            final bool isActive = i < currentStep;
            return Container(
              margin: const EdgeInsets.only(right: 5),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: isActive ? kPurple : kDotInactive,
                borderRadius: BorderRadius.circular(100),
              ),
            );
          }),
        ),
        const SizedBox(width: 10),
        // Label
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

// ── Goal Card ──
class _GoalCard extends StatelessWidget {
  final _Goal goal;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goal,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? kWhite : kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kPurple : kBorderInactive,
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kPurple.withValues(alpha: 0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // ── Icon badge ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? kPurpleLight : kIconBgInactive,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                goal.icon,
                size: 24,
                color: isSelected ? kPurple : const Color(0xFF9A9AB0),
              ),
            ),

            const SizedBox(width: 13),

            // ── Text block ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? kPurple : kHeadline,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    goal.subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: kBody,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // ── Selection indicator ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: isSelected
                  ? Container(
                      key: const ValueKey('checked'),
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: kCheckBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: kWhite,
                        size: 15,
                      ),
                    )
                  : Container(
                      key: const ValueKey('unchecked'),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: kBorderInactive,
                          width: 1.8,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pro Tip Banner ──
class _ProTipBanner extends StatelessWidget {
  const _ProTipBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: kPurpleTip,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pulse icon badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kPurple.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.show_chart_rounded,
              size: 20,
              color: kPurple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: Color(0xFF4A4580),
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  TextSpan(
                    text: 'Pro Tip: ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text:
                        'You can always change your goal later in settings. FitFuel AI adjusts dynamically as you progress.',
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

// ── Sticky Bottom Action Area ──
class _BottomActionArea extends StatelessWidget {
  final VoidCallback onContinue;
  const _BottomActionArea({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBg,
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Continue button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: kPurple,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kPurple.withValues(alpha: 0.38),
                  blurRadius: 22,
                  spreadRadius: 0,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                splashColor: Colors.white.withValues(alpha: 0.12),
                onTap: onContinue,
                child: const Center(
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      color: kWhite,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Footer fine print
          const Text(
            'SECURED BY FITFUEL AI ENGINE',
            style: TextStyle(
              fontSize: 9.5,
              letterSpacing: 1.5,
              color: kBody,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}