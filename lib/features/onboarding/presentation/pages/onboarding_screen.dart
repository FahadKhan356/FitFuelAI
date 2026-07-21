import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/routes.dart';
import '../../../../core/constants/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentStep = 0;

  @override
  Widget build(BuildContext context) {
    // Page 0 → Intro hero | Pages 1-8 → form steps (kept for backwards compat)
    if (currentStep == 0) {
      return _IntroPage(
        onGetStarted: () => context.go(AppRoutes.goalSelection),
        onSkip: () => context.go(AppRoutes.login),
      );
    }

    return _FormPage(
      currentStep: currentStep,
      onBack: () => setState(() => currentStep--),
      onNext: () {
        if (currentStep < 8) {
          setState(() => currentStep++);
        } else {
          context.go(AppRoutes.goalSelection);
        }
      },
      onComplete: () => context.go(AppRoutes.goalSelection),
    );
  }
}

// ══════════════════════════════════════════════════
//  Intro Hero Page
// ══════════════════════════════════════════════════
class _IntroPage extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onSkip;

  const _IntroPage({required this.onGetStarted, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundLight),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Hero image card ──
          _HeroImageCard(screenWidth: size.width, screenHeight: size.height),

          // ── Scrollable content below card ──
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.045),

                    // ── Headline ──
                    _HeadlineText(),

                    SizedBox(height: size.height * 0.026),

                    // ── Body text ──
                    Text(
                      'FitFuel AI uses advanced vision to instantly scan your meals, track macros, and help you reach your health goals effortlessly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.5,
                        height: 1.65,
                        color: const Color(AppColors.textSecondary),
                        letterSpacing: 0.1,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    SizedBox(height: size.height * 0.038),

                    // ── Page indicator ──
                    const _PageIndicator(activeIndex: 0, count: 3),

                    SizedBox(height: size.height * 0.038),

                    // ── Get Started button ──
                    _GetStartedButton(onTap: onGetStarted),

                    SizedBox(height: size.height * 0.022),

                    // ── Skip to Login ──
                    GestureDetector(
                      onTap: onSkip,
                      child: Text(
                        'Skip to Login',
                        style: TextStyle(
                          fontSize: 14.5,
                          color: const Color(AppColors.textSecondary),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  Form Steps Page (keeps existing onboarding flow)
// ══════════════════════════════════════════════════
class _FormPage extends StatelessWidget {
  final int currentStep;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onComplete;

  const _FormPage({
    required this.currentStep,
    required this.onBack,
    required this.onNext,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Step $currentStep of 8'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                'Tell us about you',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Customize your nutrition goals',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Progress indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: currentStep / 8,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 40),
              // Dynamic content based on step
              _buildStepContent(),
              const SizedBox(height: 40),
              Row(
                children: [
                  if (currentStep > 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onBack,
                        child: const Text('Back'),
                      ),
                    ),
                  if (currentStep > 1) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: currentStep == 8 ? onComplete : onNext,
                      child: Text(currentStep == 8 ? 'Complete' : 'Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildStepContent() {
    switch (currentStep) {
      case 1:
        return const TextField(
          decoration: InputDecoration(hintText: 'Your Name'),
        );
      case 2:
        return const TextField(
          decoration: InputDecoration(hintText: 'Age'),
          keyboardType: TextInputType.number,
        );
      case 3:
        return DropdownButtonFormField<String>(
          items: ['Male', 'Female', 'Other']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (_) {},
          decoration: const InputDecoration(hintText: 'Gender'),
        );
      case 4:
        return const TextField(
          decoration: InputDecoration(hintText: 'Height (cm)'),
          keyboardType: TextInputType.number,
        );
      case 5:
        return const TextField(
          decoration: InputDecoration(hintText: 'Weight (kg)'),
          keyboardType: TextInputType.number,
        );
      case 6:
        return const TextField(
          decoration: InputDecoration(hintText: 'Target Weight (kg)'),
          keyboardType: TextInputType.number,
        );
      case 7:
        return DropdownButtonFormField<String>(
          items: ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (_) {},
          decoration: const InputDecoration(hintText: 'Activity Level'),
        );
      case 8:
        return DropdownButtonFormField<String>(
          items: ['Weight Loss', 'Weight Gain', 'Muscle Gain', 'Maintenance']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (_) {},
          decoration: const InputDecoration(hintText: 'Goal Type'),
        );
      default:
        return const SizedBox();
    }
  }
}

// ══════════════════════════════════════════════════
//  Hero image card
// ══════════════════════════════════════════════════
class _HeroImageCard extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;

  const _HeroImageCard({
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    final double cardHeight = screenHeight * 0.44;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      width: double.infinity,
      height: cardHeight,
      decoration: const BoxDecoration(
        color: Color(0xFFEEECF8),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.09),
                    blurRadius: 12,
                    offset: const Offset(0, 20),
                  ),
                ],
                border: Border.all(
                  color: const Color.fromARGB(255, 255, 255, 255).withOpacity(1),
                  width: 2,
                  style: BorderStyle.solid,
                ),
                image: const DecorationImage(
                  image: AssetImage('assets/images/onBoarding_Hero_Image.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.fromARGB(0, 255, 243, 243), Color.fromARGB(255, 133, 129, 129)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.fromARGB(255, 255, 255, 255), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  Headline text
// ══════════════════════════════════════════════════
class _HeadlineText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          height: 1.25,
          color: const Color(AppColors.textPrimary),
        ),
        children: const [
          TextSpan(text: 'See Your Food in a '),
          TextSpan(
            text: 'New\nLight',
            style: TextStyle(color: Color(AppColors.authPurple)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  Page indicator dots
// ══════════════════════════════════════════════════
class _PageIndicator extends StatelessWidget {
  final int activeIndex;
  final int count;

  const _PageIndicator({
    required this.activeIndex,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final bool isActive = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(AppColors.authPurple)
                : const Color(0xFFD0CEEA),
            borderRadius: BorderRadius.circular(100),
          ),
        );
      }),
    );
  }
}

// ══════════════════════════════════════════════════
//  Get Started button
// ══════════════════════════════════════════════════
class _GetStartedButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GetStartedButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(AppColors.authPurple),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(AppColors.authPurple).withValues(alpha: 0.38),
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
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Get Started',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '→',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}